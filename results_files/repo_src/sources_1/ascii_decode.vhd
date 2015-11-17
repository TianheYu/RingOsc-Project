library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ascii_decode is
    port(   hex_in      :   in std_logic_vector(15 downto 0);
            byte_out    :   out std_logic_vector(31 downto 0));
end ascii_decode;

architecture Behavioral of ascii_decode is
    type lut is array (15 downto 0) of std_logic_vector(7 downto 0);
    
    function init_lut return lut is
        variable    ret :   lut;
    begin
        ret(0)  :=  x"30";
        ret(1)  :=  x"31";
        ret(2)  :=  x"32";
        ret(3)  :=  x"33";
        ret(4)  :=  x"34";
        ret(5)  :=  x"35";
        ret(6)  :=  x"36";
        ret(7)  :=  x"37";
        ret(8)  :=  x"38";
        ret(9)  :=  x"39";
        ret(10) :=  x"41";
        ret(11) :=  x"42";
        ret(12) :=  x"43";
        ret(13) :=  x"44";
        ret(14) :=  x"45";
        ret(15) :=  x"46";
        return ret;
    end init_lut;
--need to understand how this is claimed    
    signal ascii_lut    :   lut :=  init_lut;
    signal byte_xfer    :   std_logic_vector(31 downto 0);
    
begin        
        byte_xfer(31 downto 24)   <=  ascii_lut(to_integer(unsigned(hex_in(15 downto 12))));
        byte_xfer(23 downto 16)   <=  ascii_lut(to_integer(unsigned(hex_in(11 downto 8))));
        byte_xfer(15 downto 8)    <=  ascii_lut(to_integer(unsigned(hex_in(7  downto 4))));
        byte_xfer(7  downto 0)    <=  ascii_lut(to_integer(unsigned(hex_in(3  downto 0))));
        
        byte_out    <=  byte_xfer;

end Behavioral;
