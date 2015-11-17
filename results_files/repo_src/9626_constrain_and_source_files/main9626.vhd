library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity ro_array is
    generic(    num_rows        :   integer :=  96;
                num_cols        :   integer :=  26);
    port(       shift_row_input :   in std_logic;
                shift_col_input :   in std_logic;      
                circuit_output  :   out std_logic;
                clk             :   in std_logic;
                turn_on         :   in std_logic);
end ro_array;

architecture Behavioral of ro_array is

    component ring_osc is                                          																					
        port(   previous_sig    :   in std_logic;
                ColEN           :   in std_logic;
                RowEN           :   in std_logic;	
                Output_clock    :   out std_logic);	                                                                                                                          
    end component ring_osc;
 
    function init_shift (size : integer) return std_logic_vector is
        variable ret    :   std_logic_vector(size downto 2) :=  (others => '0');
    begin
        return (ret & '1');
    end init_shift;
    
    type matrix_sig is array (num_rows downto 1) of std_logic_vector(num_cols downto 1);
    signal RO_sig                   :   matrix_sig;
    
    type heat_sig is array (30 downto 1) of std_logic_vector(30 downto 1);
    signal H_sig                   :   heat_sig;
    
    signal shift_row                :   std_logic_vector(num_rows downto 1) :=  init_shift(num_rows);
    signal shift_col                :   std_logic_vector(num_cols downto 1) :=  init_shift(num_cols);
    signal outsig                   :   std_logic_vector(num_rows downto 1);
    attribute dont_touch            :   string;
    attribute u_set                 :   string;
    attribute RLOC                  :   string;

begin
                     
Ro1 : for n in 1 to num_rows/2 generate 
    attribute dont_touch of ro : label is "true";
    attribute u_set of ro   : label  is "set1";
    attribute RLOC of ro : label is "X2Y"& integer'image(integer(149-n));    
    begin
    ro:     component ring_osc 
           port map(   previous_sig    => '0',
                       Output_clock    => RO_sig(n)(1),
                       ColEN           => shift_col(1),
                       RowEN           => shift_row(n));
end generate Ro1; 
--left side generate
Rl : FOR n IN 1 TO num_rows/2 GENERATE 
    al : for m in 2 to 7 generate 
               attribute dont_touch of ro : label is "true";
               attribute u_set of ro   : label  is "set1";
            attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(149-n));   
               begin
           ro: component ring_osc  
               port map(previous_sig  => RO_sig(n)(m - 1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
    end generate al;  
END GENERATE Rl;     
R : FOR n IN 1 TO num_rows/2 GENERATE 
   a : for m in 8 to num_cols generate 
              attribute dont_touch of ro : label is "true";
              attribute u_set of ro   : label  is "set1";
           attribute RLOC of ro : label is "X" & integer'image(integer(m*2+12))& "Y"& integer'image(integer(149-n));   
              begin
           ro: component ring_osc  
               port map(previous_sig  => RO_sig(n)(m - 1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
   end generate a;  
END GENERATE R;   



Ro12 : for n in num_rows/2+1 to num_rows generate 
    attribute dont_touch of ro : label is "true";
    attribute u_set of ro   : label  is "set1";
    attribute RLOC of ro : label is "X2Y"& integer'image(integer(147-n));    
    begin
    ro:     component ring_osc 
           port map(   previous_sig    => '0',
                       Output_clock    => RO_sig(n)(1),
                       ColEN           => shift_col(1),
                       RowEN           => shift_row(n));
end generate Ro12; 
--left side generate
Rl2 : FOR n IN num_rows/2+1 TO num_rows GENERATE 
    al : for m in 2 to 7 generate 
               attribute dont_touch of ro : label is "true";
               attribute u_set of ro   : label  is "set1";
            attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(147-n));   
               begin
           ro: component ring_osc  
               port map(previous_sig  => RO_sig(n)(m - 1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
    end generate al;  
END GENERATE Rl2;     
R2 : FOR n IN num_rows/2+1 TO num_rows GENERATE 
   a : for m in 8 to num_cols generate 
              attribute dont_touch of ro : label is "true";
              attribute u_set of ro   : label  is "set1";
           attribute RLOC of ro : label is "X" & integer'image(integer(m*2+12))& "Y"& integer'image(integer(147-n));   
              begin
           ro: component ring_osc  
               port map(previous_sig  => RO_sig(n)(m - 1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
   end generate a;  
END GENERATE R2;   

--heat generation
H : FOR n IN 1 TO 30 GENERATE 
   heat : for m in 1 to 30 generate 
              attribute dont_touch of ro : label is "true";
              attribute u_set of ro   : label  is "set2";
              attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(183-n));   
              begin
           ro: component ring_osc  
               port map(previous_sig  => '0',
                    Output_clock  => H_sig(n)(m), 
                    ColEN         => turn_on,  
                    RowEN         => turn_on); 
   end generate heat;  
END GENERATE H;  


row_proc: process(clk)
    begin
        if rising_edge(clk) then 
            if(shift_row_input = '1') then
                if shift_row(num_rows) = '1' then
                    shift_row(num_rows)             <= '0';
                    shift_row(1)                    <= '1';
                else
                    shift_row(num_rows downto 2)    <= shift_row((num_rows - 1) downto 1);
                    shift_row(1)                    <= '0';
                end if;
            end if; 
        end if;
    end process;
   
col_proc: process(clk)
    begin
        if rising_edge(clk) then 
            if (shift_col_input = '1') then 
                if shift_col(num_cols) = '1' then
                    shift_col(num_cols)             <= '0';
                    shift_col(1)                    <= '1';
                else
                    shift_col(num_cols downto 2)    <= shift_col((num_cols - 1) downto 1);
                    shift_col(1)                    <= '0';
                end if;
            end if; 
        end if;
    end process;
    outsig(1)       <= RO_sig(1)(num_cols);
out_gen: for m in 2 to num_rows generate  
    begin
        outsig(m)   <= RO_sig(m)(num_cols) xor outsig(m-1);
    end generate;
    circuit_output  <= outsig(num_rows);
    
end Behavioral;
