library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter is
    generic(    g_cntr_width    :   integer :=  32);
    port(       clk             :   in std_logic;
                rst             :   in std_logic;
                clk_enbl        :   in std_logic;
                cnt_out         :   out std_logic_vector((g_cntr_width - 1) downto 0));     
end counter;

architecture Behavioral of counter is
    signal counter :   std_logic_vector((g_cntr_width - 1) downto 0)   :=  (others => '0');
begin

cntr_proc: process(clk, rst)
    begin
        if (rst = '1') then
            counter <=  (others => '0');
        elsif (rising_edge(clk)) then
            if (clk_enbl = '1') then
                counter <=  std_logic_vector(unsigned(counter) + 1);
            end if;
        end if;
    end process;
    
    cnt_out <=  counter;

end Behavioral;
