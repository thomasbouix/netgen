library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parameters is

    constant DATA_WIDTH : integer := 8;
    subtype t_data is signed(DATA_WIDTH-1 downto 0);

end package;
 
package body parameters is
end package body;

