----------------------------------------------------------------------------------
-- Interface module
--
-- This module connects the CPU's memory-mapped I/O bus to the
-- physical inputs and outputs of the FPGA board:
--
-- Inputs to CPU:
--   - Push buttons
--   - Slide switches
--
-- Outputs from CPU:
--   - LEDs
--   - 4-digit 7-segment display (multiplexed)
--
-- The CPU communicates only via io_in / io_out.
-- This module translates those signals to real hardware.
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;  -- used for simple vector increment (clock divider)

ENTITY interface IS
  PORT (
    --------------------------------------------------------------------------
    -- CPU-facing I/O buses
    --------------------------------------------------------------------------

    io_in : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- io_in bit layout (read by CPU):
    --   31:28 = unused (always 0)
    --   27:24 = buttons (btnU, btnL, btnR, btnD)
    --   23:16 = unused (always 0)
    --   15:0  = slide switches

    io_out : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- io_out bit layout (written by CPU):
    --   31:24 = left 7-seg display digits
    --   23:16 = right 7-seg display digits
    --   15:0  = LEDs

    --------------------------------------------------------------------------
    -- System signals
    --------------------------------------------------------------------------
    clk : IN STD_LOGIC;  -- system clock (fast FPGA clock)

    --------------------------------------------------------------------------
    -- Physical inputs
    --------------------------------------------------------------------------
    btnU, btnL, btnR, btnD : IN STD_LOGIC;     -- push buttons
    sw : IN STD_LOGIC_VECTOR(15 DOWNTO 0);     -- slide switches

    --------------------------------------------------------------------------
    -- Physical outputs
    --------------------------------------------------------------------------
    led : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);   -- LEDs
    seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);    -- 7-segment segments (a–g)
    dp  : OUT STD_LOGIC;                       -- decimal point
    an  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)     -- anode enable (digit select)
  );
END interface;

ARCHITECTURE Behavioral OF interface IS

  --------------------------------------------------------------------------
  -- Clock divider counter
  -- Used to generate slower clocks for:
  --   - button sampling
  --   - display multiplexing
  --------------------------------------------------------------------------
  SIGNAL clkdiv : STD_LOGIC_VECTOR(15 DOWNTO 0);

  --------------------------------------------------------------------------
  -- Currently selected hex digit for 7-seg display
  --------------------------------------------------------------------------
  SIGNAL dispsel : STD_LOGIC_VECTOR(3 DOWNTO 0);

  --------------------------------------------------------------------------
  -- Encoded 7-seg pattern including decimal point
  --------------------------------------------------------------------------
  SIGNAL dpseg : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

  --------------------------------------------------------------------------
  -- Clock divider
  -- Increments on every rising edge of the system clock.
  -- Each bit of clkdiv is a slower clock than the previous one.
  --------------------------------------------------------------------------
  pdiv : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      clkdiv <= clkdiv + 1;
    END IF;
  END PROCESS;

  --------------------------------------------------------------------------
  -- Button sampling
  -- Buttons are sampled using a slow clock (clkdiv(15))
  -- to reduce bouncing and avoid excessive CPU polling.
  --
  -- Button bits are packed into io_in[27:24]
  --------------------------------------------------------------------------
  pbut : PROCESS (clkdiv(15))
  BEGIN
    IF rising_edge(clkdiv(15)) THEN
      io_in(27 DOWNTO 24) <= btnU & btnL & btnR & btnD;
    END IF;
  END PROCESS;

  --------------------------------------------------------------------------
  -- Unused upper bits of io_in are tied to zero
  --------------------------------------------------------------------------
  io_in(31 DOWNTO 28) <= x"0";
  io_in(23 DOWNTO 16) <= x"00";

  --------------------------------------------------------------------------
  -- Switch inputs
  -- Directly mapped into io_in[15:0]
  --------------------------------------------------------------------------
  io_in(15 DOWNTO 0) <= sw;

  --------------------------------------------------------------------------
  -- LED outputs
  -- LEDs directly reflect io_out[15:0]
  --------------------------------------------------------------------------
  led <= io_out(15 DOWNTO 0);

  --------------------------------------------------------------------------
  -- 7-segment display multiplexing
  --
  -- clkdiv[15:14] selects which digit is currently active.
  -- Each digit is displayed for a short time, creating the
  -- illusion that all digits are on simultaneously.
  --------------------------------------------------------------------------

  -- Select which hex digit to display
  WITH clkdiv(15 DOWNTO 14) SELECT
    dispsel <=
      io_out(31 DOWNTO 28) WHEN "00",  -- digit 0
      io_out(27 DOWNTO 24) WHEN "01",  -- digit 1
      io_out(23 DOWNTO 20) WHEN "10",  -- digit 2
      io_out(19 DOWNTO 16) WHEN "11",  -- digit 3
      x"0"                WHEN OTHERS;

  -- Select which anode is enabled (active-low)
  WITH clkdiv(15 DOWNTO 14) SELECT
    an <=
      x"7" WHEN "00",  -- enable digit 0
      x"b" WHEN "01",  -- enable digit 1
      x"d" WHEN "10",  -- enable digit 2
      x"e" WHEN "11",  -- enable digit 3
      x"f" WHEN OTHERS;

  --------------------------------------------------------------------------
  -- Hex digit to 7-segment encoding
  -- dpseg bits are active-low
  --------------------------------------------------------------------------
  WITH dispsel SELECT
    dpseg <=
      x"c0" WHEN x"0", x"f9" WHEN x"1", x"a4" WHEN x"2", x"b0" WHEN x"3",
      x"99" WHEN x"4", x"92" WHEN x"5", x"82" WHEN x"6", x"f8" WHEN x"7",
      x"80" WHEN x"8", x"90" WHEN x"9", x"88" WHEN x"a", x"83" WHEN x"b",
      x"c6" WHEN x"c", x"a1" WHEN x"d", x"86" WHEN x"e", x"8e" WHEN x"f",
      x"ff" WHEN OTHERS;

  --------------------------------------------------------------------------
  -- Drive segment outputs
  --------------------------------------------------------------------------
  seg <= dpseg(6 DOWNTO 0);  -- segments a–g
  dp  <= '1';               -- decimal point always off

END Behavioral;
