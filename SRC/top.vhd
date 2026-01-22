------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------------
-- OVERVIEW
----------------------------------------------------------------------------------
-- Top-level System Integration Module
--
-- This module represents the highest level of the hardware design and is
-- directly connected to the FPGA physical pins via the XDC constraints file.
--
-- Responsibilities:
--  - Instantiates and interconnects the main system blocks:
--      * CPU        : Executes instructions and controls memory access
--      * Memory     : Provides program/data storage and memory-mapped I/O
--      * Interface  : Connects memory-mapped I/O to real hardware (LEDs,
--                     switches, buttons, and 7-segment display)
--  - Routes the global clock and reset signals
--  - Exposes memory-mapped peripherals to the CPU via internal buses
----------------------------------------------------------------------------------

------------------------------------------------------------------
-- top: top-level hardware module
-- - Entity connected directly to FPGA pins
------------------------------------------------------------------
ENTITY top IS
    PORT (
        clk : IN STD_LOGIC;                         -- 100Mhz on-board oscillator
        btnC : IN STD_LOGIC;                        -- Center Button (Used as global reset)
        btnU, btnL, btnR, btnD : IN STD_LOGIC;      -- User input D-Pad Buttons (Used by interface module, not directly connected to cpu)
        sw : IN STD_LOGIC_VECTOR(15 DOWNTO 0);      -- 16 physical switches (Used by interface and memory I/O modules)
        led : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);    -- 16 LEDs
        
        -- 4x7-segment display
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);     -- Segment Control (Segments On/Off)
        dp : OUT STD_LOGIC;                         -- Decimal Point (Decimal Point On/Off)
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)       -- 7-Segment Display (Which of the 4 7-segment displays)
    );
END top;

------------------------------------------------------------------
-- ARCHITECTURE Structural: Defines the structure of modules
-- - Connects blocks/modules together
-- - Contains no logic
------------------------------------------------------------------
ARCHITECTURE Structural OF top IS

    ------------------------------------------------------------------
    -- Component Declarations
    ------------------------------------------------------------------

    ----------------
    -- CPU
    ----------------
    COMPONENT cpu IS
        PORT (
            clk, rst    : IN STD_LOGIC;                         -- Clock and Reset
            wr          : OUT STD_LOGIC;                        -- Write Enable
            addr        : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);    -- Memory Address bus
            datawr      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);     -- Data written to memory
            datard      : IN STD_LOGIC_VECTOR(7 DOWNTO 0)       -- Data read from memory
        );
    END COMPONENT;

    ----------------
    -- Memory
    ----------------
    COMPONENT memory IS
        PORT (
            clk     : IN STD_LOGIC;                         -- Clock
            wr      : IN STD_LOGIC;                         -- Write Enable
            addr    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);     -- Memory Address bus
            datawr  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);      -- Data written to memory
            datard  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);     -- Data read from memory
            io_in   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);     -- I/O input (Interface data --> Memory)
            io_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)     -- I/O output (Memory data --> Interface)
        );
    END COMPONENT;

    ----------------
    -- Interface
    ----------------
    COMPONENT interface IS
        Port (
            io_in                   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);    -- I/O input (Memory data --> Interface)
            io_out                  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);     -- I/O output (Interface data --> Memory)
            clk                     : IN STD_LOGIC;                         -- Clock
            btnU, btnL, btnR, btnD  : IN STD_LOGIC;                         -- D-Pad Buttons
            sw                      : IN STD_LOGIC_VECTOR(15 DOWNTO 0);     -- 16 physical switches
            led                     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);    -- 16 LEDs

            -- 4x7-segment display
            seg                     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);     -- Segment Control (Segment On/Off)
            dp                      : OUT STD_LOGIC;                        -- Decimal Point (Decimal Point On/Off)
            an                      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)      -- 7-Segment Display (Which of the 4 7-segment displays)
        );
    END COMPONENT;

    ------------------------------------------------------------------
    -- Internal Signal Interconnections
    ------------------------------------------------------------------
    SIGNAL i_wr      : STD_LOGIC;                       -- CPU instructs to write
    SIGNAL i_addr    : STD_LOGIC_VECTOR(15 DOWNTO 0);   -- CPU --> Memory Address
    SIGNAL i_datawr  : STD_LOGIC_VECTOR(7 DOWNTO 0);    -- CPU --> Memory Data
    SIGNAL i_datard  : STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Memory --> CPU Data
    SIGNAL i_io_in   : STD_LOGIC_VECTOR(31 DOWNTO 0);   -- Interface --> Memory
    SIGNAL i_io_out  : STD_LOGIC_VECTOR(31 DOWNTO 0);   -- Memory --> Interface

BEGIN

    ------------------------------------------------------------------
    -- Component Instantiations (Interconnecting the blocks/modules)
    ------------------------------------------------------------------

    ----------------------------------------
    -- CPU Instantiation
    ----------------------------------------
    CPU_INST: cpu 
        PORT MAP (
            clk     => clk,         -- FPGA clock --> CPU clock
            rst     => btnC,        -- btnC (Center D-Pad Button) resets CPU

            -- Internal signals used for CPU to Memory communication
            wr      => i_wr,
            addr    => i_addr, 
            datawr  => i_datawr, 
            datard  => i_datard
        );

    ----------------------------------------
    -- Memory and I/O Decoder Instantiation
    ----------------------------------------
    MEM_INST: memory 
        PORT MAP (
            clk     => clk,         -- FPGA clock --> Memory clock

            -- Internal signals used for Memory to CPU communication
            wr      => i_wr, 
            addr    => i_addr, 
            datawr  => i_datawr, 
            datard  => i_datard, 

            -- Internal Memory bridging of CPU and Interface
            io_in   => i_io_in, 
            io_out  => i_io_out
        );

    ----------------------------------------
    -- Real Hardware to Memory-mapped I/O
    ----------------------------------------
    INTER_INST: interface 
        PORT MAP (
            clk     => clk,         -- FPGA clock --> I/O clock

            -- Internal Memory bridging of CPU and Interface
            io_in   => i_io_in,
            io_out  => i_io_out, 

            btnU    => btnU,        -- D-Pad Button Up 
            btnL    => btnL,        -- D-Pad Button Left 
            btnR    => btnR,        -- D-Pad Button Right 
            btnD    => btnD,        -- D-Pad Button Down 
            sw      => sw,          -- Switches
            led     => led,         -- LEDs

            -- 4x7-segment display
            seg     => seg,         -- Segment Control (Segment On/Off)
            dp      => dp,          -- Decimal Point (Decimal Point On/Off)
            an      => an           -- 7-Segment Display (Which of the 4 7-segment displays)
        );

END Structural;