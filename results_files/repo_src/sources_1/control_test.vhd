library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity control_test is
    generic(    g_BRAM_ADDR_WIDTH   :   integer :=  12;
                g_BRAM_DATA_WIDTH   :   integer :=  16;
                g_NUM_ROWS          :   integer :=  22;
                g_NUM_COLS          :   integer :=  28);
    port(       clk                 :   in std_logic;
                cntr_rst            :   out std_logic;
                cntr_clk_enbl       :   out std_logic;
                shift_row_out       :   out std_logic;
                shift_col_out       :   out std_logic;
                bram_wr_enbl        :   out std_logic;
                bram_rd_enbl        :   out std_logic;
                bram_addr           :   out std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                bram_data_in        :   in std_logic_vector((2 * g_BRAM_DATA_WIDTH - 1) downto 0);                
                rx_en               :   in std_logic;
                rx_byte             :   in std_logic_vector(7 downto 0);
                tx_dv               :   out std_logic;
                tx_byte             :   out std_logic_vector(7 downto 0);
                tx_done             :   in std_logic;
                tx_ready            :   in std_logic;
                turn_on         :   out std_logic);   
            
end control_test;

architecture Behavioral of control_test is

    type fsm_state is (IDLE, COUNT, WRITE, RESET, TRANS_SIGN, WRITE_OUT,DELAY_CYCLE, DELAY_CYCLE1,DELAY_CYCLE2,DELAY_CYCLE3, SHIFT, STATUS_CHECK, TRANS_END, RD_T1,heat_up);    
    function init_shift (size : integer) return std_logic_vector is
        variable ret    :   std_logic_vector(size downto 2) :=  (others => '0');
    begin
        return (ret & '1');
    end init_shift;

    signal control_fsm      :   fsm_state   :=  IDLE;
    signal bram_addr_reg    :   std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0)  :=  (others =>  '0');
    
    
begin

    bram_addr   <=  bram_addr_reg;
 
