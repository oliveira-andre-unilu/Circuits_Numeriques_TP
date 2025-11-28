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

BEGIN

    pseq : PROCESS (clk, rst) BEGIN
        IF rst = '1' THEN
            state <= x"0"; -- Sets State to 0 (CPU initialization/reset)
        ELSIF clk'event AND clk = '1' THEN
            CASE state IS

                -- State 0: Prepare CPU to read first instruction byte
                WHEN x"0" =>
                    -- Init 
                    state <= x"1"; -- Sets next State to 1
                    pc <= x"0000"; -- Sets Program Counter to start at 0
                    addr <= x"0000"; -- Sets Memory Read Address to start at 0
                    wr <= '0'; -- Set Memory Write to 0 (Reading instead)

                -- State 1: Fetch 1st byte of instruction
                WHEN x"1" =>
                    ir(23 DOWNTO 16) <= dataRd;             -- Store the 1st instruction byte in the TOP 8 bits of IR
                                                            -- IR becomes: [ BYTE1 ][ ???? ][ ???? ]
                                                            -- The CPU needs this byte first because it contains the opcode (type of instruction).
                    pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)
                    IF dataRd(7) = '0' OR dataRd(6 DOWNTO 5) = "00" -- If instruction starts with '0' or '_ 00'. [Concerned instructions: 00 RRR SSS (MOVE); 1 00 00 RRR (LOAD ind);  1 00 01 RRR (STOR ind)]
                        THEN -- transition 1=>4
                        state <= x"4"; -- Sets next State to 4

                    ELSE -- transition 1=>2
                        state <= x"2"; -- Sets next State to 2
                        addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1; -- Increment Program Counter (so next memory access fetches the next byte)

                    END IF;

                -- State 2: Fetch 2nd byte of instruction
                WHEN x"2" =>
                    ir(15 DOWNTO 8) <= dataRd;              -- Store the 2nd instruction byte in the MIDDLE 8 bits of IR
                                                            -- IR becomes: [ BYTE1 ][ BYTE2 ][ ???? ]
                    pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)
                    IF ir(22 DOWNTO 21) = "01" OR ir(22 DOWNTO 21) = "10"   -- If instruction starts with '_ 01' or '_ 10'. [Concerned instructions:  1 01 00 RRR (LOAD seg);  1 10 00 RRR (LOAD cst);  1 01 01 RRR (STOR seg)]
                        THEN -- transition 2=>4
                        state <= x"4"; -- Sets next State to 4

                    ELSE -- transition 2=>3
                        state <= x"3"; -- Sets next State to 3
                        addr(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1; -- Increment Program Counter (so next memory access fetches the next byte)

                    END IF;

                -- State 3: Fetch 3rd byte of instruction
                WHEN x"3" =>
                    ir(7 DOWNTO 0) <= dataRd;               -- Store the 3rd instruction byte in the BOTTOM 8 bits of IR
                                                            -- IR becomes: [ BYTE1 ][ BYTE2 ][ BYTE3 ]
                    pc(7 DOWNTO 0) <= pc(7 DOWNTO 0) + 1;   -- Increment Program Counter (so next memory access fetches the next byte)
                    -- transition 3=> 4
                    state <= x"4"; -- Sets next State to 4

                -- State 4: Execute instruction and store result
                WHEN x"4" =>
                    -- transition 4=>1
                    state <= x"1";  -- Fetch new instruction
                    addr <= pc;     -- Set Memory Address to next instruction (pointed by PC)
                    wr <= '0';      -- Set Memory Write to 0

                WHEN OTHERS => NULL;
            END CASE;
        END IF;
    END PROCESS;

END Behavioral;