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
--signal rst : std_logic;
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

begin
cmem: memory port map(clk,wr,addr,datawr,datard,io_in,io_out);
clk <= not clk after 500ps;
--rst <= '1','0' after 400ps;
io_in<=x"1a2b3c4d";
process begin
wait for 600ps;
wr<='1'; addr<=x"0003"; datawr<=x"37"; wait for 1ns; 
wr<='1'; addr<=x"00fa"; datawr<=x"45"; wait for 1ns; 
wr<='1'; addr<=x"00fe"; datawr<=x"5c"; wait for 1ns; 
wr<='1'; addr<=x"0107"; datawr<=x"62"; wait for 1ns; 
wr<='1'; addr<=x"0214"; datawr<=x"79"; wait for 1ns; 
wr<='0'; addr<=x"0003"; datawr<=x"83"; wait for 1ns; 
wr<='0'; addr<=x"00fa"; datawr<=x"83"; wait for 1ns; 
wr<='0'; addr<=x"00fe"; datawr<=x"83"; wait for 1ns; 
wr<='0'; addr<=x"0107"; datawr<=x"83"; wait for 1ns; 
wr<='0'; addr<=x"0214"; datawr<=x"83"; wait for 1ns;
wait for 1ms;
end process;

end Behavioral;
