library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--============================================================
-- Interface Avalon - Acquisition vitesse vent
-- Conforme au cahier de spécifications
--============================================================
entity gestion_anemometre_avalon is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;

        chipselect  : in  std_logic;
        write_n     : in  std_logic;
        address     : in  std_logic_vector(1 downto 0);
        writedata   : in  std_logic_vector(31 downto 0);
        readdata    : out std_logic_vector(31 downto 0);

        in_freq_anemometre : in std_logic
    );
end gestion_anemometre_avalon;

architecture rtl of gestion_anemometre_avalon is

    --===============================
    -- Registres Avalon
    --===============================
    signal config_reg : std_logic_vector(2 downto 0) := (others => '0');

    -- bits config
    signal raz_n      : std_logic;
    signal continu    : std_logic;
    signal start_stop : std_logic;

    --===============================
    -- Signaux module interne
    --===============================
    signal data_valid_int      : std_logic;
    signal data_anemometre_int : std_logic_vector(7 downto 0);

    --===============================
    -- Code renvoyé au NIOS
    --===============================
    signal code_reg : std_logic_vector(9 downto 0);

    --===============================
    -- Composant métier
    --===============================
    component gestion_anemometre is
        port (
            clk_50MHz         : in  std_logic;
            raz_n              : in  std_logic;
            in_freq_anemometre : in  std_logic;
            continu            : in  std_logic;
            start_stop         : in  std_logic;
            data_valid         : out std_logic;
            data_anemometre    : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    ------------------------------------------------------------------
    -- Décodage registre config
    ------------------------------------------------------------------
    raz_n      <= config_reg(0);
    continu    <= config_reg(1);
    start_stop <= config_reg(2);

    ------------------------------------------------------------------
    -- Instanciation du module anémomètre
    ------------------------------------------------------------------
    anemo_inst : gestion_anemometre
        port map (
            clk_50MHz         => clk,
            raz_n              => raz_n,
            in_freq_anemometre => in_freq_anemometre,
            continu            => continu,
            start_stop         => start_stop,
            data_valid         => data_valid_int,
            data_anemometre    => data_anemometre_int
        );

    ------------------------------------------------------------------
    -- Construction du registre CODE
    -- b9 = valid
    -- b7..b0 = data_anemometre
    ------------------------------------------------------------------
    code_reg <= data_valid_int & '0' & data_anemometre_int;

    ------------------------------------------------------------------
    -- Écriture Avalon
    ------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            config_reg <= (others => '0');
        elsif rising_edge(clk) then
            if chipselect = '1' and write_n = '0' then
                if address = "00" then
                    config_reg <= writedata(2 downto 0);
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Lecture Avalon
    ------------------------------------------------------------------
    process(address, config_reg, code_reg)
    begin
        case address is
            when "00" =>
                readdata <= (31 downto 3 => '0') & config_reg;

            when "01" =>
                readdata <= (31 downto 10 => '0') & code_reg;

            when others =>
                readdata <= (others => '0');
        end case;
    end process;

end rtl;
