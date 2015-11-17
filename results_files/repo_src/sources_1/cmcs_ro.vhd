library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cmcs_ro is
    port(   clk_in :   in std_logic;
            ser_in  :   in std_logic;
            ser_out :   out std_logic);
end cmcs_ro;

architecture Behavioral of cmcs_ro is

    
    component counter is
        generic(    g_cntr_width    :   integer :=  32);
        port(       clk             :   in std_logic;
                    rst             :   in std_logic;
                    clk_enbl        :   in std_logic;
                    cnt_out         :   out std_logic_vector((g_cntr_width - 1) downto 0));     
    end component;
   
    component ro_array is
        generic(    num_rows        :   integer :=  22;
                    num_cols        :   integer :=  28);
        port(       shift_row_input :   in std_logic;
                    shift_col_input :   in std_logic; 
                    clk             :   in std_logic;       
                    circuit_output  :   out std_logic;
                    turn_on         :   in std_logic);
    end component;
    
    component control_test is
        generic(    g_BRAM_ADDR_WIDTH   :   integer :=  16;
                    g_BRAM_DATA_WIDTH   :   integer :=  32;
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
                    bram_data_in        :   in std_logic_vector((2*g_BRAM_DATA_WIDTH - 1) downto 0);
                    rx_en               :   in std_logic;
                    rx_byte             :   in std_logic_vector(7 downto 0);
                    tx_dv               :   out std_logic;
                    tx_byte             :   out std_logic_vector(7 downto 0);
                    tx_done             :   in std_logic;
                    tx_ready            :   in std_logic;                    
                    turn_on             :   out std_logic);                   
    end component;
    
    component bram_sp is
        generic(    g_BRAM_ADDR_WIDTH   :   integer :=  16;
                    g_BRAM_DATA_WIDTH   :   integer :=  32);
        port(       clk_in              :   in std_logic;
                    wr_en               :   in std_logic;
                    rd_en               :   in std_logic;
                    addr                :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                    data_in             :   in std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
                    data_out            :   out std_logic_vector((2*g_BRAM_DATA_WIDTH - 1) downto 0));
    end component;
    
    component uart_tx is
        generic (   g_CLKS_PER_BIT  : integer := 1736);     -- Needs to be set correctly => 200Mhz / 115200BAUD = 1736.1111...
        port (      i_clk           : in std_logic;
                    i_tx_dv         : in std_logic;
                    i_tx_byte       : in std_logic_vector(7 downto 0);
                    o_tx_done       : out std_logic;
                    o_tx_ready      : out std_logic;
                    o_tx_serial     : out std_logic);
    end component;
    
    component uart_rx is
        generic(    g_CLKS_PER_BIT  :   integer := 434);     -- Needs to be set correctly => 50Mhz / 115200BAUD = 434.03...
        port(       i_clk           :   in  std_logic;
                    i_rx_serial     :   in  std_logic;
                    o_rx_dv         :   out std_logic;
                    o_rx_byte       :   out std_logic_vector(7 downto 0));
    end component;
    
    component xadc_wiz_0
            port  (
              convst_in     :   in  std_logic;                      -- Convert Start Input
              daddr_in      :   in  std_logic_vector(6 downto 0);   -- Address bus for the dynamic reconfiguration port
              dclk_in       :   in  std_logic;                      -- Clock input for the dynamic reconfiguration port
              den_in        :   in  std_logic;                      -- Enable Signal for the dynamic reconfiguration port
              di_in         :   in  std_logic_vector(15 downto 0);  -- Input data bus for the dynamic reconfiguration port
              dwe_in        :   in  std_logic;                      -- Write Enable for the dynamic reconfiguration port
              reset_in      :   in  std_logic;                      -- Reset signal for the System Monitor control logic
              busy_out      :   out  std_logic;                     -- ADC Busy signal
              channel_out   :   out  std_logic_vector(4 downto 0);  -- Channel Selection Outputs
              do_out        :   out  std_logic_vector(15 downto 0); -- Output data bus for dynamic reconfiguration port
              drdy_out      :   out  std_logic;                     -- Data ready signal for the dynamic reconfiguration port
              eoc_out       :   out  std_logic;                     -- End of Conversion Signal
              eos_out       :   out  std_logic;                     -- End of Sequence Signal
              alarm_out     :   out  std_logic;                     -- OR'ed output of all the Alarms    
              vp_in         :   in  std_logic;                      -- Dedicated Analog Input Pair
              vn_in         :   in  std_logic);    
      end component;
    
    constant rows                   :   integer     :=  96;
    constant cols                   :   integer     :=  32;
    constant bram_addrwidth         :   integer     :=  14;
    constant bram_datawidth         :   integer     :=  16;
    
    signal ro_xfer                          :   std_logic;
    signal cnt_out_xfer                     :   std_logic_vector(bram_datawidth-1 downto 0);
    
    attribute dont_touch                    :   string;
    attribute dont_touch of counter         :   component is "TRUE";
    attribute dont_touch of control_test    :   component is "TRUE";
    attribute dont_touch of bram_sp         :   component is "TRUE";
    attribute dont_touch of cnt_out_xfer    :   signal is "TRUE";
    
    signal cntr_rst_xfer                    :   std_logic;
    signal cntr_enbl_xfer                   :   std_logic;
    signal bram_wr_enbl_xfer                :   std_logic;
    signal bram_read_enbl_xfer              :   std_logic;

    signal bram_addr_xfer                   :   std_logic_vector(bram_addrwidth-1 downto 0);
    signal data_out_xfer                    :   std_logic_vector(2*bram_datawidth-1 downto 0);
    constant clks_per_bit                   :   integer     :=  5; --100M / 460800 = 217.01... 
     --100KHz/19200=5.21
    -- Needs to be set correctly => 50Mhz / 115200BAUD = 434.03...100/115200=868.06
    signal i_tx_dv_xfer                     :   std_logic;
    signal i_tx_byte_xfer                   :   std_logic_vector(7 downto 0);
    signal o_tx_done_xfer                   :   std_logic;
    signal o_tx_ready_xfer                  :   std_logic;
    signal shift_row_xfer                   :   std_logic;
    signal shift_col_xfer                   :   std_logic;
    signal rx_byte_xfer                     :   std_logic_vector(7 downto 0);
    signal rx_dv_xfer                       :   std_logic;
   
    signal do_out_xfer                      :   std_logic_vector(15 downto 0);
    signal channel_out_xfer                 :   std_logic_vector(4 downto 0);
    signal busy_out_xfer                    :   std_logic;
    signal drdy_out_xfer                    :   std_logic;
    signal eoc_out_xfer                     :   std_logic;
    signal eos_out_xfer                     :   std_logic;
    signal alarm_out_xfer                   :   std_logic;
    signal s_f                              :   std_logic;   
    signal turn_on_xfer                     :   std_logic;
    
