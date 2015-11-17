----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Receiver.  This receiver is able to
-- receive 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When receive is complete o_rx_dv will be
-- driven high for one clock cycle.
-- 
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity uart_rx is
    generic(    g_CLKS_PER_BIT  :   integer := 434);     -- Needs to be set correctly => 50Mhz / 115200BAUD = 434.03...
    port(       i_clk           :   in  std_logic;
                i_rx_serial     :   in  std_logic;
                o_rx_dv         :   out std_logic;
                o_rx_byte       :   out std_logic_vector(7 downto 0));
end uart_rx;

architecture rtl of uart_rx is

    type t_SM_MAIN is (s_IDLE, s_RX_START_BIT, s_RX_DATA_BITS, s_RX_STOP_BIT, s_CLEANUP);
    signal r_SM_MAIN    : t_SM_MAIN                             := s_IDLE;
    signal r_RX_DATA_R  : std_logic                             := '0';
    signal r_RX_DATA    : std_logic                             := '0';
    signal r_CLK_COUNT  : integer range 0 to g_CLKS_PER_BIT-1   := 0;
    signal r_BIT_INDEX  : integer range 0 to 7                  := 0;  -- 8 Bits Total
    signal r_RX_BYTE    : std_logic_vector(7 downto 0)          := (others => '0');
    signal r_RX_DV      : std_logic                             := '0';

begin
    -- Purpose: Double-register the incoming data.
    -- This allows it to be used in the UART RX Clock Domain.
    -- (It removes problems caused by metastabiliy)
p_SAMPLE: process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_RX_DATA_R <= i_rx_serial;
            r_RX_DATA   <= r_RX_DATA_R;
        end if;
    end process p_SAMPLE;


    -- Purpose: Control RX state machine
p_UART_RX: process (i_clk)
    begin
        if rising_edge(i_clk) then
            case r_SM_MAIN is
                when s_IDLE =>
                    r_RX_DV     <= '0';
                    r_CLK_COUNT <= 0;
                    r_BIT_INDEX <= 0;
                    if r_RX_DATA = '0' then       -- Start bit detected
                        r_SM_MAIN <= s_RX_START_BIT;
                    else
                        r_SM_MAIN <= s_IDLE;
                    end if;
                -- Check middle of start bit to make sure it's still low
                when s_RX_START_BIT =>
                    if r_CLK_COUNT = (g_CLKS_PER_BIT-1)/2 then          --need to be corrected
                        if r_RX_DATA = '0' then
                            r_CLK_COUNT <= 0;  -- reset counter since we found the middle
                            r_SM_MAIN   <= s_RX_DATA_BITS;
                        else
                            r_SM_MAIN   <= s_IDLE;
                        end if;
                    else
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_RX_START_BIT;
                    end if;

                -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
                when s_RX_DATA_BITS =>
                    if r_CLK_COUNT < g_CLKS_PER_BIT-1 then
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_RX_DATA_BITS;
                    else
                        r_CLK_COUNT            <= 0;
                        r_RX_BYTE(r_BIT_INDEX) <= r_RX_DATA;
                        -- Check if we have sent out all bits
                        if r_BIT_INDEX < 7 then
                            r_BIT_INDEX <= r_BIT_INDEX + 1;
                            r_SM_MAIN   <= s_RX_DATA_BITS;
                        else
                            r_BIT_INDEX <= 0;
                            r_SM_MAIN   <= s_RX_STOP_BIT;
                        end if;
                    end if;
                -- Receive Stop bit.  Stop bit = 1
                when s_RX_STOP_BIT =>
                    -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                    if r_CLK_COUNT < g_CLKS_PER_BIT-1 then
                        r_CLK_COUNT <= r_CLK_COUNT + 1;
                        r_SM_MAIN   <= s_RX_STOP_BIT;
                    else
                        r_RX_DV     <= '1';
                        r_CLK_COUNT <= 0;
                        r_SM_MAIN   <= s_CLEANUP;
                    end if;
                -- Stay here 1 clock
                when s_CLEANUP =>
                    r_SM_MAIN <= s_IDLE;
                    r_RX_DV   <= '0';
                when others =>
                    r_SM_MAIN <= s_IDLE;
            end case;
        end if;
    end process p_UART_RX;

    o_rx_dv   <= r_RX_DV;
    o_rx_byte <= r_RX_BYTE;

end rtl;