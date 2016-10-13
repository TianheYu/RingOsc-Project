library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity ro_array is
    generic(    num_rows        :   integer :=  27;
                num_cols        :   integer :=  26);
    port(       shift_row_input :   in std_logic;
                shift_col_input :   in std_logic;      
                circuit_output  :   out std_logic;
                clk             :   in std_logic;
                sig_shift_row   :   in std_logic_vector(num_rows downto 1);
                sig_shift_col   :   in std_logic_vector(num_cols downto 1));
end ro_array;

architecture Behavioral of ro_array is

    component ring_osc is                                          																					
        port(   previous_sig    :   in std_logic;
                ColEN           :   in std_logic;
                RowEN           :   in std_logic;	
                Output_clock    :   out std_logic);	                                                                                                                          
    end component ring_osc;
    
    component ring_oscm is                                          																					
        port(   previous_sig    :   in std_logic;
                ColEN           :   in std_logic;
                RowEN           :   in std_logic;    
                Output_clock    :   out std_logic);                                                                                                                              
    end component ring_oscm;
    
    function init_shift (size : integer) return std_logic_vector is
        variable ret    :   std_logic_vector(size downto 2) :=  (others => '0');
    begin
        return (ret & '1');
    end init_shift;
    
    type matrix_sig is array (num_rows downto 1) of std_logic_vector(num_cols downto 1);
    signal RO_sig                   :   matrix_sig;
    signal init_shift_row           :   std_logic_vector(num_rows downto 1) :=  init_shift(num_rows);
    signal init_shift_col           :   std_logic_vector(num_cols downto 1) :=  init_shift(num_cols);
    signal outsig                   :   std_logic_vector(num_rows downto 1);
    attribute dont_touch            :   string;
    attribute u_set                 :   string;
    attribute RLOC                  :   string;
    signal shift_row                :   std_logic_vector(num_rows downto 1) ;
    signal shift_col                :   std_logic_vector(num_cols downto 1) ;
begin
    shift_row     <=     sig_shift_row and init_shift_row;   
    shift_col     <=     sig_shift_col and init_shift_col;
    
Ro1 : for n in 1 to num_rows/3 generate 
        attribute dont_touch of ro : label is "true";
        attribute u_set of ro   : label  is "set1";
        attribute RLOC of ro : label is "X2Y"& integer'image(integer(197-(n-1)*5));   
        begin
        ro: component ring_oscm 
            port map(   previous_sig    => '0',
                           Output_clock    => RO_sig(n)(1),
                           ColEN           => shift_col(1),
                           RowEN           => shift_row(n));
    end generate Ro1;  
    
