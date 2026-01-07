-- TODO: Have good understandable comments
-- TODO: Format

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.01.2025 23:14:40
-- Design Name: 
-- Module Name: interface - Behavioral
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY interface IS
  --  Port ( );
  PORT (
    io_in : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- 31:28 = unused
    -- 27:24 = buttons
    -- 23:16 = unused
    -- 15:0 = switches
    io_out : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- 31:24 = disp left bank
    -- 23:16 = disp right bank
    -- 15:0 = leds
    clk : IN STD_LOGIC;
    btnU, btnL, btnR, btnD : IN STD_LOGIC;
    sw : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    led : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    dp : OUT STD_LOGIC;
    an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END interface;

ARCHITECTURE Behavioral OF interface IS
  SIGNAL clkdiv : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL dispsel : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL dpseg : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
  -- clock divider
  pdiv : PROCESS (clk) BEGIN IF rising_edge(clk) THEN
    clkdiv <= clkdiv + 1;
  END IF;
END PROCESS;
-- buttons
pbut : PROCESS (clkdiv(15)) BEGIN IF rising_edge(clkdiv(15)) THEN
  io_in(27 DOWNTO 24) <= btnU & btnL & btnR & btnD;
END IF;
END PROCESS;
io_in(31 DOWNTO 28) <= x"0";
io_in(23 DOWNTO 16) <= x"00";
-- switches
io_in(15 DOWNTO 0) <= sw;
-- leds
led <= io_out(15 DOWNTO 0);
-- 7seg display
WITH clkdiv(15 DOWNTO 14) SELECT
dispsel <= io_out(31 DOWNTO 28) WHEN "00", io_out(27 DOWNTO 24) WHEN "01", io_out(23 DOWNTO 20) WHEN "10", io_out(19 DOWNTO 16) WHEN "11",
  x"0" WHEN OTHERS;
WITH clkdiv(15 DOWNTO 14) SELECT
an <= x"7" WHEN "00", x"b" WHEN "01", x"d" WHEN "10", x"e" WHEN "11",
  x"f" WHEN OTHERS;
WITH dispsel SELECT
  dpseg <= x"c0" WHEN x"0", x"f9" WHEN x"1", x"a4" WHEN x"2", x"b0" WHEN x"3", x"99" WHEN x"4", x"92" WHEN x"5",
  x"82" WHEN x"6", x"f8" WHEN x"7", x"80" WHEN x"8", x"90" WHEN x"9", x"88" WHEN x"a", x"83" WHEN x"b",
  x"c6" WHEN x"c", x"a1" WHEN x"d", x"86" WHEN x"e", x"8e" WHEN x"f",
  x"ff" WHEN OTHERS;
seg <= dpseg(6 DOWNTO 0);
dp <= '1';
END Behavioral;