----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.10.2014 15:25:58
-- Design Name: 
-- Module Name: clk_div - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_div is
    port(   clk_in  :   in std_logic;
            clk_out :   out std_logic);
end clk_div;

architecture Behavioral of clk_div is
    signal counter  :   integer     :=  0;
    signal clk_int  :   std_logic   :=  '0';
begin
    clk_out <= clk_int;
    
    process(clk_in)
    begin
        if (rising_edge(clk_in)) then
            if (counter < 100) then
                counter <= counter + 1;
            else
                counter <=  0;
                clk_int  <=  not clk_int;
            end if;
        end if;
    end process;
end Behavioral;
