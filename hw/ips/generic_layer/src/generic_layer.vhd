-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.netgen_parameters.all;

-----------------------------------

entity generic_layer is 
    generic (
        G_NB_INPUTS     : integer   := 2; 
        G_NB_WEIGHTS    : integer   := 4
    );

    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
        inputs          : in  std_logic_vector( (G_NB_INPUTS  * DATA_WIDTH) - 1 downto 0);
        outputs         : out std_logic_vector( (G_NB_WEIGHTS * DATA_WIDTH) - 1 downto 0) 
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is
    
    type t_parameters is array (0 to G_NB_WEIGHTS-1) of T_DATA;

    signal weights      : t_parameters      := (others => (0 => '1', others => '0'));   -- weights[i] = 1
    signal offsets      : t_parameters      := (others => (0 => '1', others => '0'));   -- offsets[i] = 1
    signal inputs_sum   : integer           := 0; 

begin

    -- res = i(0) + i(1) + ... + i(n-1)
    p_inputs_sum : process(clk) is
   
        variable res    : integer   :=  0 ;
        variable done   : std_logic := '0'; 
    
    begin

        if rstn = '0' then
            res     :=  0 ;
            done    := '0';
            
        elsif rising_edge(clk) then

            if done = '0' then
                done := '1';

                adding_inputs : for i in 0 to G_NB_INPUTS-1 loop
                    res := res + to_integer( signed( inputs(((i*DATA_WIDTH)+DATA_WIDTH-1) downto i*DATA_WIDTH))); 
                end loop;

                inputs_sum <= res;

            end if;
        end if;
    end process;

    p_outputs_computing : process(clk) begin

        if (rstn = '0') then

            weights <= (others => (0 => '1', others => '0') );
            offsets <= (others => (0 => '1', others => '0') );
            outputs <= (others => '0');

        elsif rising_edge(clk) then

            -- outputs[i] = ( weights[i] * inputs_sum ) + ( NB_INPUTS * offsets[i] )
            processing_outputs : for i in 0 to G_NB_WEIGHTS-1 loop

               outputs(i*DATA_WIDTH + DATA_WIDTH - 1 downto i*DATA_WIDTH) <= std_logic_vector(to_signed(
                                                                                        to_integer(weights(i)) * inputs_sum + 
                                                                                        (G_NB_INPUTS * to_integer(signed(offsets(i))))
                                                                             , DATA_WIDTH));
            end loop;

        end if;

    end process; 

end architecture;

