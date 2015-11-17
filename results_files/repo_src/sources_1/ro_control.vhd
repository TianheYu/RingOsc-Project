----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2014 10:33:07
-- Design Name: 
-- Module Name: ro_control - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ro_control is
    generic(    clks_per_bit    :   integer :=  217;       -- 200Mhz / 115200BAUD = 1736.1111...
                g_ROWS          :   integer :=  10;
                g_COLS          :   integer :=  10);
    port(       clk_in          :   in std_logic;
                ro_in           :   in std_logic;
                ro_row_shift    :   out std_logic;
                ro_col_shift    :   out std_logic;
                rst_all_shift   :   out std_logic;
                ser_rx          :   in std_logic;
                ser_tx          :   out std_logic);
end ro_control;

architecture Behavioral of ro_control is

    component control_unit is
        generic(    g_ROWS              :   integer :=  10;
                    g_COLS              :   integer :=  10;
                    g_bram_addr_width   :   integer :=  16;
                    g_bram_data_width   :   integer :=  32);
        port(       clk_in              :   in std_logic;
                    cntr_enbl           :   out std_logic;
                    cntr_rst            :   out std_logic;
                    bram_wr_enbl        :   out std_logic;
                    bram_addr_out       :   out std_logic_vector((g_bram_addr_width - 1) downto 0);
                    bram_data_in        :   in std_logic_vector((g_bram_data_width - 1) downto 0);
                    ro_shift_row        :   out std_logic;
                    ro_shift_col        :   out std_logic;
                    rst_all_shift       :   out std_logic;   
                    rx_byte             :   in std_logic_vector(7 downto 0);
                    rx_en               :   in std_logic;
                    tx_rdy              :   in std_logic;
                    tx_done             :   in std_logic;
                    tx_dv               :   out std_logic;
                    tx_byte             :   out std_logic_vector(7 downto 0));
    end component;

    component uart_tx is
        generic (   g_CLKS_PER_BIT  : integer := 1736);     
        port (      i_clk           : in std_logic;
                    i_tx_dv         : in std_logic;
                    i_tx_byte       : in std_logic_vector(7 downto 0);
                    o_tx_done       : out std_logic;
                    o_tx_ready      : out std_logic;
                    o_tx_serial     : out std_logic);
    end component;
    
    component uart_rx is
        generic(    g_CLKS_PER_BIT  :   integer := 115);     -- Needs to be set correctly
        port(       i_clk           :   in  std_logic;
                    i_rx_serial     :   in  std_logic;
                    o_rx_dv         :   out std_logic;
                    o_rx_byte       :   out std_logic_vector(7 downto 0));
    end component;
    
    component bram_sp is
        generic(    g_BRAM_ADDR_WIDTH   :   integer :=  16;
                    g_BRAM_DATA_WIDTH   :   integer :=  32);
        port(       clk_in              :   in std_logic;
                    wr_en               :   in std_logic;
                    addr                :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                    data_in             :   in std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
                    data_out            :   out std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0));
    end component;
    
    component counter is
        generic(    g_cntr_width    :   integer :=  32);
        port(       cnt_clk         :   in std_logic;
                    rst             :   in std_logic;
                    cnt_enbl        :   in std_logic;
                    cnt_out         :   out std_logic_vector((g_cntr_width - 1) downto 0));     
    end component;

    
    constant const_bram_addr_width  :   integer :=  integer(ceil(log2(real(g_ROWS * g_COLS))));
    constant const_bram_data_width  :   integer :=  16;
    
    -- UART_TX COMPONENT SIGNALS:
    signal i_tx_dv_xfer     :   std_logic;
    signal i_tx_byte_xfer   :   std_logic_vector(7 downto 0);
    signal o_tx_done_xfer   :   std_logic;
    signal o_tx_ready_xfer  :   std_logic;
    
    -- UART_RX COMPONENT SIGNALS:
    signal o_rx_dv_xfer     :   std_logic;
    signal o_rx_byte_xfer   :   std_logic_vector(7 downto 0);
    
    -- ASCII_DECODE COMPONENT SIGNALS:
    signal hex_in_xfer      :   std_logic_vector(3 downto 0);
    signal byte_out_xfer    :   std_logic_vector(7 downto 0);
    
    -- BRAM COMPONENT SIGNALS:
    signal wr_en_xfer       :   std_logic;
    signal addr_xfer        :   std_logic_vector((const_bram_addr_width - 1) downto 0);
    signal data_out_xfer     :   std_logic_vector((const_bram_data_width - 1) downto 0);
    
    -- COUNTER COMPONENT SIGNALS
    signal cntr_rst_xfer    :   std_logic;
    signal cntr_enbl_xfer   :   std_logic;
    signal cnt_out_xfer     :   std_logic_vector((const_bram_data_width - 1) downto 0);
    
--    attribute dont_touch    :   string;
--    attribute dont_touch of counter :   component is "true";
    
begin

bram0: component bram_sp
        generic map(    g_BRAM_ADDR_WIDTH   =>  const_bram_addr_width,
                        g_BRAM_DATA_WIDTH   =>  const_bram_data_width)
        port map(       clk_in              =>  clk_in,
                        wr_en               =>  wr_en_xfer,
                        addr                =>  addr_xfer,
                        data_in             =>  cnt_out_xfer,
                        data_out            =>  data_out_xfer);

cu0: component control_unit
        generic map(    g_ROWS              =>  g_ROWS,
                        g_COLS              =>  g_COLS,
                        g_bram_addr_width   =>  const_bram_addr_width,
                        g_bram_data_width   =>  const_bram_data_width)
        port map(       clk_in              =>  clk_in,
                        cntr_enbl           =>  cntr_enbl_xfer,
                        cntr_rst            =>  cntr_rst_xfer,
                        bram_wr_enbl        =>  wr_en_xfer,
                        bram_addr_out       =>  addr_xfer,
                        bram_data_in        =>  data_out_xfer,
                        ro_shift_row        =>  ro_row_shift,
                        ro_shift_col        =>  ro_col_shift,
                        rst_all_shift       =>  rst_all_shift,
                        rx_byte             =>  o_rx_byte_xfer,
                        rx_en               =>  o_rx_dv_xfer,
                        tx_rdy              =>  o_tx_ready_xfer,
                        tx_done             =>  o_tx_done_xfer,
                        tx_dv               =>  i_tx_dv_xfer,
                        tx_byte             =>  i_tx_byte_xfer);
                        
cntr0: component counter
        generic map(    g_cntr_width    =>  const_bram_data_width)    
        port map(       cnt_clk         =>  ro_in,
                        rst             =>  cntr_rst_xfer,
                        cnt_enbl        =>  cntr_enbl_xfer,
                        cnt_out         =>  cnt_out_xfer);    
                        
tx0: component uart_tx
        generic map(    g_CLKS_PER_BIT  =>  clks_per_bit)
        port map(       i_clk           =>  clk_in,
                        i_tx_dv         =>  i_tx_dv_xfer,
                        i_tx_byte       =>  i_tx_byte_xfer,
                        o_tx_done       =>  o_tx_done_xfer,
                        o_tx_ready      =>  o_tx_ready_xfer,
                        o_tx_serial     =>  ser_tx);
                    
rx0: component uart_rx
        generic map(    g_CLKS_PER_BIT  =>  clks_per_bit)
        port map(       i_clk           =>  clk_in,
                        i_rx_serial     =>  ser_rx,
                        o_rx_dv         =>  o_rx_dv_xfer,
                        o_rx_byte       =>  o_rx_byte_xfer);
                    
end Behavioral;
