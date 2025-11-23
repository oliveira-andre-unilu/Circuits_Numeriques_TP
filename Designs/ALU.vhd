----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.11.2025 11:28:29
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    port (  clk     : in std_logic;
            rst   : in std_logic;
            wr_en   : out std_logic;
            dr      : in std_logic_vector (7 downto 0); -- Data to read in the memory
            dw      : out std_logic_vector(7 downto 0); -- Data to write in the memory
            addr    : out std_logic_vector(7 downto 0); -- Reference to the memory
            pc_out  : out std_logic_vector(7 downto 0); -- Program counter
            accu_out: out std_logic_vector(7 downto 0) -- Accumulator used for calculations
        );
end ALU;


architecture Behavioral of ALU is
  type t_state is (S0, S1, S2, S3, S4); -- Defined states
  signal state, next_state : t_state;

  signal PC, next_PC : std_logic_vector(15 downto 0);
  signal IR, next_IR : std_logic_vector(23 downto 0);

  signal addr_reg : std_logic_vector(15 downto 0);
  signal wr_reg   : std_logic;
begin
    -- Output drivers (registered)
  ADDR <= addr_reg;
  wr_en   <= wr_reg;
  dw <= (others => '0'); -- not used in Task 2

  ---------------------------------------------------------------------
  -- Synchronous register update
  ---------------------------------------------------------------------
  proc_regs : process(clk, rst)
  begin
    if rst = '1' then
      state <= S0;
      PC    <= (others => '0');     -- will be set to 0000 on transition 0->1
      IR    <= (others => '0'); -- Instruction register
      addr_reg <= (others => '0');
      wr_reg <= '0';
    elsif rising_edge(clk) then
      state <= next_state;
      PC    <= next_PC;
      IR    <= next_IR;
      addr_reg <= addr_reg; -- will be updated by combinational next-cycle assignment below
      wr_reg   <= wr_reg;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- Combinational next-state & outputs (implements transitions)
  ---------------------------------------------------------------------
  proc_comb : process(state, dr, PC, IR)
    variable pc_lsb : unsigned(7 downto 0);
    variable pc_msb : std_logic_vector(7 downto 0);
    variable tmp_next_PC : std_logic_vector(15 downto 0);
  begin
    -- defaults (hold values)
    next_state <= state;
    next_PC    <= PC;
    next_IR    <= IR;
    addr_reg   <= (others => '0');
    wr_reg     <= '0';

    -- convenience
    pc_msb := PC(15 downto 8);
    pc_lsb := unsigned(PC(7 downto 0));

    case state is

      -- State 0: power-up -> 1
      when S0 =>
        -- always: PC <= 0000, Addr <= 0000, WR <= 0, then go to state 1
        next_PC <= (others => '0');
        addr_reg <= (others => '0');
        wr_reg <= '0';
        next_state <= S1;

      -- State 1: fetch first byte
      when S1 =>
        -- memory read already active; DataRd holds received byte
        -- store first fetched byte into IR(23:16), increment PC LSB
        next_IR <= dr & IR(15 downto 0);  -- place dr into IR(23:16)
        -- increment only PC(7 downto 0)
        tmp_next_PC := PC;
        tmp_next_PC(7 downto 0) := std_logic_vector(pc_lsb + 1);
        next_PC <= tmp_next_PC;

        -- Decide next state based on DataRd[7:5]
        if dr(7) = '0' or (dr(7 downto 5) = "100") then
          -- 1-byte instruction -> execute
          next_state <= S4;
        else
          -- longer instruction -> fetch 2nd byte
          next_state <= S2;
          -- set ADDR to new PC LSB for next read
          addr_reg <= tmp_next_PC;
          wr_reg <= '0';
        end if;

      -- State 2: fetch second byte
      when S2 =>
        -- DataRd contains second byte
        next_IR <= IR(23 downto 16) & dr & IR(7 downto 0); -- put into IR(15:8)
        -- increment PC LSB
        tmp_next_PC := PC;
        tmp_next_PC(7 downto 0) := std_logic_vector(pc_lsb + 1);
        next_PC <= tmp_next_PC;

        -- decide: if instruction 2-bytes -> execute, else -> fetch 3rd
        -- instruction opcode is in IR(23:16)
        if IR(23 downto 21) = "101" or IR(23 downto 21) = "110" then
          next_state <= S4;
        else
          next_state <= S3;
          addr_reg <= tmp_next_PC;
          wr_reg <= '0';
        end if;

      -- State 3: fetch third byte
      when S3 =>
        next_IR <= IR(23 downto 8) & dr; -- put into IR(7:0)
        tmp_next_PC := PC;
        tmp_next_PC(7 downto 0) := std_logic_vector(pc_lsb + 1);
        next_PC <= tmp_next_PC;
        -- always go to execute
        next_state <= S4;

      -- State 4: execute (for Task 2: just done, prepare next fetch)
      when S4 =>
        -- set ADDR <= PC (PC may have been modified by an instruction, but for Task 2 it's unchanged)
        addr_reg <= PC;
        wr_reg <= '0';
        -- instruction finished, go to state 1 to fetch next instruction byte
        next_state <= S1;

      when others =>
        next_state <= S0;
    end case;
  end process;

end Behavioral;
