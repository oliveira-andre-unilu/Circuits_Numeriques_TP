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
    --signal rst : std_logic;
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

BEGIN
    cmem : memory PORT MAP(clk, wr, addr, datawr, datard, io_in, io_out);
    clk <= NOT clk AFTER 500ps;
    --rst <= '1','0' after 400ps;
    io_in <= x"1a2b3c4d";
    PROCESS BEGIN
        WAIT FOR 600ps;
        wr <= '1';
        addr <= x"0003";
        datawr <= x"37";
        WAIT FOR 1ns;
        wr <= '1';
        addr <= x"00fa";
        datawr <= x"45";
        WAIT FOR 1ns;
        wr <= '1';
        addr <= x"00fe";
        datawr <= x"5c";
        WAIT FOR 1ns;
        wr <= '1';
        addr <= x"0107";
        datawr <= x"62";
        WAIT FOR 1ns;
        wr <= '1';
        addr <= x"0214";
        datawr <= x"79";
        WAIT FOR 1ns;
        wr <= '0';
        addr <= x"0003";
        datawr <= x"83";
        WAIT FOR 1ns;
        wr <= '0';
        addr <= x"00fa";
        datawr <= x"83";
        WAIT FOR 1ns;
        wr <= '0';
        addr <= x"00fe";
        datawr <= x"83";
        WAIT FOR 1ns;
        wr <= '0';
        addr <= x"0107";
        datawr <= x"83";
        WAIT FOR 1ns;
        wr <= '0';
        addr <= x"0214";
        datawr <= x"83";
        WAIT FOR 1ns;
        WAIT FOR 1ms;
    END PROCESS;

END Behavioral;