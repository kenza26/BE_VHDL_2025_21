library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc is
    Port (
        clk_50MHz    : in  std_logic;
        raz_n        : in  std_logic;
        data_in      : in  std_logic;                      -- DOUT du MCP3201
        clk_adc      : out std_logic;                      -- horloge 1 MHz (gated during CS low)
        start_conv   : out std_logic;                      -- impulsion toutes les 100 ms (domaine 1MHz)
        angle_barre  : out std_logic_vector(11 downto 0);  -- 12 bits
        CS           : out std_logic;                      -- Chip Select (active low)
        fin_conv     : out std_logic                       -- indicateur fin de conversion (1 tick @ 1MHz)
    );
end adc;

architecture Behavioral of adc is

    -- === Génération 1 MHz ===
    signal clk_1MHz       : std_logic := '0';
    signal cnt_1MHz       : integer range 0 to 24 := 0; -- toggle every 25 cycles -> 50MHz -> 1MHz

    -- === Génération start_conv toutes les 100 ms (en domaine 1MHz) ===
    signal start_100ms    : std_logic := '0';
    signal cnt_100ms      : integer range 0 to 100000 := 0; -- 100 ms @ 1MHz = 100000 ticks
    constant COUNT_100MS  : integer := 100000;

    -- === Compteur de fronts (rising edges) pendant CS='0' ===
    signal adc_count      : integer range 0 to 31 := 0;  -- on compte edges (we'll use 1..14 window)

    -- === Registre à décalage (12 bits) ===
    signal shift_reg      : std_logic_vector(11 downto 0) := (others => '0');

    -- === Machine à états ===
    type etat_type is (IDLE, START, READ_BITS, END_CONV);
    signal etat           : etat_type := IDLE;

    -- === Signaux internes / sorties internes ===
    signal cs_int         : std_logic := '1';
   
    signal fin_conv_i     : std_logic := '0';
    signal data_temp      : std_logic_vector(11 downto 0) := (others => '0');

begin

    ----------------------------------------------------------------
    -- Génération 1 MHz (diviseur 50MHz -> 1MHz)
    ----------------------------------------------------------------
    process(clk_50MHz, raz_n)
    begin
        if raz_n = '0' then
            clk_1MHz <= '0';
            cnt_1MHz <= 0;
        elsif rising_edge(clk_50MHz) then
            if cnt_1MHz = 24 then
                clk_1MHz <= not clk_1MHz;
                cnt_1MHz <= 0;
            else
                cnt_1MHz <= cnt_1MHz + 1;
            end if;
        end if;
		  
    end process;
	 
clk_adc <= clk_1MHz;

--    ----------------------------------------------------------------
--    -- Génération start_conv toutes les 100 ms (dans domaine clk_1MHz)
--    ----------------------------------------------------------------
    process(clk_1MHz, raz_n)
    begin
        if raz_n = '0' then
            cnt_100ms <= 0;
            start_100ms <= '0';
        elsif rising_edge(clk_1MHz) then
            if cnt_100ms = COUNT_100MS - 1 then
                cnt_100ms <= 0;
                start_100ms <= '1';   -- pulse 1 tick @ 1MHz
            else
                cnt_100ms <= cnt_100ms + 1;
                start_100ms <= '0';
            end if;
        end if;
    end process;

    start_conv <= start_100ms;

--
--    ----------------------------------------------------------------
--    -- Comptage des fronts (rising edges) sur clk_1MHz pendant CS actif (cs_int = '0')
--    -- On remet à 0 quand CS remonte.
--    -- adc_count = 1 after first rising edge while CS low, etc.
--    ----------------------------------------------------------------
    process(clk_1MHz, raz_n)
    begin
        if raz_n = '0' then
            adc_count <= 0;
        elsif rising_edge(clk_1MHz) then
            if cs_int = '0' then
                if adc_count < 31 then
                    adc_count <= adc_count + 1;
                end if;
            else
                adc_count <= 0;
            end if;
        end if;
    end process;
--
--    ----------------------------------------------------------------
--    -- Registre à décalage : on récupère les bits utiles envoyés par MCP3201
--    -- Selon datasheet: after CS low, there is a null bit then 12 data bits.
--    -- Ici on lit quand adc_count dans [3 .. 14] (1-based counts). We shift MSB first.
--    ----------------------------------------------------------------
    process(clk_1MHz, raz_n)
    begin
        if raz_n = '0' then
            shift_reg <= (others => '0');
        elsif rising_edge(clk_1MHz) then
            if cs_int = '0' and adc_count >= 3 and adc_count <= 14 then
                -- shift left and insert new LSB (incoming bit is MSB first)
                shift_reg <= shift_reg(10 downto 0) & data_in;
            end if;
            -- if CS goes high, we keep shift_reg until FSM samples it
        end if;
    end process;
--
--    ----------------------------------------------------------------
--    -- Machine à états principale (domaine clk_1MHz)
--    -- Séquence:
--    -- IDLE -> START (CS low, enable sclk) -> READ_BITS (wait until adc_count == 14) -> END_CONV (latch & release)
--    ----------------------------------------------------------------
    process(clk_50MHz, raz_n)
    begin
        if raz_n = '0' then
            etat <= IDLE;
            cs_int <= '1';         
            data_temp <= (others => '0');
            fin_conv_i <= '0';
        elsif rising_edge(clk_50MHz) then
            -- default: clear fin_conv_i each tick
            fin_conv_i <= '0';

            case etat is
                when IDLE =>
                    cs_int <= '1';
                    
                    if start_100ms = '1' then
                        -- start conversion
                        cs_int <= '0';
                        -- adc_count will start incrementing on next rising edges
                        etat <= START;
                    end if;

                when START =>
                    -- wait until we have received the 14th rising edge (adc_count = 14)
                    -- go to READ_BITS state to monitor adc_count
                    etat <= READ_BITS;

                when READ_BITS =>
                    -- keep CS low and SCLK enabled; rec_dec is filling shift_reg
                    if adc_count >= 14 then
                        -- we've read the 12 data bits (counts 3..14), latch and finish
                        data_temp <= shift_reg;
                        etat <= END_CONV;
                    end if;

                when END_CONV =>
                    -- release CS and stop SCLK
                    cs_int <= '1';
                  
                    fin_conv_i <= '1';  -- one tick pulse indicating conversion done
                    etat <= IDLE;

                when others =>
                    etat <= IDLE;
            end case;
        end if;
    end process;
--
--    ----------------------------------------------------------------
--    -- Assignation sorties
--    ----------------------------------------------------------------
    angle_barre <= data_temp;
    CS <= cs_int;
    fin_conv <= fin_conv_i;
--
end Behavioral;
