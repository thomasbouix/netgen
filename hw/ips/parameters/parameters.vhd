-- HDL parameters shared by all IPs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    -- NETWORK DATA WIDTH
    constant p_DATA_WIDTH       : integer := 64;

    -- TYPES
    subtype t_data                is signed(p_DATA_WIDTH - 1 downto 0);         -- atomic data element
    type    t_data_array          is array (integer range <>) of T_DATA;        -- array of data for IP's interal registers
    type    t_int_array           is array (integer range <>) of integer;       -- array of integers 

    -- NETWORK PARAMETERS

        -- number of inputs of the first layer
        constant p_NETWORK_INPUTS   : integer                                   := 2;               

        -- number of layers inside the network
        constant p_NETWORK_LAYERS   : integer                                   := 5;               

        -- nb of weights of each layer
        constant p_NETWORK_WEIGHTS  : t_int_array(0 to p_NETWORK_LAYERS - 1)    := (4, 3, 2, 4, 4);

        -- must be equal to the number of weights of the last layer
        constant p_NETWORK_OUTPUTS  : integer                                   := 4;               
            
        -- vivado does not support this 
        -- constant p_NETWORK_OUTPUTS  : integer := (p_NETWORK_WEIGHTS(p_NETWORK_LAYERS - 1));         

end package;
 
package body parameters is
end package body;

