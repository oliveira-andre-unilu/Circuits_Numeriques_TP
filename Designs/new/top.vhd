library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- The entity ports match the physical names in the BASYS3 XDC constraints [1, 3]
entity top is
    Port (
        clk : in std_logic;
        btnC : in std_logic; -- Master reset [1, 3]
        btnU, btnL, btnR, btnD : in std_logic; -- Navigation buttons [3]
        sw : in std_logic_vector(15 downto 0);
        led : out std_logic_vector(15 downto 0);
        seg : out std_logic_vector(6 downto 0);
        dp : out std_logic;
        an : out std_logic_vector(3 downto 0)
    );
end top;

architecture Structural of top is

    -- 1. Component Declarations [2]
    component cpu is
        Port (
            clk, rst : in std_logic;
            wr : out std_logic;
            addr : out std_logic_vector(15 downto 0);
            datawr : out std_logic_vector(7 downto 0);
            datard : in std_logic_vector(7 downto 0)
        );
    end component;

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

    component interface is
        Port (
            io_in : out std_logic_vector(31 downto 0);
            io_out : in std_logic_vector(31 downto 0);
            clk : in std_logic;
            btnU, btnL, btnR, btnD : in std_logic;
            sw : in std_logic_vector(15 downto 0);
            led : out std_logic_vector(15 downto 0);
            seg : out std_logic_vector(6 downto 0);
            dp : out std_logic;
            an : out std_logic_vector(3 downto 0)
        );
    end component;

    -- 2. Internal Signal Interconnections [1, 2]
    signal i_wr      : std_logic;
    signal i_addr    : std_logic_vector(15 downto 0);
    signal i_datawr  : std_logic_vector(7 downto 0);
    signal i_datard  : std_logic_vector(7 downto 0);
    signal i_io_in   : std_logic_vector(31 downto 0);
    signal i_io_out  : std_logic_vector(31 downto 0);

begin

    -- 3. Component Instantiations (Interconnecting the blocks) [2, 4]
    CPU_INST: cpu 
        port map (
            clk => clk, 
            rst => btnC, -- btnC serves as the global reset [1]
            wr => i_wr, 
            addr => i_addr, 
            datawr => i_datawr, 
            datard => i_datard
        );

    MEM_INST: memory 
        port map (
            clk => clk, 
            wr => i_wr, 
            addr => i_addr, 
            datawr => i_datawr, 
            datard => i_datard, 
            io_in => i_io_in, 
            io_out => i_io_out
        );

    INTER_INST: interface 
        port map (
            clk => clk, 
            io_in => i_io_in, 
            io_out => i_io_out, 
            btnU => btnU, 
            btnL => btnL, 
            btnR => btnR, 
            btnD => btnD, 
            sw => sw, 
            led => led, 
            seg => seg, 
            dp => dp, 
            an => an
        );

end Structural;