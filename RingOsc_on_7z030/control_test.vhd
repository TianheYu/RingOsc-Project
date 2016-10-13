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
                fsm_rst             :   in std_logic; 
                cntr_rst            :   out std_logic;
                cntr_clk_enbl       :   out std_logic;
                shift_row_out       :   out std_logic;
                shift_col_out       :   out std_logic;
                bram_wr_enbl        :   out std_logic;
                bram_rd_enbl        :   out std_logic;
                bram_addr           :   out std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);                               
                rx_byte             :   in std_logic_vector(7 downto 0);
                cntr_cycle          :   in std_logic_vector(31 downto 0);
                m_done              :   out std_logic;             
                sig_shift_row       :   out std_logic_vector(g_NUM_ROWS downto 1);
                sig_shift_col       :   out std_logic_vector(g_NUM_COLS downto 1));   
            
end control_test;

architecture Behavioral of control_test is

    type fsm_state is (IDLE, RD_S1, RD_T1,ENABLE_SIG,DELAY_CYCLE, COUNT,SHIFT , SHITT_STOP,WRITE, RESET, FINISH_SIGN);   
 
    function init_shift (size : integer) return std_logic_vector is
        variable ret    :   std_logic_vector(size downto 2) :=  (others => '0');
    begin
        return (ret & '1');
    end init_shift;

    signal control_fsm      :   fsm_state   :=  IDLE;
    signal bram_addr_reg    :   std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0)  :=  (others =>  '0');
    
    
begin

    bram_addr   <=  bram_addr_reg;
 
control_proc: process(clk , fsm_rst)
        variable ro_cntr        :   integer :=  0;
        variable row_cntr       :   integer :=  0;
        variable col_cntr       :   integer :=  0;
        variable de_cntr        :   integer :=  0;
    begin
        if (fsm_rst = '0') then 
            control_fsm    <=  RESET;
        elsif(rising_edge(clk)) then
            case control_fsm is
                when IDLE   =>
                    cntr_rst            <=  '1';
                    cntr_clk_enbl       <=  '0';
                    bram_wr_enbl        <=  '0';
                    bram_rd_enbl        <=  '0';
                    bram_addr_reg       <=  (others => '0');
                    sig_shift_row       <=  (others => '0');
                    sig_shift_col       <=  (others => '0');
                    control_fsm          <= RD_S1; 
                                       
                when RD_S1 =>	             
	                if (rx_byte = x"53") then --S
	                   control_fsm  <=  RD_T1;
                    else
                       control_fsm   <=  RD_S1;
                    end if;
                   
                 when RD_T1  =>                          
                    if (rx_byte = x"54") then --T
                        control_fsm  <=  ENABLE_SIG;
                        bram_rd_enbl <= '0'; 
                    else
                        control_fsm  <=  RD_T1;
                    end if;      	                                                
                                                             
                when ENABLE_SIG =>
                    sig_shift_row       <=  (others => '1');
                    sig_shift_col       <=  (others => '1');   
                    control_fsm         <=  DELAY_CYCLE;
                
                when DELAY_CYCLE =>
                      shift_row_out   <=  '0';
                      shift_col_out   <=  '0';
                      if (de_cntr = 2) then
                          de_cntr         :=  0;
                          control_fsm    <=  COUNT;
                      else
                           de_cntr      :=  de_cntr + 1;
                           control_fsm     <=  DELAY_CYCLE;
                      end if;   
                                                                                                                          
                when COUNT  =>
                        cntr_rst   <=  '0';
                        if (ro_cntr = to_integer(unsigned(cntr_cycle))) then
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
                    control_fsm <= SHITT_STOP ;
                    
                 WHEN SHITT_STOP=>                      
                     shift_row_out   <=  '0';
                     shift_col_out   <=  '0';
                     control_fsm <=  DELAY_CYCLE;
                        
                 when WRITE  =>           -- after finish writing, output an finish signal       
                    if (col_cntr = 0 ) and (row_cntr = g_NUM_ROWS) then --after read all data into bram, row=0, col = col.
                        control_fsm <=  FINISH_SIGN;               
                        cntr_rst        <=  '1';
                        bram_wr_enbl    <=  '0';                        
                        bram_addr_reg   <=  (others => '0'); --//back to addr 0
                        sig_shift_row   <=  (others => '0');
                        sig_shift_col   <=  (others => '0');
                        row_cntr        :=  0;
                        col_cntr        :=  0;
                    else
                        bram_wr_enbl        <=  '1';
                        bram_addr_reg   <=  std_logic_vector(unsigned(bram_addr_reg) + 1); --start from address '1' to row*col
                        control_fsm     <=  SHIFT;
                    end if;
                        
                 when FINISH_SIGN  =>
                    if (rx_byte = x"55") then       --pull down the signal when receiving '55'
                       control_fsm     <=  RD_S1;
                       m_done           <=  '0';
                    else
                       m_done           <=  '1';  -- output '1' after finished testing
                       control_fsm     <=  FINISH_SIGN;
                       bram_rd_enbl    <= '1'; --keeps read_enable to '1' after finished testing
                    end if;
                 
                when RESET  =>
                    cntr_rst            <=  '1';
                    cntr_clk_enbl       <=  '0';
                    bram_wr_enbl        <=  '0';
                    bram_rd_enbl        <=  '0';
                    bram_addr_reg       <=  (others => '0');
                    sig_shift_row       <=  (others => '0');
                    sig_shift_col       <=  (others => '0');
                    m_done              <=  '0';
                    control_fsm         <=  IDLE;
            end case;
        end if;
    end process;

end Behavioral;
