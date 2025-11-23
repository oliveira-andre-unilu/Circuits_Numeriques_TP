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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory is
port (
clk : in std_logic;
wr : in std_logic; 
addr : in std_logic_vector(15 downto 0);
datawr : in std_logic_vector(7 downto 0);
datard : out std_logic_vector(7 downto 0);
io_in : in std_logic_vector(31 downto 0);
io_out : out std_logic_vector(31 downto 0)
);
end memory;

architecture Behavioral of memory is
type ramtype is array (0 to 8191) of std_logic_vector(7 downto 0);
signal ram : ramtype;
type page0type is array (0 to 255) of std_logic_vector(7 downto 0);
signal page0 : page0type;
signal memoryrd,page0rd : std_logic_vector(7 downto 0);
signal io_out_r : std_logic_vector(31 downto 0);
begin

pwrite: process (clk) begin
if clk'event and clk='1' then
if wr='1' then ram(to_integer(unsigned(addr)))<=datawr; end if;
end if; end process;

pread: process(clk) begin
if clk'event and clk='0' then
memoryrd<=ram(to_integer(unsigned(addr)));
end if; end process;

pwrperiph: process(clk) begin
if clk'event and clk='1' then
if wr='1' and addr(15 downto 8)=x"00" then case addr(7 downto 0) is  
    when x"fc" => io_out_r( 7 downto  0)<=datawr;
    when x"fd" => io_out_r(15 downto  8)<=datawr;
    when x"fe" => io_out_r(23 downto 16)<=datawr;
    when x"ff" => io_out_r(31 downto 24)<=datawr;
    when others=>null;
end case; end if;   
end if; end process;
io_out <= io_out_r;

page0rd<=page0(to_integer(unsigned(addr(7 downto 0))));
datard<=page0rd when addr(15 downto 8)=x"00" else memoryrd;

page0(248)<=io_in( 7 downto  0);
page0(249)<=io_in(15 downto  8);
page0(250)<=io_in(23 downto 16);
page0(251)<=io_in(31 downto 24);
page0(252)<=io_out_r( 7 downto  0);
page0(253)<=io_out_r(15 downto  8);
page0(254)<=io_out_r(23 downto 16);
page0(255)<=io_out_r(31 downto 24);

page0(0 to 247) <= (
x"01", x"02", x"03", x"04",
others => x"00"); 

end Behavioral;
