library ieee;
use ieee.std_logic_1164.all;

library work;
use work.parameters.all;

entity generic_fc_nn_tb is 

    generic (
        g_NETWORK_INPUTS    : integer := 2;     -- number of inputs of the first layer
        g_NETWORK_OUTPUTS   : integer := 4;     -- number of outputs of the last layer
        g_NETWORK_HEIGHT    : integer := 3;     -- number of inputs / outputs of middle layers
        g_NETWORK_LAYERS    : integer := 5      -- number of layers inside the network
    );

end entity;

architecture behavior of generic_fc_nn_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

    signal clk              : std_logic;
    signal rstn             : std_logic;

begin

    generic_fc_nn : entity work.generic_fc_nn 

        generic map ( 
            g_NETWORK_INPUTS    => g_NETWORK_INPUTS,
            g_NETWORK_OUTPUTS   => g_NETWORK_OUTPUTS,
            g_NETWORK_HEIGHT    => g_NETWORK_HEIGHT,     
            g_NETWORK_LAYERS    => g_NETWORK_LAYERS
        )

        port map    ( 
            clk                 => clk,
            rstn                => rstn
        );

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

