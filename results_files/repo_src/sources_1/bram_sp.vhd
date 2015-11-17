library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity bram_sp is
    generic(    g_BRAM_ADDR_WIDTH   :   integer :=  12;
                g_BRAM_DATA_WIDTH   :   integer :=  16);
    port(       clk_in              :   in std_logic;
                wr_en               :   in std_logic;
                rd_en               :   in std_logic;
                addr                :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                data_in             :   in std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
                data_out            :   out std_logic_vector((2 * g_BRAM_DATA_WIDTH - 1) downto 0));
end bram_sp;

architecture Behavioral of bram_sp is

    component ascii_decode is
    port(   hex_in      :   in  std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
            byte_out    :   out std_logic_vector((2 * g_BRAM_DATA_WIDTH - 1) downto 0));
    end component;
    
    type ram is array (((2 ** g_BRAM_ADDR_WIDTH) - 1) downto 0) of std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
    signal BRAM :   ram :=  (others => (others => '0'));
    
    signal hex_in_xfer       :  std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
    signal byte_out_xfer     :  std_logic_vector((2 * g_BRAM_DATA_WIDTH - 1) downto 0);
begin

dec0: component ascii_decode
            port map(  hex_in          =>  hex_in_xfer,
                       byte_out        =>  byte_out_xfer);
ram_proc: process(clk_in)
    begin
        if (rising_edge(clk_in)) then
            if (wr_en = '1') then
                BRAM(to_integer(unsigned(addr))) <=  data_in;
            end if;
	    if (rd_en = '1') then
		    hex_in_xfer   <=  BRAM(to_integer(unsigned(addr)));
    		data_out      <=  byte_out_xfer;
            end if;            
        end if;
    end process;

end Behavioral;