begin
    xdc:   xadc_wiz_0
        port map  (
          convst_in      =>  '0',                   -- Convert Start Input
          daddr_in       =>  (others => '0'),      -- Address bus for the dynamic reconfiguration port
          dclk_in        =>   s_f,                      -- Clock input for the dynamic reconfiguration port
          den_in         =>  '0',               -- Enable Signal for the dynamic reconfiguration port only high for 1 clock cycle
          dwe_in         =>  '0' ,                     -- never write. Write Enable for the dynamic reconfiguration port
          di_in          =>  (others => '0'),  -- Input data bus for the dynamic reconfiguration port
          reset_in      => '1',
          do_out         => do_out_xfer, -- Output data bus for dynamic reconfiguration port
          busy_out      => busy_out_xfer,                     -- ADC Busy signal
          channel_out    => channel_out_xfer,  -- Channel Selection Outputs     
          drdy_out      => drdy_out_xfer,                     -- Data ready signal for the dynamic reconfiguration port
          eoc_out       => eoc_out_xfer,                    -- //End of Conversion Signal
          eos_out       => eos_out_xfer,                     -- //End of Sequence Signal
          alarm_out     =>  alarm_out_xfer ,                     -- //OR'ed output of all the Alarms    
          vp_in         => '0',                    -- //Dedicated Analog Input Pair
          vn_in         => '0');    

