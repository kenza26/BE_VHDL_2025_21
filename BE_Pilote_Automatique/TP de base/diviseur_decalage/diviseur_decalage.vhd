library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity diviseur_decalage is 
    port (
        clk_1s     : out std_logic;
        rst        : in  std_logic;
        clk_50Mhz  : in  std_logic
    );
end entity diviseur_decalage;

architecture divDec of diviseur_decalage is 
begin 

    process (clk_50Mhz , rst)
        variable temp    : integer range 0 to 25000000;
        variable clk_1st : std_logic := '0';
    begin 

        if (rst = '0') then 
            clk_1st := '0';
            temp    := 0;

        elsif (rising_edge(clk_50Mhz)) then 
            temp := temp + 1;

            if (temp = 25000000) then 
                temp    := 0;
                clk_1st := not clk_1st;
            end if;
        end if;

        clk_1s <= clk_1st;   

    end process;

end architecture divDec;
