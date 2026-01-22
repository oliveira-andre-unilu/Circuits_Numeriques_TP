----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.11.2025 17:06:41
-- Design Name: 
-- Module Name: memory - Behavioral
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
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY memory IS
    PORT (
        clk : IN STD_LOGIC;
        wr : IN STD_LOGIC;
        addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        datawr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        datard : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        io_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END memory;

ARCHITECTURE Behavioral OF memory IS
    TYPE ramtype IS ARRAY (0 TO 8191) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ram : ramtype;
    TYPE page0type IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL page0 : page0type;
    SIGNAL memoryrd, page0rd : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_out_r : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    pwrite : PROCESS (clk) BEGIN
        IF clk'event AND clk = '1' THEN
            IF wr = '1' THEN
                ram(to_integer(unsigned(addr))) <= datawr;
            END IF;
        END IF;
    END PROCESS;

    pread : PROCESS (clk) BEGIN
        IF clk'event AND clk = '0' THEN
            memoryrd <= ram(to_integer(unsigned(addr)));
        END IF;
    END PROCESS;

    pwrperiph : PROCESS (clk) BEGIN
        IF clk'event AND clk = '1' THEN
            IF wr = '1' AND addr(15 DOWNTO 8) = x"00" THEN
                CASE addr(7 DOWNTO 0) IS
                    WHEN x"fc" => io_out_r(7 DOWNTO 0) <= datawr;
                    WHEN x"fd" => io_out_r(15 DOWNTO 8) <= datawr;
                    WHEN x"fe" => io_out_r(23 DOWNTO 16) <= datawr;
                    WHEN x"ff" => io_out_r(31 DOWNTO 24) <= datawr;
                    WHEN OTHERS => NULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    io_out <= io_out_r;

    page0rd <= page0(to_integer(unsigned(addr(7 DOWNTO 0))));
    datard <= page0rd WHEN addr(15 DOWNTO 8) = x"00" ELSE
        memoryrd;

    page0(248) <= io_in(7 DOWNTO 0);
    page0(249) <= io_in(15 DOWNTO 8);
    page0(250) <= io_in(23 DOWNTO 16);
    page0(251) <= io_in(31 DOWNTO 24);
    page0(252) <= io_out_r(7 DOWNTO 0);
    page0(253) <= io_out_r(15 DOWNTO 8);
    page0(254) <= io_out_r(23 DOWNTO 16);
    page0(255) <= io_out_r(31 DOWNTO 24);

    page0(0 TO 247) <= (
    x"01", x"02", x"03", x"04",
    OTHERS => x"00");

END Behavioral;