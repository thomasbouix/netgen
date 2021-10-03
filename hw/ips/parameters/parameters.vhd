-- HDL parameters shared by all IPs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    -- NETWORK DATA WIDTH
    constant p_DATA_WIDTH : integer := 8;

    -- TYPES
    subtype t_data          is signed(p_DATA_WIDTH - 1 downto 0);                         -- atomic data element
    type    t_int_array     is array (integer range <>)                   of integer;     -- array of integer
    type    t_neurons       is array (integer range <>)                   of integer;     -- number of neurons for each layer
    type    t_bias          is array (integer range <>)                   of integer;     -- array of bias for one layer
    type    t_weights       is array (integer range <>, integer range <>) of integer;     -- weights(row, column) = weights(output, input)

    -- NETWORK PARAMETERS

        -- number of inputs of the first layer
        constant p_NETWORK_INPUTS   : integer                               := 2;               

        -- number of layers inside the network
        constant p_NETWORK_LAYERS   : integer                               := 5;               

        -- nb of neurons (=outputs) of each layer
        constant p_NETWORK_NEURONS  : t_neurons(0 to p_NETWORK_LAYERS - 1)  := (4, 3, 2, 4, 4);

        -- must be equal to the number of neurons of the last layer
        constant p_NETWORK_OUTPUTS  : integer                               := 4;               
            
end package;
 
package body parameters is
end package body;

