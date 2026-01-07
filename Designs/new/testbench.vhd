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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity testbench is
--  Port ( );
end testbench;

architecture Behavioral of testbench is
signal clk : std_logic := '0';
signal rst : std_logic;
signal wr : std_logic; 
signal addr : std_logic_vector(15 downto 0);
signal datawr : std_logic_vector(7 downto 0);
signal datard : std_logic_vector(7 downto 0);
signal io_in : std_logic_vector(31 downto 0);
signal io_out : std_logic_vector(31 downto 0);
component memory is 
port (
clk : in std_logic;
wr : in std_logic; 
addr : in std_logic_vector(15 downto 0);
datawr : in std_logic_vector(7 downto 0);
datard : out std_logic_vector(7 downto 0);
io_in : in std_logic_vector(31 downto 0);
io_out : out std_logic_vector(31 downto 0)
);
end component;
component cpu is
Port (
clk,rst : in std_logic; 
wr : out std_logic; 
addr : out std_logic_vector(15 downto 0);
datawr : out std_logic_vector(7 downto 0);
datard : in std_logic_vector(7 downto 0)
);
end component;

begin
cmem: memory port map(clk,wr,addr,datawr,datard,io_in,io_out);
ccpu: cpu port map(clk,rst,wr,addr,datawr,datard);
clk <= not clk after 500ps;
rst <= '1','0' after 400ps;
process begin
io_in<=x"00000000"; wait for 50ns;
io_in<=x"01000000"; wait for 50ns; io_in<=x"00000000"; wait for 50ns;
io_in<=x"03000000"; wait for 50ns; io_in<=x"00000000"; wait for 50ns;
io_in<=x"02000000"; wait for 50ns; io_in<=x"00000000"; wait for 50ns;
io_in<=x"02000000"; wait for 50ns; io_in<=x"00000000"; wait for 50ns;
io_in<=x"08000000"; wait for 50ns; io_in<=x"00000000"; wait for 50ns;
io_in<=x"00000043"; wait for 50ns; 
io_in<=x"01000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"08000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"05000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"08000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"01000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"08000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
io_in<=x"09000043"; wait for 50ns; io_in<=x"00000043"; wait for 50ns;
wait for 16000ns;
io_in<=x"00000002"; wait for 50ns; 
io_in<=x"00000004"; wait for 50ns; 
io_in<=x"00000009"; wait for 50ns; 
io_in<=x"00000002"; wait for 50ns; 
io_in<=x"0000000A"; wait for 50ns; 
io_in<=x"0000000B"; wait for 50ns; 

wait;
end process; 
end Behavioral;
