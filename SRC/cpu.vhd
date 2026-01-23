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

----------------------------------------------------------------------------------
-- OVERVIEW
----------------------------------------------------------------------------------
-- Simple Microprocessor CPU
-- Implements a Von Neumann architecture with:
--  - Instruction Fetch (States 0–3)
--  - Execute / Writeback (State 4)
--  - Register file
--  - ALU
--  - Jump logic
----------------------------------------------------------------------------------

------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------
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

------------------------------------------------------------------
-- CPU Entity (External Interface)
------------------------------------------------------------------
ENTITY cpu IS
  PORT (
    clk, rst  : IN STD_LOGIC;                       -- System clock and reset
    wr        : OUT STD_LOGIC;                      -- Memory write enable
    addr      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);  -- Memory address bus
    datawr    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);   -- Data written to memory
    datard    : IN STD_LOGIC_VECTOR(7 DOWNTO 0)     -- Data read from memory
  );
END cpu;

ARCHITECTURE Behavioral OF cpu IS

  ------------------------------------------------------------------
  -- Control and Core Registers
  ------------------------------------------------------------------
  SIGNAL state  : STD_LOGIC_VECTOR(3 DOWNTO 0);   -- Sequencer state (0-4)
  SIGNAL pc     : STD_LOGIC_VECTOR(15 DOWNTO 0);  -- Program Counter
  SIGNAL ir     : STD_LOGIC_VECTOR(23 DOWNTO 0);  -- Instruction Register (3 bytes)

  ------------------------------------------------------------------
  -- Register file: 8 general-purpose 8-bit registers
  -- reg(0)         = accumulator
  -- reg(1)         = flags register (C, Z, S, V)
  -- reg(6), reg(7) = address registers (MSB / LSB)
  ------------------------------------------------------------------
  TYPE regtype IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL reg : regtype;

  ------------------------------------------------------------------
  -- ALU Interface Signals
  ------------------------------------------------------------------
  SIGNAL aluop1, aluop2 : STD_LOGIC_VECTOR(7 DOWNTO 0); -- ALU Operands
  SIGNAL alures         : STD_LOGIC_VECTOR(7 DOWNTO 0); -- ALU Result
  SIGNAL alucode        : STD_LOGIC_VECTOR(3 DOWNTO 0); -- ALU Operations Selector
  SIGNAL aluflags       : STD_LOGIC_VECTOR(3 DOWNTO 0); -- ALU flags (C, Z, S, V)

