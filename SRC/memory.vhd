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


----------------------------------------------------------------------------------
-- Memory module for a simple microprocessor system
--
-- This module provides:
--  - 8 KB RAM
--  - Page 0 (256 bytes) containing:
--      * BIOS / program ROM
--      * Memory-mapped I/O registers
--  - Interface to external I/O (buttons, switches, displays, LEDs)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory is
port (
    clk     : in  std_logic;                     -- system clock
    wr      : in  std_logic;                     -- write enable from CPU
    addr    : in  std_logic_vector(15 downto 0); -- 16-bit address bus
    datawr  : in  std_logic_vector(7 downto 0);  -- data written by CPU
    datard  : out std_logic_vector(7 downto 0);  -- data read by CPU
    io_in   : in  std_logic_vector(31 downto 0); -- external inputs
    io_out  : out std_logic_vector(31 downto 0)  -- external outputs
);
end memory;

architecture Behavioral of memory is

    --------------------------------------------------------------------------
    -- Main RAM: 8 KB (8192 bytes)
    --------------------------------------------------------------------------
    type ramtype is array (0 to 8191) of std_logic_vector(7 downto 0);
    signal ram : ramtype;

    --------------------------------------------------------------------------
    -- Page 0 memory (address 0x0000–0x00FF)
    -- Used for:
    --   * BIOS / program code
    --   * Memory-mapped I/O registers
    --------------------------------------------------------------------------
    type page0type is array (0 to 255) of std_logic_vector(7 downto 0);
    signal page0 : page0type;

    --------------------------------------------------------------------------
    -- Internal read data paths
    --------------------------------------------------------------------------
    signal memoryrd : std_logic_vector(7 downto 0); -- data read from RAM
    signal page0rd  : std_logic_vector(7 downto 0); -- data read from page 0

    --------------------------------------------------------------------------
    -- Internal register holding output I/O state
    --------------------------------------------------------------------------
    signal io_out_r : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------------------------------
    -- WRITE PROCESS (Main RAM)
    -- Writes occur on the rising edge of the clock
    -- Only active when wr = '1'
    --------------------------------------------------------------------------
    pwrite : process (clk)
    begin
        if rising_edge(clk) then
            if wr = '1' then
                -- Convert address to integer index
                ram(to_integer(unsigned(addr))) <= datawr;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- READ PROCESS (Main RAM)
    -- Reads occur on the falling edge of the clock
    -- This separates read/write phases (simple CPU timing)
    --------------------------------------------------------------------------
    pread : process(clk)
    begin
        if falling_edge(clk) then
            memoryrd <= ram(to_integer(unsigned(addr)));
        end if;
    end process;

    --------------------------------------------------------------------------
    -- WRITE PROCESS (Memory-mapped peripherals)
    -- Only active when:
    --   * wr = '1'
    --   * address is in page 0 (addr[15:8] = 0x00)
    --
    -- Specific addresses map to bytes of io_out
    --------------------------------------------------------------------------
    pwrperiph : process(clk)
    begin
        if rising_edge(clk) then
            if wr = '1' and addr(15 downto 8) = x"00" then
                case addr(7 downto 0) is
                    when x"FC" => io_out_r( 7 downto  0) <= datawr;
                    when x"FD" => io_out_r(15 downto  8) <= datawr;
                    when x"FE" => io_out_r(23 downto 16) <= datawr;
                    when x"FF" => io_out_r(31 downto 24) <= datawr;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Drive output port
    io_out <= io_out_r;

    --------------------------------------------------------------------------
    -- PAGE 0 READ (combinational)
    -- Only lower 8 bits of address are used
    --------------------------------------------------------------------------
    page0rd <= page0(to_integer(unsigned(addr(7 downto 0))));

    --------------------------------------------------------------------------
    -- CPU READ DATA MUX (aka switch)
    -- If address is in page 0 → read page0
    -- Else → read main RAM
    --------------------------------------------------------------------------
    datard <= page0rd when addr(15 downto 8) = x"00"
              else memoryrd;

    --------------------------------------------------------------------------
    -- MEMORY-MAPPED INPUT REGISTERS
    -- CPU reads external inputs as memory locations
    --------------------------------------------------------------------------
    page0(248) <= io_in( 7 downto  0);
    page0(249) <= io_in(15 downto  8);
    page0(250) <= io_in(23 downto 16);
    page0(251) <= io_in(31 downto 24);

    --------------------------------------------------------------------------
    -- MEMORY-MAPPED OUTPUT REGISTERS (read-back)
    --------------------------------------------------------------------------
    page0(252) <= io_out_r( 7 downto  0);
    page0(253) <= io_out_r(15 downto  8);
    page0(254) <= io_out_r(23 downto 16);
    page0(255) <= io_out_r(31 downto 24);

    --------------------------------------------------------------------------
    -- PAGE 0 INITIAL CONTENT (BIOS / PROGRAM ROM)
    -- This is the program executed by the CPU after reset
    --
    -- Each byte is an instruction or operand.
    -- Comments describe the *assembly-level meaning*.
    --------------------------------------------------------------------------

    page0 (0 to 247) <= (
    x"B8", x"75",		-- 00: jumpabs 75 10111.000 
    x"B8", x"97",		-- 02: jumpabs 97 auxil program
    x"00", 			-- 04: NOP
    -- display addr
    x"EE", x"00", x"FF", 	-- 05: st r6,[00FF] 11101110
    x"EF", x"00", x"FE", 	-- 08: st r7,[00FE] 
    -- loop wait for keypressed
    x"E0", x"00", x"FB", 	-- 0b: ld r0,[00FB] 1110.000
    x"CA", x"04", 		-- 0e: cmp 04  11001.010
    x"BD", x"27", 		-- 10: jmp z 27 10111.101  dec lsb subroutine
    x"CA", x"05", 		-- 12: cmp 05
    x"BD", x"2C", 		-- 14: jmp z dec msb subroutine
    x"CA", x"02", 		-- 16: cmp 02
    x"BD", x"31", 		-- 18: jmp z inc lsb subr
    x"CA", x"03", 		-- 1a: cmp 03
    x"BD", x"36", 		-- 1c: jmp z inc msb subr
    x"CA", x"08", 		-- 1e: cmp 08
    x"BD", x"42", 		-- 20: jmp z record subr
    x"CA", x"09", 		-- 22: cmp 09
    x"9D", 			-- 24: jmp z to addr in r6 r7 10011.101
    x"B8", x"0B", 		-- 25: jmp abs loop wait for keypressed 10111.000
    -- dec lsb
    x"38", 			-- 27: mov r7,r0 00.111.000
    x"7B", 			-- 28: dec 01.111.011
    x"07", 			-- 29: mov r0,r7 00.000.111
    x"B8", x"39", 		-- 2a: jump abs loop wait for keyrelease
    -- dec msb
    x"30", 			-- 2c: mov r6,r0 00.110.000
    x"7B", 			-- 2d: dec
    x"06", 			-- 2e: mov r0,r6
    x"B8", x"39", 		-- 2f: jump abs loop wait for keyrelease
    -- inc lsb
    x"38", 			-- 31: mov r7,r0 00.111.000
    x"7A", 			-- 32: inc 01.111.010  
    x"07", 			-- 33: mov r0,r7 00.000.111
    x"B8", x"39", 		-- 34: jump abs loop wait for keyrelease
    -- dec msb
    x"30", 			-- 36: mov r6,r0 00.110.000
    x"7A", 			-- 37: inc
    x"06", 			-- 38: mov r0,r6
    -- loop wait for keyrelease
    x"E0", x"00", x"FB", 	-- 39: ld r0,[00FB] 11100.000
    x"CA", x"00", 		-- 3c: cmp 00 11001.010 
    x"BD", x"05", 		-- 3e: jmp z start displ addr
    x"B8", x"39", 		-- 40: jmp abs wait release
    -- record routine -- wait for keyrelease 
    x"E0", x"00", x"FB", 	-- 42: ld r0,[00FB] 11100.000
    x"CA", x"00", 		-- 45: cmp 00 11001.010 
    x"B9", x"42", 		-- 47: jmp nz 10111.001 
    -- record routine 
    x"E4", x"00", x"F8", 	-- 49: ld r4, [00F8] switches 11100.100
    x"85", 			-- 4c: ld r5, [] memory 10000.101
    x"EC", x"00", x"FF", 	-- 4d: st r4, [00FF] 11101.100
    x"ED", x"00", x"FE", 	-- 50: st r5, [00FE]
    x"E0", x"00", x"FB", 	-- 53: ld r0,[00FB] 11100.000 buttons
    x"CA", x"04", 		-- 56: cmp 04 11001.010 
    x"BD", x"68", 		-- 58: jmp z 10111.101  dec lsb subroutine
    x"CA", x"02", 		-- 5a: cmp 02
    x"BD", x"6D", 		-- 5c: jmp z inc lsb subroutine
    x"CA", x"01", 		-- 5e: cmp 01
    x"BD", x"72", 		-- 60: jmp z record subroutine
    x"CA", x"08", 		-- 62: cmp 08
    x"BD", x"39", 		-- 64: jmp z normal release
    x"B8", x"49", 		-- 66: jmp abs loop wait for keypressed 10111.000
    -- dec lsb
    x"38", 			-- 68: mov r7,r0 00.111.000
    x"7B", 			-- 69: dec 01.111.011
    x"07", 			-- 6a: mov r0,r7 00.000.111
    x"B8", x"42", 		-- 6b: jump abs loop wait for keyrelease
    -- inc lsb
    x"38", 			-- 6d: mov r7,r0 00.111.000
    x"7A", 			-- 6e: inc 01.111.010
    x"07", 			-- 6f: mov r0,r7 00.000.111
    x"B8", x"42", 		-- 70: jump abs loop wait for keyrelease
    -- record
    x"8C", 			-- 72: st r4,[] 10001.100
    x"B8", x"42", 		-- 73: jump abs loop wait for keyrelease
    -- display bios
    x"C0", x"00", 		-- 75: ld r0,0 11000.000 
    x"07", 			-- 77: mov r0,r7 00.000.111
    x"00", 			-- 78: nop
    x"06", 			-- 79: mov r0,r6 
    x"EF", x"00", x"FA", 	-- 7a: st r7, special [00fa] 11101.111 -- ?
    x"C4", x"B1", 		-- 7d: ld r4, b1
    x"C5", x"05", 		-- 7f: ld r5, 05
    x"EC", x"00", x"FF", 	-- 81: st r4, display1 
    x"ED", x"00", x"FE", 	-- 84: st r5, display2
    x"E0", x"00", x"FB", 	-- 87: ld r0,[00FB] 11100.000
    x"CA", x"00", 		-- 8a: cmp 0
    x"BD", x"87", 		-- 8c: jz 87 test zero button
    x"E0", x"00", x"FB", 	-- 8e: ld r0,[00FB] 11100.000
    x"CA", x"00", 		-- 91: cmp 0
    x"BD", x"05", 		-- 93: jz 05 test zero button
    x"B8", x"8E", 		-- 95: jmp abs 8e

    -- start test program at 97
    x"C0", x"00", 		-- 97: ld r0,0
    x"07", 			-- 99: mov r0,r7
    x"C6", x"02", 		-- 9a: ld r6,2
    x"C5", x"FF", 		-- 9c: ld r5,ff
    x"8D", 			-- 9e: st r5,[]  10001101 
    x"7A", 			-- 9f: inc
    x"07", 			-- a0: mov r0,r7
    x"8D", 			-- a1: st r5,[]
    x"C5", x"00", 		-- a2: ld r5,00
    x"C4", x"01", 		-- a4: ld r4,01
    x"7A", 			-- a6: inc
    x"BC", x"AD", 		-- a7: jovr 11011100 
    x"07", 			-- a9: mov r0,r7
    x"8D", 			-- aa: st r5,[]
    x"B8", x"A6", 		-- ab: ja 11011000 
    x"20", 			-- ad: mov r4,r0  00100000
    x"7A", 			-- ae: inc
    x"BC", x"BF", 		-- af: jovr
    x"04", 			-- b1 : mov r0,r4
    x"07", 			-- b2: mov r0,r7
    x"80", 			-- b3: ld r0,[]  10000000
    x"60", 			-- b4: and r0  01000100
    x"B9", x"AD", 		-- b5: jnz  11011001 
    x"20", 			-- b7: mov r4,r0
    x"07", 			-- b8: mov r0,r7
    x"8C", 			-- b9 : st r4,[] 10001100
    x"44", 			-- ba: add r4  01100000
    x"BC", x"AD", 		-- bb : jovr
    x"B8", x"B8", 		-- bd : jabs 
    x"E7", x"00", x"F8", 	-- bf: ld r7,[switches]  11100111
    x"85", 			-- c2: ld r5,[] 10000101
    x"EF", x"00", x"FF", 	-- c3: st r7,[display1] 
    x"ED", x"00", x"FE", 	-- c6: st r5,[display2] 
    x"B8", x"BF", 		-- c9: jabs

    others => x"00"); 

    end Behavioral;
