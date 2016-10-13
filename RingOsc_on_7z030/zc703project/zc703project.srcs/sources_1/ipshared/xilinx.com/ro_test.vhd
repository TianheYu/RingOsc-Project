library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;
--
------------------------------------------------------------------------------------
--
-- Main Entity for ring_osc
--
entity ring_osc is
    port(   Output_clock    : out std_logic;
            previous_sig    : in std_logic;
            ColEN           : in std_logic;
            RowEN           : in std_logic );
end ring_osc;
--
------------------------------------------------------------------------------------
-- 
-- Start of Main Architecture for ring_osc
--	 
architecture low_level_definition of ring_osc is
--
    signal ring_delay1      : std_logic;
    signal ring_delay2      : std_logic;
    signal ring_delay3      : std_logic;
    signal ring_delay4      : std_logic;
    signal ring_delay5      : std_logic;
    signal ring_delay6      : std_logic;
    signal ring_delay7      : std_logic;
    signal ring_delay8      : std_logic;
    signal ring_invert      : std_logic;
    signal reset            : std_logic;

--
-- Attributes to stop delay logic from being optimised.
--
    attribute dont_touch                : string; 
    attribute dont_touch of ring_delay1 : signal is "true"; 
    attribute dont_touch of ring_delay2 : signal is "true"; 
    attribute dont_touch of ring_delay3 : signal is "true"; 
    attribute dont_touch of ring_delay4 : signal is "true";
    attribute dont_touch of ring_delay5 : signal is "true"; 
    attribute dont_touch of ring_delay6 : signal is "true"; 
    attribute dont_touch of ring_delay7 : signal is "true";
    attribute dont_touch of ring_delay8 : signal is "true"; 
    attribute dont_touch of ring_invert : signal is "true"; 
    attribute dont_touch of reset       : signal is "true";   

    attribute dont_touch of Xor_out         : label is "true";
    attribute dont_touch of invert_lut      : label is "true";
    attribute dont_touch of En_row_col      : label is "true";
    attribute dont_touch of delay1_lut      : label  is "true";
    attribute dont_touch of delay2_lut      : label  is "true";
    attribute dont_touch of delay3_lut      : label  is "true";
    attribute dont_touch of delay4_lut      : label  is "true";
    attribute dont_touch of delay5_lut      : label  is "true";
    attribute dont_touch of delay6_lut      : label  is "true";
    attribute dont_touch of delay7_lut      : label  is "true";
    attribute dont_touch of delay8_lut      : label  is "true";

    attribute RLOC                  : string;
    attribute RLOC of delay1_lut    : label  is "X0Y4";
    attribute RLOC of delay2_lut    : label  is "X0Y4";
    attribute RLOC of delay3_lut    : label  is "X0Y3";
    attribute RLOC of delay4_lut    : label  is "X0Y3";
    attribute RLOC of delay5_lut    : label  is "X0Y2";
    attribute RLOC of delay6_lut    : label  is "X0Y2";
    attribute RLOC of delay7_lut    : label  is "X0Y1";
    attribute RLOC of delay8_lut    : label  is "X0Y1";
    attribute RLOC of invert_lut    : label  is "X0Y0";
    attribute RLOC of En_row_col    : label  is "X0Y0";
    attribute RLOC of Xor_out       : label  is "X0Y0";

--assign position of all cells
    attribute BEL                   : string;
    attribute BEL of delay1_lut     : label  is "A6LUT";
    attribute BEL of delay2_lut     : label  is "B6LUT";
    attribute BEL of delay3_lut     : label  is "A6LUT";
    attribute BEL of delay4_lut     : label  is "B6LUT";
    attribute BEL of delay5_lut     : label  is "A6LUT";
    attribute BEL of delay6_lut     : label  is "B6LUT";
    attribute BEL of delay7_lut     : label  is "A6LUT";
    attribute BEL of delay8_lut     : label  is "B6LUT";
    attribute BEL of invert_lut     : label  is "C6LUT";
    attribute BEL of Xor_out        : label  is "B6LUT";
    attribute BEL of En_row_col     : label  is "A6LUT";

--	
-- Circuit description
--	
begin

En_row_col: component LUT2
    generic map(    INIT    => X"7")
    port map(       I0      => ColEN,
                    I1      => RowEN,
                    O       => reset);

Xor_out: component LUT2
    generic map(    INIT    => X"6")
    port map(       I0      => ring_invert,
                    I1      => previous_sig,
                    O       => Output_clock);

delay1_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_invert,
                    O       => ring_delay1);

delay2_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay1,
                    O       => ring_delay2);

delay3_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay2,
                    O       => ring_delay3);

delay4_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay3,
                    O       => ring_delay4 );

delay5_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay4,
                    O       => ring_delay5);

delay6_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay5,
                    O       => ring_delay6);

delay7_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay6,
                    O       => ring_delay7);
delay8_lut: component LUT1
    generic map(    INIT    => X"1")
    port map(       I0      => ring_delay7,
                    O       => ring_delay8);

invert_lut: component LUT2
    generic map(    INIT    => X"B") 
    port map(       I0      => reset,
                    I1      => ring_delay8,
                    O       => ring_invert );
                    
end low_level_definition;