cntr: component counter
        generic map(    g_cntr_width    =>  16)
        port map(       clk             =>  ro_xfer,
                        rst             =>  cntr_rst_xfer,
                        clk_enbl        =>  cntr_enbl_xfer,
                        cnt_out         =>  cnt_out_xfer);
                        
sngl_ro: component ro_array
        generic map(    num_rows        =>  rows,
                        num_cols        =>  cols)
        port map(       shift_row_input =>  shift_row_xfer,
                        shift_col_input =>  shift_col_xfer,
                        clk             =>   s_f,
                        circuit_output  =>  ro_xfer,
                        turn_on => turn_on_xfer);
                        
cntrl_unt: component control_test
        generic map(    g_BRAM_ADDR_WIDTH   =>  bram_addrwidth,
                        g_BRAM_DATA_WIDTH   =>  bram_datawidth,
                        g_NUM_ROWS          =>  rows,
                        g_NUM_COLS          =>  cols)
        port map(       clk                 =>   s_f,
                        cntr_rst            =>  cntr_rst_xfer,
                        cntr_clk_enbl       =>  cntr_enbl_xfer,
                        bram_wr_enbl        =>  bram_wr_enbl_xfer,
                        bram_rd_enbl        =>  bram_read_enbl_xfer,
                        bram_addr           =>  bram_addr_xfer,
                        bram_data_in        =>  data_out_xfer,
                        shift_row_out       =>  shift_row_xfer,
                        shift_col_out       =>  shift_col_xfer,
                        rx_en               =>  rx_dv_xfer,
                        rx_byte             =>  rx_byte_xfer,
                        tx_dv               =>  i_tx_dv_xfer,
                        tx_byte             =>  i_tx_byte_xfer,
                        tx_done             =>  o_tx_done_xfer,
                        tx_ready            =>  o_tx_ready_xfer,
                        turn_on => turn_on_xfer);
                        
bram: component bram_sp
        generic map(    g_BRAM_ADDR_WIDTH   =>  bram_addrwidth,
                        g_BRAM_DATA_WIDTH   =>  bram_datawidth)
        port map(       clk_in              =>   s_f,
                        wr_en               =>  bram_wr_enbl_xfer,
                        rd_en               =>  bram_read_enbl_xfer,
                        addr                =>  bram_addr_xfer,
                        data_in             =>  cnt_out_xfer,
                        data_out            =>  data_out_xfer);

rx0:  component uart_rx 
        generic map( g_CLKS_PER_BIT  => clks_per_bit)    
        port map(   i_clk           =>   s_f,
                    i_rx_serial     =>  ser_in,
                    o_rx_dv         =>  rx_dv_xfer,
                    o_rx_byte       =>  rx_byte_xfer);                                          
tx0: component uart_tx
        generic map(    g_CLKS_PER_BIT  =>  clks_per_bit)
        port map(       i_clk           =>   s_f,
                        i_tx_dv         =>  i_tx_dv_xfer,
                        i_tx_byte       =>  i_tx_byte_xfer,
                        o_tx_done       =>  o_tx_done_xfer,
                        o_tx_ready      =>  o_tx_ready_xfer,
                        o_tx_serial     =>  ser_out);

 slowdown_process:process(clk_in)
            variable cntr  :   integer :=  0;
            --devide by 1000    
            begin
                if (rising_edge(clk_in)) then
                     if (cntr = 499) then
                     cntr         :=  0;
                     s_f <= not(s_f);
                     else
                     cntr      :=   cntr + 1;
                     end if;                        
                end if;
             end process;
end Behavioral;
