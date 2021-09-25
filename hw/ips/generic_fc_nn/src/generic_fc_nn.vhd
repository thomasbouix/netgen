-- Generic Fully Convolutionnal Neural Network
-- typical structure : 
-- 2 3 3 3 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

entity generic_fc_nn is 

    generic (
        g_NETWORK_INPUTS        : integer := 2;     -- number of inputs of the first layer
        g_NETWORK_OUTPUTS       : integer := 4;     -- number of outputs of the last layer
        g_NETWORK_HEIGHT        : integer := 3;     -- number of inputs / outputs of middle layers
        g_NETWORK_LAYERS        : integer := 5      -- number of layers inside the network
    );

    port(
        clk                     : in  std_logic;
        rstn                    : in  std_logic
    );

end entity;

architecture rtl of generic_fc_nn is

    -- generic_layer class header
    component generic_layer

        generic (
            g_NB_INPUTS         : integer;
            g_NB_WEIGHTS        : integer
       );

        port (
            clk                 : in  std_logic;
            rstn                : in  std_logic;
            inputs              : in  t_data_array(0 to g_NB_INPUTS  - 1);
            outputs             : out t_data_array(0 to g_NB_WEIGHTS - 1)
        );

    end component;

    signal r_layer_connections  : t_data_array(0 to g_NETWORK_LAYERS * g_NETWORK_HEIGHT - 1)    := (others => (others => '0'));
    signal network_inputs       : t_data_array(0 to g_NETWORK_INPUTS  - 1)                      := (others => (others => '0'));
    signal network_outputs      : t_data_array(0 to g_NETWORK_OUTPUTS - 1)                      := (others => (others => '0'));


begin

    layers : for i in 0 to g_NETWORK_LAYERS - 1 generate
        
        first_layer : if i = 0 generate

            FL : generic_layer
                generic map (
                    g_NB_INPUTS     => g_NETWORK_INPUTS,
                    g_NB_WEIGHTS    => g_NETWORK_HEIGHT
                )

                port map (
                   clk              => clk,  
                   rstn             => rstn,
                   inputs           => network_inputs,
                   outputs          => r_layer_connections(0 to g_NETWORK_HEIGHT - 1)
                );
        end generate first_layer;

        middle_layers : if i > 0 and i < g_NETWORK_LAYERS - 1 generate

            ML : generic_layer 
                
                generic map (
                    g_NB_INPUTS     => g_NETWORK_HEIGHT,
                    g_NB_WEIGHTS    => g_NETWORK_HEIGHT
                )

                port map (
                   clk              => clk,  
                   rstn             => rstn,
                   inputs           => r_layer_connections( g_NETWORK_HEIGHT*(i-1) to g_NETWORK_HEIGHT*(i)   - 1),
                   outputs          => r_layer_connections( g_NETWORK_HEIGHT*(i)   to g_NETWORK_HEIGHT*(i+1) - 1) 
                );
        end generate middle_layers;

        last_layer : if i = g_NETWORK_LAYERS - 1 generate

            LL : generic_layer
                generic map (
                    g_NB_INPUTS     => g_NETWORK_HEIGHT,
                    g_NB_WEIGHTS    => g_NETWORK_OUTPUTS
                )

                port map (
                   clk              => clk,  
                   rstn             => rstn,
                   inputs           => r_layer_connections( g_NETWORK_HEIGHT*(i-1) to g_NETWORK_HEIGHT*(i) - 1),
                   outputs          => network_outputs
                );
        end generate last_layer;

    end generate layers;

end architecture;

