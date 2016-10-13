library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity bram_sp is
    generic(    g_BRAM_ADDR_WIDTH   :   integer :=  12;
                g_BRAM_DATA_WIDTH   :   integer :=  16);
    port(       clk_in              :   in std_logic;
                wr_en               :   in std_logic;
                rd_en               :   in std_logic;
                addr_wr             :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                addr_rd             :   in std_logic_vector((g_BRAM_ADDR_WIDTH - 1) downto 0);
                data_in             :   in std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
                data_out            :   out std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0));
end bram_sp;

architecture Behavioral of bram_sp is

    
    type ram is array (((2 ** g_BRAM_ADDR_WIDTH) - 1) downto 0) of std_logic_vector((g_BRAM_DATA_WIDTH - 1) downto 0);
    signal BRAM :   ram :=  (others => (others => '0'));
    
begin

ram_proc: process(clk_in)
    begin
        if (rising_edge(clk_in)) then
            if (wr_en = '1' and rd_en = '0') then
                BRAM(to_integer(unsigned(addr_wr))) <=  data_in;
            end if;
	        if (rd_en = '1' and wr_en = '0') then
		        data_out   <=  BRAM(to_integer(unsigned(addr_rd)));
            end if;            
        end if;
    end process;

end Behavioral;

