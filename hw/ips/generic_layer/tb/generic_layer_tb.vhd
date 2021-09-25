library ieee;
use ieee.std_logic_1164.all;

library work;
use work.parameters.all;

entity generic_layer_tb is 

    generic (
        g_NB_INPUTS         : integer := 2;
        g_NB_WEIGHTS        : integer := 2
    );

end entity;

architecture behavior of generic_layer_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

    signal clk              : std_logic;
    signal rstn             : std_logic;
    signal inputs           : t_data_array(0 to g_NB_INPUTS  - 1)   := (others => (others => '0'));
    signal outputs          : t_data_array(0 to g_NB_WEIGHTS - 1)   := (others => (others => '0'));

begin

    generic_layer : entity work.generic_layer 

        generic map ( 
                      g_NB_INPUTS   => g_NB_INPUTS,
                      g_NB_WEIGHTS  => g_NB_WEIGHTS 
                    )

        port map    ( 
                      clk           => clk,
                      rstn          => rstn,
                      inputs        => inputs,
                      outputs       => outputs
                    );

        inputs(0)   <= (1 => '1', others => '0');       -- i(0) = 2
        inputs(1)   <= (7 => '1', others => '0');       -- i(1) = -128

        p_reset : process begin

            rstn    <= '0';
            wait for 50 * CLOCK_PERIOD;
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

