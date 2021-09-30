-- HDL parameters shared by all IPs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    constant p_DATA_WIDTH : integer := 64;

    -- atomic data element
    subtype t_data is signed(p_DATA_WIDTH-1 downto 0);

    -- array of data for IPs' IO
    type t_data_array is array (integer range <>) of T_DATA;

    -- array of integer for IPs' registers
    type t_int_array    is array (integer range <>) of integer;

end package;
 
package body parameters is
end package body;

