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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY cpu IS
  PORT (
    clk, rst : IN STD_LOGIC;
    wr : OUT STD_LOGIC;
    addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    datawr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    datard : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END cpu;

ARCHITECTURE Behavioral OF cpu IS
  SIGNAL state : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL pc : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL ir : STD_LOGIC_VECTOR(23 DOWNTO 0);
  TYPE regtype IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL reg : regtype;
  SIGNAL aluop1, aluop2, alures : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL alucode, aluflags : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

  pseq : PROCESS (clk, rst) BEGIN
    IF rst = '1' THEN
      state <= x"0";
    ELSIF clk'event AND clk = '1' THEN
      CASE state IS

        WHEN x"0" =>
          -- Init 
          state <= x"1";
          pc <= x"0000";
          addr <= x"0000";
          wr <= '0';

        WHEN x"1" =>
          ir(23 DOWNTO 16) <= dataRd;
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;
          IF dataRd(7) = '0' OR dataRd(6 DOWNTO 5) = "00"
            THEN -- transition 1=>4
            state <= x"4";
            -- 02. LOAD INDIRECT
            IF datard(7 DOWNTO 3) = "10000" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= reg(7);
              wr <= '0';
            END IF;
            -- 06. STORE INDIRECT
            IF datard(7 DOWNTO 3) = "10001" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= reg(7);
              wr <= '1';
              datawr <= reg(to_integer(unsigned(datard(2 DOWNTO 0))));
            END IF;
            -- 10. ALU REG
            IF datard(7 DOWNTO 6) = "01" AND datard(5 DOWNTO 3) /= "111" THEN
              aluop1 <= reg(0);
              aluop2 <= reg(to_integer(unsigned(datard(2 DOWNTO 0))));
              alucode <= '0' & datard(5 DOWNTO 3);
            END IF;
            -- 11. ALU ONE
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            if datard(7 downto 3)="01111" then
              aluop1 <= reg(0); 
              alucode <= '1' & datard(2 downto 0); -- '1' prefix denotes 1-operand [9]
            end if;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --

          ELSE -- transition 1=>2
            state <= x"2";
            addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;

          END IF;

        WHEN x"2" =>
          ir(15 DOWNTO 8) <= dataRd;
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;
          IF ir(22 DOWNTO 21) = "01" OR ir(22 DOWNTO 21) = "10"
            THEN -- transition 2=>4
            state <= x"4";
            -- 03. LOAD MIXED
            IF ir(23 DOWNTO 19) = "10100" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= datard;
              wr <= '0';
            END IF;
            -- 07. STORE MIXED
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            if ir(23 downto 19)="10101" then
              addr(15 downto 8) <= reg(6); 
              addr(7 downto 0) <= datard; -- LSB comes from memory bus [10]
              wr <= '1'; 
              datawr <= reg(to_integer(unsigned(ir(18 downto 16)))); -- Data from source register [10]
            end if;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            -- 09. ALU CONSTANT
            IF ir(23 DOWNTO 19) = "11001" THEN
              aluop1 <= reg(0);
              aluop2 <= datard;
              alucode <= '0' & ir(18 DOWNTO 16);
            END IF;

          ELSE -- transition 2=>3
            state <= x"3";
            addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;

          END IF;

        WHEN x"3" =>
          ir(7 DOWNTO 0) <= dataRd;
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;
          -- transition 3=> 4
          state <= x"4";
          -- 04. LOAD DIRECT
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          if ir(23 downto 19)="11100" then
            addr(15 downto 8) <= ir(15 downto 8); -- MSB from 2nd byte of IR [12]
            addr(7 downto 0) <= datard;          -- LSB currently being read [12]
            wr <= '0';
          end if;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --

          -- 08. STORE DIRECT
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          if ir(23 downto 19)="11101" then
            addr(15 downto 8) <= ir(15 downto 8); 
            addr(7 downto 0) <= datard; 
            wr <= '1';
            datawr <= reg(to_integer(unsigned(ir(18 downto 16)))); -- Data from source register [13]
          end if;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --

        WHEN x"4" =>
          -- transition 4=>1
          state <= x"1";
          addr <= pc;
          wr <= '0';
          -- 01. MOVE
          IF ir(23 DOWNTO 22) = "00" AND ir(21 DOWNTO 19) /= ir(18 DOWNTO 16) THEN
            reg(to_integer(unsigned(ir(18 DOWNTO 16)))) <= reg(to_integer(unsigned(ir(21 DOWNTO 19))));
          END IF;
          -- 02,03,04. LOAD INDIRECT, MIXED OR DIRECT
          IF ir(23 DOWNTO 19) = "10000" OR ir(23 DOWNTO 19) = "10100" OR ir(23 DOWNTO 19) = "11100" THEN
            reg(to_integer(unsigned(ir(18 DOWNTO 16)))) <= datard;
          END IF;
          -- 05. LOAD CONSTANT
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          if ir(23 downto 19)="11000" then
            reg(to_integer(unsigned(ir(18 downto 16)))) <= ir(15 downto 8); -- Constant is 2nd byte of instruction [14]
          end if;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          -- 12 to 15 JUMP INSTRUCTIONS
          IF ir(23) = '1' AND ir(20 DOWNTO 19) = "11" AND
            (ir(18 DOWNTO 16) = "000" OR reg(1)(to_integer(unsigned(ir(17 DOWNTO 16)))) = ir(18)) THEN
            -- JUMP SECRET
            IF ir(22 DOWNTO 21) = "00" THEN
              pc(15 DOWNTO 8) <= reg(6);
              pc(7 DOWNTO 0) <= reg(7);
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= reg(7);
            END IF;
            -- JUMP SHORT ABSOL
            IF ir(22 DOWNTO 21) = "01" THEN
              pc(7 DOWNTO 0) <= ir(15 DOWNTO 8);
              addr(7 DOWNTO 0) <= ir(15 DOWNTO 8);
            END IF;
            -- JUMP SHORT REL
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            if ir(22 downto 21)="10" then 
              pc(7 downto 0) <= pc(7 downto 0) + ir(15 downto 8); 
              addr(7 downto 0) <= pc(7 downto 0) + ir(15 downto 8); 
            end if;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            -- JUMP LONG ABS
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            if ir(22 downto 21)="11" then 
              pc(15 downto 8) <= ir(15 downto 8); 
              pc(7 downto 0) <= ir(7 downto 0); 
              addr(15 downto 8) <= ir(15 downto 8); 
              addr(7 downto 0) <= ir(7 downto 0); 
            end if;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
          END IF;
          -- 9 to 11 ALU INSTRUCTIONS
          IF ir(23 DOWNTO 22) = "01" OR ir(23 DOWNTO 19) = "11001" THEN
            IF alucode /= "0010" THEN
              reg(0) <= alures;
            END IF;
            reg(1)(3 DOWNTO 0) <= aluflags;
          END IF;

        WHEN OTHERS => NULL;
      END CASE;
    END IF;
  END PROCESS;

  palu : PROCESS (aluop1, aluop2, alucode)
    VARIABLE vop1, vop2, vres : STD_LOGIC_VECTOR(9 DOWNTO 0);
  BEGIN
    vop1 := '0' & aluop1(7) & aluop1;
    vop2 := '0' & aluop2(7) & aluop2;
    vres := vop1;
    CASE alucode IS
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "0000" => vres := vop1 + vop2; -- ADD [18]
      WHEN "0001" => vres := vop1 - vop2; -- SUB [18]
      WHEN "0010" => vres := vop1 - vop2; -- CMP (same as sub, result not saved in pseq) [18]
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "0100" => vres := vop1 AND vop2;
      WHEN "0101" => vres := vop1 OR vop2;
      WHEN "0110" => vres := vop1 XOR vop2;
      WHEN "0111" => vres := vop1; -- impossible
      WHEN "1000" => vres := 0 - vop1;
      WHEN "1001" => vres := NOT vop1;
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "1010" => vres := vop1 + 1;    -- INC [18]
      WHEN "1011" => vres := vop1 - 1;    -- DEC [18]
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "1100" => vres(7 DOWNTO 1) := vop1(6 DOWNTO 0);
        vres(0) := vop1(7);
      WHEN "1101" => vres(6 DOWNTO 0) := vop1(7 DOWNTO 1);
        vres(7) := vop1(0);
      WHEN "1110" => vres(7 DOWNTO 1) := vop1(6 DOWNTO 0);
        vres(0) := '0';
      WHEN "1111" => vres(6 DOWNTO 0) := vop1(7 DOWNTO 1);
        vres(7) := '0';
      WHEN OTHERS => vres := vop1;
    END CASE;
    alures <= vres(7 DOWNTO 0);
    aluflags(0) <= vres(9);
    IF vres(7 DOWNTO 0) = x"00" THEN
      aluflags(1) <= '1';
    ELSE
      aluflags(1) <= '0';
    END IF;
    -- IMPLEMENTED CODE BY ANDRE AND LEO --
    -- Negative flag (SIGN): bit 7 of the result [19, 20]
    aluflags(2) <= vres(7);

    -- Signed Carry flag: XOR between bit 8 and 7 of the extended result [19, 20]
    aluflags(3) <= vres(8) xor vres(7);
    -- IMPLEMENTED CODE BY ANDRE AND LEO --
  END PROCESS;
END Behavioral;