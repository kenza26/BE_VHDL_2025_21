library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--********************************************************************
-- Module : gestion_anemometre
--
-- Rôle :
--  - Mesurer la vitesse du vent en comptant le nombre d’impulsions
--    du signal anémomètre sur une fenêtre EXACTE de 1 seconde
--
-- Spécifications respectées :
--  - clk_50MHz : horloge 50 MHz
--  - raz_n     : reset actif bas
--  - in_freq_anemometre : signal 0..250 Hz
--  - continu   : 1 = mode continu, 0 = monocoup
--  - start_stop:
--        monocoup : 1 = start, 0 = stop + data_valid = 0
--  - data_valid :
--        =1 quand une mesure est valide
--  - data_anemometre :
--        vitesse du vent codée sur 8 bits
--********************************************************************
entity gestion_anemometre is
    port (
        clk_50MHz          : in  std_logic;
        raz_n               : in  std_logic;
        in_freq_anemometre  : in  std_logic;
        continu             : in  std_logic;
        start_stop          : in  std_logic;
        data_valid          : out std_logic;
        data_anemometre     : out std_logic_vector(7 downto 0)
    );
end gestion_anemometre;

architecture rtl of gestion_anemometre is

    ------------------------------------------------------------------
    -- Génération d’une impulsion toutes les 1 seconde
    ------------------------------------------------------------------
    signal tick_1s   : std_logic := '0';
    signal div_count : unsigned(25 downto 0) := (others => '0');
    constant DIV_MAX : unsigned(25 downto 0) := to_unsigned(49_999_999, 26);
    -- 50 MHz → 50 000 000 cycles = 1 seconde

    ------------------------------------------------------------------
    -- Synchronisation et détection de fronts anémomètre
    ------------------------------------------------------------------
    signal anemo_sync : std_logic := '0';
    signal anemo_prev : std_logic := '0';

    ------------------------------------------------------------------
    -- Mesure
    ------------------------------------------------------------------
    signal pulse_count : unsigned(7 downto 0) := (others => '0');
    signal data_reg    : unsigned(7 downto 0) := (others => '0');

    ------------------------------------------------------------------
    -- Contrôle acquisition
    ------------------------------------------------------------------
    signal acquisition_en_cours : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- 1) Diviseur temporel → impulsion 1 seconde
    ------------------------------------------------------------------
    process(clk_50MHz, raz_n)
    begin
        if raz_n = '0' then
            div_count <= (others => '0');
            tick_1s   <= '0';
        elsif rising_edge(clk_50MHz) then
            if div_count = DIV_MAX then
                div_count <= (others => '0');
                tick_1s   <= '1';     -- impulsion 1 cycle
            else
                div_count <= div_count + 1;
                tick_1s   <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 2) Gestion des modes (continu / monocoup)
    ------------------------------------------------------------------
    process(clk_50MHz, raz_n)
    begin
        if raz_n = '0' then
            acquisition_en_cours <= '0';
        elsif rising_edge(clk_50MHz) then
            if continu = '1' then
                acquisition_en_cours <= '1';     -- toujours actif
            else
                if start_stop = '1' then
                    acquisition_en_cours <= '1'; -- démarrage monocoup
                else
                    acquisition_en_cours <= '0'; -- arrêt monocoup
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 3) Comptage + validation de la mesure
    ------------------------------------------------------------------
    process(clk_50MHz, raz_n)
    begin
        if raz_n = '0' then
            pulse_count <= (others => '0');
            data_reg    <= (others => '0');
            data_valid  <= '0';
            anemo_sync  <= '0';
            anemo_prev  <= '0';

        elsif rising_edge(clk_50MHz) then

            -- valeur par défaut
            data_valid <= '0';

            -- synchronisation du signal anémomètre
            anemo_prev <= anemo_sync;
            anemo_sync <= in_freq_anemometre;

            -- comptage des fronts montants
            if acquisition_en_cours = '1' then
                if anemo_prev = '0' and anemo_sync = '1' then
                    if pulse_count < 255 then
                        pulse_count <= pulse_count + 1;
                    end if;
                end if;
            end if;

            -- fin EXACTE d’une fenêtre de 1 seconde
            if tick_1s = '1' then
                data_reg    <= pulse_count;
                pulse_count <= (others => '0');
                data_valid  <= '1';
            end if;

            -- remise à zéro demandée par la spec (monocoup)
            if continu = '0' and start_stop = '0' then
                data_valid <= '0';
            end if;

        end if;
    end process;

    ------------------------------------------------------------------
    -- Sortie
    ------------------------------------------------------------------
    data_anemometre <= std_logic_vector(data_reg);

end rtl;





