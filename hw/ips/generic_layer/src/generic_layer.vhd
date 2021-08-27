-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------

entity generic_layer is 
    generic (
        G_NB_INPUTS     : integer   := 2; 
        G_NB_WEIGHTS    : integer   := 4;
        G_DATA_WIDTH    : integer   := 8
    );

    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
        inputs          : in  std_logic_vector( (G_NB_INPUTS  * G_DATA_WIDTH) - 1 downto 0);
        outputs         : out std_logic_vector( (G_NB_WEIGHTS * G_DATA_WIDTH) - 1 downto 0) 
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is
    
    type t_parameters is array (0 to G_NB_WEIGHTS-1) of std_logic_vector(G_DATA_WIDTH-1 downto 0);

    signal weights      : t_parameters      := (others => (others => '0')); 
    signal offsets      : t_parameters      := (others => (others => '0')); 
    signal inputs_sum   : integer           := 0; 

begin

    process(clk) begin

        if (rstn = '0') then

            weights         <= (others => (others => '0') );

        elsif rising_edge(clk) then

            -- inputs_sum = i(0) + i(1) + ... + i(n-1)
            adding_inputs : for i in 0 to G_NB_INPUTS loop
                inputs_sum      <= 
                                inputs_sum + 
                                to_integer( unsigned( inputs(((i*G_DATA_WIDTH)+G_DATA_WIDTH-1) downto i*G_DATA_WIDTH))); 
            end loop;

            -- outputs[i] = weights[i] * inputs_sum + NB_WEIGHTS * offsets[i]
            processing_outputs : for i in 0 to G_NB_WEIGHTS-1 loop

               outputs          <= std_logic_vector(to_unsigned(
                                to_integer(unsigned(weights(i))) * inputs_sum + 
                                (G_NB_WEIGHTS * to_integer(unsigned(offsets(i))))
                                , G_DATA_WIDTH));

            end loop;

        end if;

    end process; 

end architecture;

