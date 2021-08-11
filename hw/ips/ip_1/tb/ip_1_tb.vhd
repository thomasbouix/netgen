library ieee;
use ieee.std_logic_1164.all;

entity ip_1_tb is 
end entity;

architecture behavior of ip_1_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

begin

    ip_1 : entity work.ip_1 port map (
    );     
    
    clock : process is begin
        i_clk <= '0';
        wait for CLOCK_PERIOD_2;
        i_clk <= '1';
        wait for CLOCK_PERIOD_2;
    end process;

end architecture;

