-- TODO: Do undone instructions
-- TODO: Have good understandable comments
-- TODO: Format


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.11.2025 15:59:59
-- Design Name: 
-- Module Name: cpu - Behavioral
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
use IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu is
Port (
clk,rst : in std_logic; 
wr : out std_logic; 
addr : out std_logic_vector(15 downto 0);
datawr : out std_logic_vector(7 downto 0);
datard : in std_logic_vector(7 downto 0)
);
end cpu;

architecture Behavioral of cpu is
signal state : std_logic_vector(3 downto 0);
signal pc : std_logic_vector(15 downto 0);
signal ir : std_logic_vector(23 downto 0);
type regtype is array(0 to 7) of std_logic_vector(7 downto 0);   
signal reg : regtype;
signal aluop1,aluop2,alures : std_logic_vector(7 downto 0);
signal alucode,aluflags : std_logic_vector(3 downto 0);

begin

pseq:process(clk,rst) begin
if rst='1' then state<=x"0"; 
elsif clk'event and clk='1' then
case state is  

when x"0"=> 
-- Init 
  state<=x"1"; pc<=x"0000"; 
  addr<=x"0000"; wr<='0';

when x"1"=>
  ir(23 downto 16)<=dataRd;
  pc(7 downto 0)<=pc(7 downto 0)+1;
if dataRd(7)='0' or dataRd(6 downto 5)="00" 
then -- transition 1=>4
  state<=x"4"; 
  -- 02. LOAD INDIRECT
  if datard(7 downto 3)="10000" then
   addr(15 downto 8) <= reg(6); addr(7 downto 0) <= reg(7); wr <='0';
  end if;
  -- 06. STORE INDIRECT
  if datard(7 downto 3)="10001" then
   addr(15 downto 8) <= reg(6); addr(7 downto 0) <= reg(7); wr <='1'; 
   datawr <= reg(to_integer(unsigned(datard(2 downto 0))));
  end if;
  -- 10. ALU REG
  if datard(7 downto 6)="01" and datard(5 downto 3)/="111" then
   aluop1<=reg(0); aluop2<=reg(to_integer(unsigned(datard(2 downto 0)))); alucode<='0'&datard(5 downto 3); 
  end if;
  -- 11. ALU ONE
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  
else -- transition 1=>2
  state<=x"2"; 
  addr(7 downto 0)<=pc(7 downto 0)+1;
  
end if;

when x"2" =>
  ir(15 downto 8)<=dataRd;
  pc(7 downto 0)<=pc(7 downto 0)+1;
if ir(22 downto 21)="01" or ir(22 downto 21)="10"
then -- transition 2=>4
  state<=x"4"; 
  -- 03. LOAD MIXED
  if ir(23 downto 19)="10100" then
    addr(15 downto 8) <= reg(6); addr(7 downto 0) <= datard; wr <='0';
  end if;
  -- 07. STORE MIXED
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  -- 09. ALU CONSTANT
  if ir(23 downto 19)="11001" then
    aluop1<=reg(0); aluop2<=datard; alucode<='0'&ir(18 downto 16);
  end if;
  
else -- transition 2=>3
  state<=x"3"; 
  addr(7 downto 0)<=pc(7 downto 0)+1;
  
end if;

when x"3" =>
  ir(7 downto 0)<=dataRd;
  pc(7 downto 0)<=pc(7 downto 0)+1;
-- transition 3=> 4
  state<=x"4"; 
  -- 04. LOAD DIRECT
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  -- 08. STORE DIRECT
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  
when x"4" =>
-- transition 4=>1
  state<=x"1";
  addr<=pc;
  wr<='0';
  -- 01. MOVE
  if ir(23 downto 22)="00" and ir(21 downto 19)/=ir(18 downto 16) then
    reg(to_integer(unsigned(ir(18 downto 16)))) <= reg(to_integer(unsigned(ir(21 downto 19))));
  end if;
  -- 02,03,04. LOAD INDIRECT, MIXED OR DIRECT
  if ir(23 downto 19)="10000" or ir(23 downto 19)="10100" or ir(23 downto 19)="11100" then
    reg(to_integer(unsigned(ir(18 downto 16)))) <= datard;
  end if;
  -- 05. LOAD CONSTANT
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  -- 12 to 15 JUMP INSTRUCTIONS
  if ir(23)='1' and ir(20 downto 19)="11" and 
    (ir(18 downto 16)="000" or reg(1)(to_integer(unsigned(ir(17 downto 16))))=ir(18)) then
    -- JUMP SECRET
    if ir(22 downto 21)="00" then pc(15 downto 8)<=reg(6); pc(7 downto 0)<=reg(7);
      addr(15 downto 8)<=reg(6); addr(7 downto 0)<=reg(7); end if;
    -- JUMP SHORT ABSOL
    if ir(22 downto 21)="01" then pc(7 downto 0)<=ir(15 downto 8);
      addr(7 downto 0)<=ir(15 downto 8); end if;
    -- JUMP SHORT REL
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
    -- JUMP LONG ABS
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  end if;   
  -- 9 to 11 ALU INSTRUCTIONS
  if ir(23 downto 22)="01" or ir(23 downto 19)="11001" then
    if alucode/="0010" then reg(0)<=alures; end if;
    reg(1)(3 downto 0)<=aluflags;
  end if; 
 
when others=>null;
end case; end if; end process;

palu:process (aluop1, aluop2, alucode) 
variable vop1, vop2, vres : std_logic_vector(9 downto 0);
begin
vop1:='0'&aluop1(7)&aluop1; vop2:='0'&aluop2(7)&aluop2;
vres:=vop1;
case alucode is
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
when "0100" => vres:=vop1 and vop2;
when "0101" => vres:=vop1 or vop2;
when "0110" => vres:=vop1 xor vop2;
when "0111" => vres:=vop1; -- impossible
when "1000" => vres:=0-vop1;
when "1001" => vres:=not vop1;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
when "1100" => vres(7 downto 1):=vop1(6 downto 0); vres(0):=vop1(7);
when "1101" => vres(6 downto 0):=vop1(7 downto 1); vres(7):=vop1(0);
when "1110" => vres(7 downto 1):=vop1(6 downto 0); vres(0):='0';
when "1111" => vres(6 downto 0):=vop1(7 downto 1); vres(7):='0';
when others => vres:=vop1;
end case;
alures <= vres(7 downto 0);
aluflags(0) <= vres(9);
if vres(7 downto 0) = x"00" then aluflags(1)<='1'; else aluflags(1)<='0'; end if;
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
end process;


end Behavioral;