BEGIN

  ------------------------------------------------------------------
  -- CPU Sequencer: fetch, decode, execute
  -- - Sequential CPU
  -- - Triggered by clock and reset
  -- - Finite state machine (5 States including Initializer State)
  --    > [STATE 0]: Initialize
  --    > [STATE 1]: Fetch byte 1 of instruction
  --    > [STATE 2]: Fetch byte 2 of instruction
  --    > [STATE 3]: Fetch byte 3 of instruction
  --    > [STATE 4]: Execute
  ------------------------------------------------------------------
  pseq : PROCESS (clk, rst) BEGIN
    IF rst = '1' THEN
      state <= x"0"; -- Reset CPU to initial state (State 0)

    ELSIF clk'event AND clk = '1' THEN
      CASE state IS

        ----------------------------------------------------------------
        -- STATE 0: Initialization (Prepare CPU to read first instruction byte)
        -- - Resets program counter
        -- - Prepares memory read
        -- - Moves to instruction fetch
        ----------------------------------------------------------------
        WHEN x"0" =>
          state <= x"1";    -- Sets next State to 1 (State 1 = Fetch State)
          pc    <= x"0000"; -- Sets Program Counter to start at 0
          addr  <= x"0000"; -- Sets Memory Read Address to start at 0
          wr    <= '0';     -- Set Read mode (Memory Write to 0)

        ----------------------------------------------------------------
        -- STATE 1: Fetch first instruction byte (opcode)
        -- - Reads opcode byte
        -- - Stores it at top of IR
        -- - Increments program counter
        ----------------------------------------------------------------
        WHEN x"1" =>
          ir(23 DOWNTO 16) <= dataRd;             -- Store the 1st instruction byte in the TOP 8 bits of IR
                                                  -- IR becomes: [ BYTE1 ][ ???? ][ ???? ]
                                                  -- The CPU needs this byte first because it contains the opcode (type of instruction).
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)

          -- If instruction starts with '0' or '_ 00'.
          -- | Concerned instructions:
          -- |    1 ->  00 RRR SSS (MOVE);
          -- |    2 ->  1 00 00 RRR (LOAD ind);
          -- |    6 ->  1 00 01 RRR (STOR ind);
          -- |    10 -> 01 AAA RRR (ALU 2op (R0, R));
          -- |    11 -> 01 111 BBB (ALU 1op (R0));
          -- These instructions only require 1 byte.
          IF dataRd(7) = '0' OR dataRd(6 DOWNTO 5) = "00" THEN
            state <= x"4"; -- Sets next State to 4 (Execute Instruction)

            -- LOAD indirect (Instruction 1)
            IF datard(7 DOWNTO 3) = "10000" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= reg(7);
              wr <= '0';
            END IF;

            -- STORE indirect (Instruction 6)
            IF datard(7 DOWNTO 3) = "10001" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= reg(7);
              wr <= '1';
              datawr <= reg(to_integer(unsigned(datard(2 DOWNTO 0))));
            END IF;

            -- ALU register (Instruction 10)
            IF datard(7 DOWNTO 6) = "01" AND datard(5 DOWNTO 3) /= "111" THEN
              aluop1 <= reg(0);
              aluop2 <= reg(to_integer(unsigned(datard(2 DOWNTO 0))));
              alucode <= '0' & datard(5 DOWNTO 3);
            END IF;

            -- ALU one-operand (INC, DEC, NOT, NEG) (Instruction 11)
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            IF datard(7 DOWNTO 3)="01111" THEN
              aluop1 <= reg(0); 
              alucode <= '1' & datard(2 DOWNTO 0);
            END IF;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --

          ELSE 
            -- Instruction needs more bytes
            state <= x"2"; -- Sets next State to 2
            addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1; -- Increment Program Counter (so next memory access fetches the next byte)

          END IF;

        ----------------------------------------------------------------
        -- STATE 2: Fetch second instruction byte
        -- - Reads second byte of instruction
        -- - Stores it at the middle of IR
        -- - Increments program counter
        ----------------------------------------------------------------
        WHEN x"2" =>
          ir(15 DOWNTO 8) <= dataRd;              -- Store the 2nd instruction byte in the MIDDLE 8 bits of IR
                                                  -- IR becomes: [ BYTE1 ][ BYTE2 ][ ???? ]
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)

          -- If instruction starts with '_ 01' or '_ 10'. 
          -- | Concerned instructions:
          -- |    3 -> 1 01 00 RRR (LOAD seg);
          -- |    5 -> 1 10 00 RRR (LOAD cst); Passes Through (Execution in STATE 4)
          -- |    7 -> 1 01 01 RRR (STOR seg);
          -- |    9 -> 1 10 01 AAA (ALU 2op(R0, DD));
          -- These instructions require 2 bytes.
          IF ir(22 DOWNTO 21) = "01" OR ir(22 DOWNTO 21) = "10" THEN
            state <= x"4"; -- Sets next State to 4

            -- LOAD segmented (LOAD MIXED) (Instruction 3)
            IF ir(23 DOWNTO 19) = "10100" THEN
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0) <= datard;
              wr <= '0';
            END IF;

            -- STORE segmented (STORE MIXED) (Instruction 7)
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            IF ir(23 DOWNTO 19)="10101" THEN
              addr(15 DOWNTO 8) <= reg(6); 
              addr(7 DOWNTO 0) <= datard;
              wr <= '1'; 
              datawr <= reg(to_integer(unsigned(ir(18 DOWNTO 16))));
            END IF;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --

            -- ALU constant (Instruction 9)
            IF ir(23 DOWNTO 19) = "11001" THEN
              aluop1 <= reg(0);
              aluop2 <= datard;
              alucode <= '0' & ir(18 DOWNTO 16);
            END IF;

          ELSE
            -- Instruction needs third byte
            state <= x"3"; -- Sets next State to 3
            addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1; -- Increment Program Counter (so next memory access fetches the next byte)

          END IF;

        ----------------------------------------------------------------
        -- STATE 3: Fetch third instruction byte
        -- - Reads third byte of instruction
        -- - Stores it at the end of IR
        -- - Increments program counter
        ----------------------------------------------------------------
        WHEN x"3" =>
          ir(7 DOWNTO 0) <= dataRd;               -- Store the 3rd instruction byte in the BOTTOM 8 bits of IR
                                                  -- IR becomes: [ BYTE1 ][ BYTE2 ][ BYTE3 ]
          pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)
          state <= x"4";  -- Sets next State to 4

          -- | Concerned instructions:
          -- |    4 -> 1 11 00 RRR (LOAD dir);
          -- |    8 -> 1 11 01 RRR (STOR dir);
          -- These instructions require all 3 bytes.

          -- LOAD direct (Instruction 4)
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          IF ir(23 DOWNTO 19)="11100" THEN
            addr(15 DOWNTO 8) <= ir(15 DOWNTO 8);
            addr(7 DOWNTO 0) <= datard;
            wr <= '0';
          END IF;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --

          -- STORE direct (Instruction 8)
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          IF ir(23 DOWNTO 19)="11101" THEN
            addr(15 DOWNTO 8) <= ir(15 DOWNTO 8); 
            addr(7 DOWNTO 0) <= datard; 
            wr <= '1';
            datawr <= reg(to_integer(unsigned(ir(18 DOWNTO 16))));
          END IF;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --

        ----------------------------------------------------------------
        -- STATE 4: Execute instruction / write-back (store result)
        -- - Executes based on previous instructions
        -- - Stores results
        ----------------------------------------------------------------
        WHEN x"4" =>
          -- transition 4=>1
          state <= x"1";  -- Fetch new instruction
          addr  <= pc;    -- Set Memory Address to next instruction (pointed by PC)
          wr    <= '0';   -- Set Memory Write to 0

          -- MOVE (Instruction 1)
          IF ir(23 DOWNTO 22) = "00" AND
             ir(21 DOWNTO 19) /= ir(18 DOWNTO 16) THEN
            reg(to_integer(unsigned(ir(18 DOWNTO 16)))) <= reg(to_integer(unsigned(ir(21 DOWNTO 19))));
          END IF;

          -- LOAD instructions (LOAD INDIRECT, MIXED OR DIRECT) (Instruction 2, 3, 4)
          IF ir(23 DOWNTO 19) = "10000" OR
             ir(23 DOWNTO 19) = "10100" OR
             ir(23 DOWNTO 19) = "11100" THEN
            reg(to_integer(unsigned(ir(18 DOWNTO 16)))) <= datard;
          END IF;

          -- LOAD constant (Instruction 5)
          -- IMPLEMENTED CODE BY ANDRE AND LEO --
          IF ir(23 DOWNTO 19)="11000" THEN
            reg(to_integer(unsigned(ir(18 DOWNTO 16)))) <= ir(15 DOWNTO 8);
          END IF;
          -- IMPLEMENTED CODE BY ANDRE AND LEO --

          -- JUMP (Instructions 12 to 15)
          IF ir(23) = '1' AND
             ir(20 DOWNTO 19) = "11" AND
             (ir(18 DOWNTO 16) = "000" OR reg(1)(to_integer(unsigned(ir(17 DOWNTO 16)))) = ir(18)) THEN

            -- JUMP SECRET (Instruction 12)
            IF ir(22 DOWNTO 21) = "00" THEN
              pc(15 DOWNTO 8)   <= reg(6);
              pc(7 DOWNTO 0)    <= reg(7);
              addr(15 DOWNTO 8) <= reg(6);
              addr(7 DOWNTO 0)  <= reg(7);
            END IF;

            -- JUMP SHORT ABSOL (Instruction 13)
            IF ir(22 DOWNTO 21) = "01" THEN
              pc(7 DOWNTO 0)    <= ir(15 DOWNTO 8);
              addr(7 DOWNTO 0)  <= ir(15 DOWNTO 8);
            END IF;

            -- JUMP SHORT REL (Instruction 14)
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            IF ir(22 DOWNTO 21)="10" THEN 
              pc(7 DOWNTO 0)    <= pc(7 DOWNTO 0) + ir(15 DOWNTO 8); 
              addr(7 DOWNTO 0)  <= pc(7 DOWNTO 0) + ir(15 DOWNTO 8); 
            END IF;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --

            -- JUMP LONG ABS (Instruction 15)
            -- IMPLEMENTED CODE BY ANDRE AND LEO --
            IF ir(22 DOWNTO 21)="11" THEN 
              pc(15 DOWNTO 8)   <= ir(15 DOWNTO 8); 
              pc(7 DOWNTO 0)    <= ir(7 DOWNTO 0); 
              addr(15 DOWNTO 8) <= ir(15 DOWNTO 8); 
              addr(7 DOWNTO 0)  <= ir(7 DOWNTO 0); 
            END IF;
            -- IMPLEMENTED CODE BY ANDRE AND LEO --

          END IF;
          -- ALU (Instruction 9 to 11)
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

  ------------------------------------------------------------------
  -- ALU: combinational arithmetic / logic unit
  -- - Runs instantly on input change
  -- - Does not rely on clock
  ------------------------------------------------------------------
  palu : PROCESS (aluop1, aluop2, alucode)
    VARIABLE vop1, vop2, vres : STD_LOGIC_VECTOR(9 DOWNTO 0);
  BEGIN

    vop1 := '0' & aluop1(7) & aluop1; -- 10-bit value [Bit 9: unsigned carry placeholder] + [Bit 8: Signed bit (copy of bit 7)] + [Bit 7-0: data]
    vop2 := '0' & aluop2(7) & aluop2; -- Same as above
    vres := vop1;                     -- No matching ALU operation (avoid undefined values)

    CASE alucode IS
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "0000" => vres := vop1 + vop2;   -- ADD
      WHEN "0001" => vres := vop1 - vop2;   -- SUB
      WHEN "0010" => vres := vop1 - vop2;   -- CMP (Subtraction in ALU for flags, numeric result not stored in register)
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "0100" => vres := vop1 AND vop2; -- AND
      WHEN "0101" => vres := vop1 OR vop2;  -- OR
      WHEN "0110" => vres := vop1 XOR vop2; -- XOR
      WHEN "0111" => vres := vop1;          -- Impossible!
      WHEN "1000" => vres := 0 - vop1;      -- NEG
      WHEN "1001" => vres := NOT vop1;      -- NOT
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "1010" => vres := vop1 + 1;      -- INC
      WHEN "1011" => vres := vop1 - 1;      -- DEC
      -- IMPLEMENTED CODE BY ANDRE AND LEO --
      WHEN "1100" => vres(7 DOWNTO 1) := vop1(6 DOWNTO 0);  -- Shift Bits Left (Bit 7 wraps around)
        vres(0) := vop1(7);
      WHEN "1101" => vres(6 DOWNTO 0) := vop1(7 DOWNTO 1);  -- Shift Bits Right (Bit 0 wraps around)
        vres(7) := vop1(0);
      WHEN "1110" => vres(7 DOWNTO 1) := vop1(6 DOWNTO 0);  -- Logical Shift Left (Bit 7 is discarded)
        vres(0) := '0';
      WHEN "1111" => vres(6 DOWNTO 0) := vop1(7 DOWNTO 1);  -- Logical Shift Right (Bit 0 is discarded)
        vres(7) := '0';
      WHEN OTHERS => vres := vop1;
    END CASE;

    alures <= vres(7 DOWNTO 0);         -- ALU result
    aluflags(0) <= vres(9);             -- Carry

    IF vres(7 DOWNTO 0) = x"00" THEN    -- Zero
      aluflags(1) <= '1';
    ELSE
      aluflags(1) <= '0';
    END IF;

    -- IMPLEMENTED CODE BY ANDRE AND LEO --
    aluflags(2) <= vres(7);             -- Sign
    aluflags(3) <= vres(8) XOR vres(7); -- Overflow
    -- IMPLEMENTED CODE BY ANDRE AND LEO --
  END PROCESS;
END Behavioral;