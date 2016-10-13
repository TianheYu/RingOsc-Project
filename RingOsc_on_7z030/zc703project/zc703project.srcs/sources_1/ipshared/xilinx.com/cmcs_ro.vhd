library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--try 921600 baud rate

entity cmcs_ro is
    port(   clk         :   in std_logic;
            rst         :   in std_logic;
            Test_en     :   in std_logic_vector(7 downto 0);         
            P_r         :   in std_logic_vector(31 downto 0);
            R_ADDR      :   in std_logic_vector(13 downto 0);
            T_finish    :   out std_logic;   
            R_DATA      :   out std_logic_vector(31 downto 0));
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
                    sig_shift_row   :   in std_logic_vector(num_rows downto 1);
                    sig_shift_col   :   in std_logic_vector(num_cols downto 1));
    end component;
    
    component control_test is
        generic(    g_BRAM_ADDR_WIDTH   :   integer :=  16;
                    g_BRAM_DATA_WIDTH   :   integer :=  32;
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
    end component;
    
    component bram_sp is
        generic(    g_BRAM_ADDR_WIDTH   :   integer :=  16;
                    g_BRAM_DATA_WIDTH   :   integer :=  32);
        port(       clk_in              :   in std_logic;
                    wr_en               :   in std_logic;
                    rd_en               :   in std_logic;
                    addr_wr             :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                    addr_rd             :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                    data_in             :   in std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
                    data_out            :   out std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0));
    end component;

    constant rows               :   integer     :=  27;
    constant cols               :   integer     :=  26;
    constant bram_addrwidth         :   integer     :=  14;
    constant bram_datawidth         :   integer     :=  32;
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
    signal bram_addr_wr_xfer                :   std_logic_vector(bram_addrwidth-1 downto 0);
--    signal bram_addr_rd_xfer                :   std_logic_vector(bram_addrwidth-1 downto 0);    
--    signal data_out_xfer                    :   std_logic_vector(bram_datawidth-1 downto 0);
    constant clks_per_bit                   :   integer     :=  434; --50M / 921600 = 54.253... -- Needs to be set correctly => 50Mhz / 115200BAUD = 434.03...
    
    signal shift_row_xfer                   :   std_logic;
    signal shift_col_xfer                   :   std_logic;
    signal rx_byte_xfer                     :   std_logic_vector(7 downto 0);
    signal rx_dv_xfer                       :   std_logic;
    signal row_xfer                         :   std_logic_vector(rows downto 1);
    signal col_xfer                         :   std_logic_vector(cols downto 1);
    signal clk_in                           :   std_logic;
begin

    clk_in  <= clk;

cntr: component counter
        generic map(    g_cntr_width    =>  bram_datawidth)
        port map(       clk             =>  ro_xfer,
                        rst             =>  cntr_rst_xfer,
                        clk_enbl        =>  cntr_enbl_xfer,
                        cnt_out         =>  cnt_out_xfer);
                        
sngl_ro: component ro_array
        generic map(    num_rows        =>  rows,
                        num_cols        =>  cols)
        port map(       shift_row_input =>  shift_row_xfer,
                        shift_col_input =>  shift_col_xfer,
                        clk             =>  clk_in,
                        circuit_output  =>  ro_xfer,
                        sig_shift_row       =>  row_xfer,
                        sig_shift_col       =>  col_xfer);
                        
cntrl_unt: component control_test
        generic map(    g_BRAM_ADDR_WIDTH   =>  bram_addrwidth,
                        g_BRAM_DATA_WIDTH   =>  bram_datawidth,
                        g_NUM_ROWS          =>  rows,
                        g_NUM_COLS          =>  cols)
        port map(       clk                 =>  clk_in,
                        fsm_rst             =>  rst,
                        cntr_rst            =>  cntr_rst_xfer,
                        cntr_clk_enbl       =>  cntr_enbl_xfer,
                        bram_wr_enbl        =>  bram_wr_enbl_xfer,
                        bram_rd_enbl        =>  bram_read_enbl_xfer,
                        bram_addr           =>  bram_addr_wr_xfer,
                        shift_row_out       =>  shift_row_xfer,
                        shift_col_out       =>  shift_col_xfer,
                        rx_byte             =>  Test_en,
                        cntr_cycle          =>  P_r,
                        m_done              =>  T_finish,                      
                        sig_shift_row       =>  row_xfer,
                        sig_shift_col       =>  col_xfer );
                        
bram: component bram_sp
        generic map(    g_BRAM_ADDR_WIDTH   =>  bram_addrwidth,
                        g_BRAM_DATA_WIDTH   =>  bram_datawidth)
        port map(       clk_in              =>  clk_in,
                        wr_en               =>  bram_wr_enbl_xfer,
                        rd_en               =>  bram_read_enbl_xfer,
                        addr_wr             =>  bram_addr_wr_xfer,
                        data_in             =>  cnt_out_xfer,
                        addr_rd             =>  R_ADDR,
                        data_out            =>  R_DATA);

end Behavioral;
    