control_proc: process(clk)
        variable ro_cntr        :   integer :=  0;
        variable row_cntr       :   integer :=  0;
        variable col_cntr       :   integer :=  0;
        variable de_cntr        :   integer :=  0;
        
        variable hex_offset     :   integer :=  3;
        variable start_sign     :   integer :=  1;
        variable end_sign       :   integer :=  1;
        variable heat           :   integer :=  0;
        variable heat_cntr      :   integer :=  0;
    begin
        if (rising_edge(clk)) then
            case control_fsm is
                when IDLE   =>
                    cntr_rst            <=  '0';
                    cntr_clk_enbl       <=  '0';
                    bram_wr_enbl        <=  '0';
                    bram_addr_reg       <=  (others => '0');
	                bram_rd_enbl <= '0';                   
                    turn_on   <= '0';
                     
                    if (rx_en = '1') then 
                         if (rx_byte = x"53") then --S
                            control_fsm  <=  RD_T1;
                         else
                            control_fsm   <=  IDLE;
                         end if;
                    else 
                         control_fsm   <=  IDLE;
                    end if;
                    
                 when RD_T1  =>                          
                    if (rx_en = '1') then
                        if (rx_byte = x"54") then --T
                          if (heat = 1) then
                              control_fsm    <=  heat_up;
                              heat := 0 ;
                          else
                              control_fsm    <=  COUNT; 
                              heat := 1; 
                          end if;
                        else
                          control_fsm   <=  IDLE;
                        end if;
                    else
                        control_fsm  <=  RD_T1;
                    end if;     
                     
                 when heat_up =>
                        -- turn on the upper heating part for 20 seconds
                           if (heat_cntr = 2000000) then
                               heat_cntr         :=  0;
                               control_fsm     <=  COUNT;  
                               turn_on   <= '0'; 
                           else
                                heat_cntr      :=  heat_cntr + 1;
                                turn_on   <= '1';
                                control_fsm     <=  heat_up;
                           end if;                           
                                                        
                when COUNT  =>
                        cntr_rst        <=  '0';
                        shift_row_out   <=  '0';
                        shift_col_out   <=  '0';
                        if (ro_cntr = 2) then ------------------
                            cntr_clk_enbl   <=  '0';
                            ro_cntr         :=  0;
                            control_fsm <=  WRITE;
                        else
                            ro_cntr         :=  ro_cntr + 1;
                            cntr_clk_enbl   <=  '1';
                        end if;
                        
                    when SHIFT  =>
                        cntr_rst            <=  '1';
                        bram_wr_enbl        <=  '0';
                        if (col_cntr = g_NUM_COLS - 1) then
                            col_cntr        :=  0;
                            row_cntr        :=  row_cntr + 1;
                            shift_row_out   <=  '1';
                            shift_col_out   <=  '1';
                        else
                            col_cntr        :=  col_cntr + 1;
                            shift_col_out   <=  '1';
                        end if;
                        control_fsm <=  COUNT;
                        
                    when WRITE  =>                  
                        if (col_cntr = 0 ) and (row_cntr = g_NUM_ROWS) then --after read all data into bram, row=0, col = col.
                            control_fsm <=  TRANS_SIGN;                    
                            cntr_rst        <=  '1';
                            bram_wr_enbl    <=  '0';
	                        bram_rd_enbl    <= '1';
                            bram_addr_reg   <=  init_shift(g_BRAM_ADDR_WIDTH); --start from address 1 to transmit
                            row_cntr    :=  0;
                            col_cntr    :=  0;
                        else
                            bram_wr_enbl        <=  '1';
                            bram_addr_reg   <=  std_logic_vector(unsigned(bram_addr_reg) + 1); --start from address '1' to row*col
                            control_fsm     <=  SHIFT;
                        end if;
                        

                 when TRANS_SIGN  =>
                    if (tx_ready    =   '0') then       --if uart not ready to receive
                       control_fsm     <=  TRANS_SIGN ;
                       tx_dv           <=  '0';
                    else
                       tx_dv           <=  '1';  
                       if (start_sign = 1)   then
                            tx_byte         <=  x"54";   --'T'
                       else 
                            tx_byte         <=  x"48";   --'H'
                       end if;
                       control_fsm     <=  DELAY_CYCLE1;
                    end if;
                 
                  when DELAY_CYCLE1  =>
                       if (de_cntr = 2) then
                           de_cntr         :=  0;
                           if (start_sign = 0) then
                               start_sign     :=  1;
                               control_fsm    <=  WRITE_OUT;
                            else
                               start_sign  := start_sign - 1;
                               control_fsm    <=  TRANS_SIGN;
                            end if;
                       else
                            de_cntr      :=  de_cntr + 1;
                            tx_dv       <= '0';
                            control_fsm     <=  DELAY_CYCLE1;
                       end if;                 
                 
  ----------------------------------------------------------------------------------------------------------------        x                          
                when WRITE_OUT   =>            
                if (tx_ready    =   '0') then       --if uart not ready to receive
                   control_fsm     <=  WRITE_OUT ;
                   tx_dv           <=  '0';
                else
                   tx_dv           <=  '1';         --transmit signal, next clock cycle, output appropriate data
                   tx_byte         <=  bram_data_in(((hex_offset * 8) + 7) downto (hex_offset * 8));
                   control_fsm     <=  DELAY_CYCLE2;
                end if;

	           	when DELAY_CYCLE2  =>
		            if (de_cntr = 2) then
                        de_cntr         :=  0;
                        if (hex_offset = 0) then
                            hex_offset     :=  3;
                            control_fsm    <=  STATUS_CHECK;
                        else
                            hex_offset  :=  hex_offset - 1;
                            control_fsm	<=  WRITE_OUT;
                        end if;
                    else
                        de_cntr      :=  de_cntr + 1;
                        tx_dv       <= '0';
                        control_fsm     <=  DELAY_CYCLE2;
                    end if;

	            when STATUS_CHECK  =>
	               bram_rd_enbl <= '1';
		           bram_addr_reg   <=  std_logic_vector(unsigned(bram_addr_reg) + 1); --address++ to read bram 
                     if unsigned(bram_addr_reg)< (g_NUM_ROWS * g_NUM_COLS)then
                         control_fsm    <= DELAY_CYCLE;
                     else
                         control_fsm     <=  TRANS_END;
                     end if; 
		   
		        when DELAY_CYCLE =>
                          if (de_cntr = 2) then
                              de_cntr         :=  0;
                              control_fsm    <=  WRITE_OUT;
                          else
                               de_cntr      :=  de_cntr + 1;
                               tx_dv       <= '0';
                               control_fsm     <=  DELAY_CYCLE;
                          end if;  
				
----------------------------------------------------------------------------------------------------------------------------------         x            

                   when TRANS_END  =>
                       if (tx_ready    =   '0') then       --if uart not ready to receive
                          control_fsm     <=  TRANS_END;
                          tx_dv           <=  '0';
                       else
	                      bram_rd_enbl <= '0';
                          tx_dv           <=  '1';  
                          tx_byte         <=  x"2E";   --'.'
                          control_fsm     <=  DELAY_CYCLE3;
                       end if;
                     
                when DELAY_CYCLE3  =>
                          if (de_cntr = 2) then
                              de_cntr         :=  0;
                              control_fsm    <=  RESET;
                          else
                               de_cntr      :=  de_cntr + 1;
                               tx_dv       <= '0';
                               control_fsm     <=  DELAY_CYCLE3;
                          end if;  

                
                when RESET  =>
                    bram_wr_enbl        <=  '0';
                    bram_addr_reg       <=  (others => '0');
                    control_fsm         <=  IDLE;
                    tx_dv               <=  '0';
                     
            end case;
        end if;
    end process;

end Behavioral;
