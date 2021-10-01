-- HDL parameters shared by all IPs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    -- NETWORK DATA WIDTH
    constant p_DATA_WIDTH       : integer                                   := 64;

    -- TYPES
    subtype t_data                is signed(p_DATA_WIDTH - 1 downto 0);                         -- atomic data element
    type    t_data_array          is array (integer range <>) of T_DATA;                        -- array of data for IP's interal registers
    type    t_int_array           is array (integer range <>) of integer;                       -- array of integers 

    -- NETWORK PARAMETERS
    constant p_NETWORK_INPUTS   : integer                                   := 2;               -- number of inputs of the first layer
    constant p_NETWORK_OUTPUTS  : integer                                   := 4;               -- number of outputs of the last layer
    constant p_NETWORK_LAYERS   : integer                                   := 5;               -- number of layers inside the network
    constant p_NETWORK_HEIGHTS  : t_int_array(0 to p_NETWORK_LAYERS - 1)    := (others => 3);   -- height of each layer (=number of weights)

end package;
 
package body parameters is
end package body;

