-- HDL parameters shared by all IPs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    constant p_DATA_WIDTH : integer := 8;

    -- atomic data element
    subtype t_data is signed(p_DATA_WIDTH-1 downto 0);

    -- array of data
    type t_data_array is array (integer range <>) of T_DATA;

end package;
 
package body parameters is
end package body;

