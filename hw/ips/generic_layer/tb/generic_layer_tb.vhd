library ieee;
use ieee.std_logic_1164.all;

library work;
use work.netgen_parameters.all;

entity generic_layer_tb is 

    generic (
        G_NB_INPUTS         : integer := 2;
        G_NB_WEIGHTS        : integer := 2
    );

end entity;

architecture behavior of generic_layer_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

    signal clk              : std_logic;
    signal rstn             : std_logic;
    signal inputs           : std_logic_vector(G_NB_INPUTS *DATA_WIDTH-1 downto 0)  := (others => '0');
    signal outputs          : std_logic_vector(G_NB_WEIGHTS*DATA_WIDTH-1 downto 0)  := (others => '0');

begin

    generic_layer : entity work.generic_layer 

        generic map ( 
                      G_NB_INPUTS   => G_NB_INPUTS,
                      G_NB_WEIGHTS  => G_NB_WEIGHTS 
                    )

        port map    ( 
                      clk           => clk,
                      rstn          => rstn,
                      inputs        => inputs,
                      outputs       => outputs
                    );

        inputs      <= (1 => '1',               -- inputs(0) = 2 
                        15 => '1',              -- inputs(1) = -128
                        others => '0');

        p_reset : process begin

            rstn    <= '0';
            wait for 5 * CLOCK_PERIOD;
            rstn    <= '1';
            wait;

        end process;

   
        p_clock : process begin

            clk     <= '0';
            wait for CLOCK_PERIOD_2;
            clk     <= '1';
            wait for CLOCK_PERIOD_2;

        end process;     
    
end architecture;

