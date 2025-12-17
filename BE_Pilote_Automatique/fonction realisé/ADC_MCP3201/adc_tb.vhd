LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.math_real.ALL;

ENTITY tb_adc IS
END tb_adc;

ARCHITECTURE behavior OF tb_adc IS

    -- Signaux pour le DUT
    SIGNAL clk_50MHz   : std_logic := '0';
    SIGNAL raz_n       : std_logic := '0';
    SIGNAL data_in     : std_logic := '0';
    SIGNAL clk_adc     : std_logic;
    SIGNAL start_conv  : std_logic;
    SIGNAL angle_barre : std_logic_vector(11 downto 0);
    SIGNAL CS          : std_logic;
    SIGNAL fin_conv    : std_logic;

    -- Composant DUT
    COMPONENT adc
        Port (
            clk_50MHz    : in  std_logic;
            raz_n        : in  std_logic;
            data_in      : in  std_logic;
            clk_adc      : out std_logic;
            start_conv   : out std_logic;
            angle_barre  : out std_logic_vector(11 downto 0);
            CS           : out std_logic;
            fin_conv     : out std_logic
        );
    END COMPONENT;

BEGIN

    -- Instanciation du DUT
    UUT: adc
        PORT MAP (
            clk_50MHz    => clk_50MHz,
            raz_n        => raz_n,
            data_in      => data_in,
            clk_adc      => clk_adc,
            start_conv   => start_conv,
            angle_barre  => angle_barre,
            CS           => CS,
            fin_conv     => fin_conv
        );

    ----------------------------------------------------------------
    -- Génération du clock 50 MHz
    ----------------------------------------------------------------
    clk_process: process
    begin
        while true loop
            clk_50MHz <= '0';
            wait for 10 ns;
            clk_50MHz <= '1';
            wait for 10 ns;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- Reset initial
    ----------------------------------------------------------------
    reset_process: process
    begin
        raz_n <= '0';
        wait for 100 ns;
        raz_n <= '1';
        wait;
    end process;

    ----------------------------------------------------------------
    -- Génération du signal data_in aléatoire (simulate MCP3201)
    ----------------------------------------------------------------
    adc_data_process: process
        variable seed1 : positive := 12345;
        variable seed2 : positive := 67890;
        variable rand  : real;
    begin
        while true loop
            uniform(seed1, seed2, rand);
            if rand < 0.5 then
                data_in <= '0';
            else
                data_in <= '1';
            end if;
            wait for 1 us;  -- fréquence ≈ 1 MHz
        end loop;
    end process;

END behavior;
