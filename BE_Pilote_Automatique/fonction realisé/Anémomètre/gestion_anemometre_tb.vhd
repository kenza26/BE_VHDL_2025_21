library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_gestion_anemometre is
end tb_gestion_anemometre;

architecture sim of tb_gestion_anemometre is

    -- Signaux DUT
    signal clk_50MHz         : std_logic := '0';
    signal raz_n              : std_logic := '0';
    signal in_freq_anemometre : std_logic := '0';
    signal continu            : std_logic := '0';
    signal start_stop         : std_logic := '0';
    signal data_valid         : std_logic;
    signal data_anemometre    : std_logic_vector(7 downto 0);

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;    -- 50 MHz
    constant ANEMO_PER  : time := 100 ms;   -- 10 Hz (10 impulsions par seconde)

begin

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    DUT : entity work.gestion_anemometre
        port map (
            clk_50MHz         => clk_50MHz,
            raz_n              => raz_n,
            in_freq_anemometre => in_freq_anemometre,
            continu            => continu,
            start_stop         => start_stop,
            data_valid         => data_valid,
            data_anemometre    => data_anemometre
        );

    ------------------------------------------------------------------
    -- Horloge 50 MHz
    ------------------------------------------------------------------
    clk_process : process
    begin
        clk_50MHz <= '0';
        wait for CLK_PERIOD/2;
        clk_50MHz <= '1';
        wait for CLK_PERIOD/2;
    end process;

    ------------------------------------------------------------------
    -- Signal anémomètre (10 Hz)
    ------------------------------------------------------------------
    anemo_process : process
    begin
        in_freq_anemometre <= '1';
        wait for ANEMO_PER/2;
        in_freq_anemometre <= '0';
        wait for ANEMO_PER/2;
    end process;

    ------------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------------
    stim_proc : process
    begin
        ------------------------------------------------------------------
        -- Reset
        ------------------------------------------------------------------
	raz_n <= '0';
	wait for 200 ns;
        raz_n <= '1';
		

--        ------------------------------------------------------------------
--        -- MODE CONTINU
--        ------------------------------------------------------------------
        continu    <= '1';
        start_stop <= '0';
        wait;
--
--        ------------------------------------------------------------------
--        -- MODE MONOCOUP
--        ------------------------------------------------------------------
--        continu <= '0';
--
--        -- démarrage mesure
--        start_stop <= '1';
--        wait for 2 sec;
--
--        -- arrêt → data_valid doit retomber à 0
--        start_stop <= '0';
--        wait for 1 sec;
--
--        wait;
    end process;

end sim;