--left side generate
R1 : FOR n IN 1 TO num_rows/3 GENERATE 
    a1 : for m in 2 to 4 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(197-(n-1)*5));   
       begin
       ro: component ring_oscm  
           port map(previous_sig  => RO_sig(n)(m-1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
    end generate a1;  
END GENERATE R1;     

R1m : FOR n IN 1 TO num_rows/3 GENERATE 
   a1m : for m in 5 to 20 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(197-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a1m;  
END GENERATE R1m;  

R11m : FOR n IN 1 TO num_rows/3 GENERATE 
   a11m : for m in 21 to 23 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(197-(n-1)*5));      
       begin
       ro: component ring_oscm  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a11m;  
END GENERATE R11m;  

R111m : FOR n IN 1 TO num_rows/3 GENERATE 
   a111m : for m in 24 to num_cols generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(197-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a111m;  
END GENERATE R111m;  
------------------------------------------------------------------
Ro2 : for n in num_rows/3+1 TO num_rows/3*2 generate 
        attribute dont_touch of ro : label is "true";
        attribute u_set of ro   : label  is "set1";
        attribute RLOC of ro : label is "X2Y"& integer'image(integer(192-(n-1)*5));   
        begin
        ro: component ring_oscm 
            port map(   previous_sig    => '0',
                           Output_clock    => RO_sig(n)(1),
                           ColEN           => shift_col(1),
                           RowEN           => shift_row(n));
    end generate Ro2; 

R2 : FOR n IN num_rows/3+1 TO num_rows/3*2 GENERATE 
    a2 : for m in 2 to 4 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(192-(n-1)*5));   
       begin
       ro: component ring_oscm  
           port map(previous_sig  => RO_sig(n)(m-1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
    end generate a2;  
END GENERATE R2;     

R2m : FOR n IN num_rows/3+1 TO num_rows/3*2 GENERATE 
   a2m : for m in 5 to 20 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(192-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a2m;  
END GENERATE R2m;  

R22m : FOR n IN num_rows/3+1 TO num_rows/3*2 GENERATE 
   a22m : for m in 21 to 23 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(192-(n-1)*5));      
       begin
       ro: component ring_oscm  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a22m;  
END GENERATE R22m;  

R222m : FOR n IN num_rows/3+1 TO num_rows/3*2 GENERATE 
   a222m : for m in 24 to num_cols generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(192-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a222m;  
END GENERATE R222m;  
------------------------------------------------------------------
Ro3 : for n in num_rows/3*2+1 TO num_rows generate 
        attribute dont_touch of ro : label is "true";
        attribute u_set of ro   : label  is "set1";
        attribute RLOC of ro : label is "X2Y"& integer'image(integer(187-(n-1)*5));   
        begin
        ro: component ring_oscm 
            port map(   previous_sig    => '0',
                           Output_clock    => RO_sig(n)(1),
                           ColEN           => shift_col(1),
                           RowEN           => shift_row(n));
    end generate Ro3; 

R3 : FOR n IN num_rows/3*2+1 TO num_rows GENERATE 
    a3 : for m in 2 to 4 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(187-(n-1)*5));   
       begin
       ro: component ring_oscm  
           port map(previous_sig  => RO_sig(n)(m-1),
                    Output_clock  => RO_sig(n)(m), 
                    ColEN         => shift_col(m),  
                    RowEN         => shift_row(n)); 
    end generate a3;  
END GENERATE R3;     

R3m : FOR n IN num_rows/3*2+1 TO num_rows GENERATE 
   a3m : for m in 5 to 20 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2))& "Y"& integer'image(integer(187-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a3m;  
END GENERATE R3m;  

R33m : FOR n IN num_rows/3*2+1 TO num_rows GENERATE 
   a33m : for m in 21 to 23 generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(187-(n-1)*5));      
       begin
       ro: component ring_oscm  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a33m;  
END GENERATE R33m;  

R333m : FOR n IN num_rows/3*2+1 TO num_rows GENERATE 
   a333m : for m in 24 to num_cols generate 
       attribute dont_touch of ro : label is "true";
       attribute u_set of ro   : label  is "set1";
       attribute RLOC of ro : label is "X" & integer'image(integer(m*2+14))& "Y"& integer'image(integer(187-(n-1)*5));      
       begin
       ro: component ring_osc  
          port map(previous_sig  => RO_sig(n)(m - 1),
                   Output_clock  => RO_sig(n)(m), 
                   ColEN         => shift_col(m),  
                   RowEN         => shift_row(n)); 
   end generate a333m;  
END GENERATE R333m;  

---------------------------------------------------------------

row_proc: process(clk)
 begin
   if rising_edge(clk) then 
      if(shift_row_input = '1') then
        if init_shift_row(num_rows) = '1' then
          init_shift_row(num_rows)             <= '0';
          init_shift_row(1)                    <= '1';
        else
          init_shift_row(num_rows downto 2)    <= init_shift_row((num_rows - 1) downto 1);
          init_shift_row(1)                    <= '0';
         end if;
      end if; 
   end if;
end process;

col_proc: process(clk)
begin
   if rising_edge(clk) then 
      if(shift_col_input = '1') then
        if init_shift_col(num_cols) = '1' then
          init_shift_col(num_cols)             <= '0';
          init_shift_col(1)                    <= '1';
        else
          init_shift_col(num_cols downto 2)    <= init_shift_col((num_cols - 1) downto 1);
          init_shift_col(1)                    <= '0';
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
