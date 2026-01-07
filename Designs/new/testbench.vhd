-- TODO: Have good understandable comments
-- TODO: Format

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.11.2025 17:33:10
-- Design Name: 
-- Module Name: testbench - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY testbench IS
    --  Port ( );
END testbench;

ARCHITECTURE Behavioral OF testbench IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC;
    SIGNAL wr : STD_LOGIC;
    SIGNAL addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL datawr : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL datard : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL io_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    COMPONENT memory IS
        PORT (
            clk : IN STD_LOGIC;
            wr : IN STD_LOGIC;
            addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            datawr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            datard : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            io_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            io_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT cpu IS
        PORT (
            clk, rst : IN STD_LOGIC;
            wr : OUT STD_LOGIC;
            addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            datawr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            datard : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

BEGIN
    cmem : memory PORT MAP(clk, wr, addr, datawr, datard, io_in, io_out);
    ccpu : cpu PORT MAP(clk, rst, wr, addr, datawr, datard);
    clk <= NOT clk AFTER 500ps;
    rst <= '1', '0' AFTER 400ps;
    PROCESS BEGIN
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"01000000";
        WAIT FOR 50ns;
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"03000000";
        WAIT FOR 50ns;
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"02000000";
        WAIT FOR 50ns;
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"02000000";
        WAIT FOR 50ns;
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"08000000";
        WAIT FOR 50ns;
        io_in <= x"00000000";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"01000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"08000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"05000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"08000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"01000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"08000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        io_in <= x"09000043";
        WAIT FOR 50ns;
        io_in <= x"00000043";
        WAIT FOR 50ns;
        WAIT FOR 16000ns;
        io_in <= x"00000002";
        WAIT FOR 50ns;
        io_in <= x"00000004";
        WAIT FOR 50ns;
        io_in <= x"00000009";
        WAIT FOR 50ns;
        io_in <= x"00000002";
        WAIT FOR 50ns;
        io_in <= x"0000000A";
        WAIT FOR 50ns;
        io_in <= x"0000000B";
        WAIT FOR 50ns;

        WAIT;
    END PROCESS;
END Behavioral;