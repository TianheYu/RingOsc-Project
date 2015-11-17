----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Transmitter.  This transmitter is able
-- to transmit 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When transmit is complete o_tx_done will be
-- driven high for one clock cycle.
--
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity uart_tx is
    generic (   g_CLKS_PER_BIT  : integer := 434);     -- Needs to be set correctly => 200Mhz / 115200BAUD = 434.03...
    port (      i_clk           : in std_logic;
                i_tx_dv         : in std_logic;
                i_tx_byte       : in std_logic_vector(7 downto 0);
                o_tx_done       : out std_logic;
                o_tx_ready      : out std_logic;
                o_tx_serial     : out std_logic);
end uart_tx;
 
architecture rtl of uart_tx is
    type t_SM_MAIN is (s_IDLE, s_TX_START_BIT, s_TX_DATA_BITS, s_TX_STOP_BIT, s_CLEANUP);
    signal r_SM_MAIN    : t_SM_MAIN := s_IDLE;
    signal r_CLK_COUNT  : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_BIT_INDEX  : integer range 0 to 7 := 0;  -- 8 Bits Total
    signal r_TX_DATA    : std_logic_vector(7 downto 0) := (others => '0');
    signal r_TX_DONE    : std_logic := '0';
begin

p_UART_TX:  process (i_clk)
    begin
        if rising_edge(i_clk) then
            case r_SM_MAIN is
                when s_IDLE =>
                    o_tx_serial <= '1';         -- Drive Line High for Idle
                    o_tx_ready  <= '1';
                    r_TX_DONE   <= '0';
                    r_CLK_COUNT <= 0;
                    r_BIT_INDEX <= 0;
                    if i_tx_dv = '1' then
                        r_TX_DATA <= i_tx_byte;     --store 8 bits
                        r_SM_MAIN <= s_TX_START_BIT;
                    else
                        r_SM_MAIN <= s_IDLE;
                    end if;

                -- Send out Start Bit. Start bit = 0
                when s_TX_START_BIT =>
                    o_tx_serial <= '0';
                    o_tx_ready <= '0';
                    -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
                    if r_CLK_COUNT < g_CLKS_PER_BIT-1 then
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_TX_START_BIT;
                    else
                        r_CLK_COUNT <= 0;
                        r_SM_MAIN   <= s_TX_DATA_BITS;
                    end if;

                -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish          
                when s_TX_DATA_BITS =>
                    o_tx_serial <= r_TX_DATA(r_BIT_INDEX);
                    if r_CLK_COUNT < g_CLKS_PER_BIT-1 then
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_TX_DATA_BITS;
                    else
                        r_CLK_COUNT <= 0;
                        -- Check if we have sent out all bits
                        if r_BIT_INDEX < 7 then
                            r_BIT_INDEX <= r_BIT_INDEX + 1;
                            r_SM_MAIN   <= s_TX_DATA_BITS;
                        else
                            r_BIT_INDEX <= 0;
                            r_SM_MAIN   <= s_TX_STOP_BIT;
                        end if;
                    end if;

                -- Send out Stop bit.  Stop bit = 1
                when s_TX_STOP_BIT =>
                    o_tx_serial <= '1';
                    -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                    if r_CLK_COUNT < g_CLKS_PER_BIT-1 then
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_TX_STOP_BIT;
                    else
                        r_TX_DONE   <= '1';
                        r_CLK_COUNT <= 0;
                        r_SM_MAIN   <= s_CLEANUP;
                    end if;
                    
                -- Stay here 1 clock
                when s_CLEANUP =>
                    r_TX_DONE <= '1';
                    r_SM_MAIN <= s_IDLE;

                when others =>
                    r_SM_MAIN <= s_IDLE;

            end case;
        end if;
    end process p_UART_TX;
    o_tx_done <= r_TX_DONE;
    
end rtl;