library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity design_tb is
end design_tb;

architecture behav of design_tb is

    -- definition de la classe design_1
    component design_1 is
        port (
            clk         : in std_logic;
            rst         : in std_logic
        );
    end component design_1;

    signal  rst         : std_logic;
    signal  clk         : std_logic;

begin

    -- instanciation de l'objet design_1_i de la classe design_1
    design_1_i: component design_1
        port map (
            clk         => clk,
            rst         => rst
        );

    clock : process begin 

        clk <= '0'; wait for 5 ns;
        clk <= '1'; wait for 5 ns;

    end process;
    
    reset : process begin

        rst <= '0'; wait for 100 ns;
        rst <= '1'; wait;
  
    end process;

    simulation : process begin
        wait;
    end process;

end behav;
