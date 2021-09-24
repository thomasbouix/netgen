-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

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
        outputs         : out std_logic_vector( (G_NB_WEIGHTS * DATA_WIDTH) - 1 downto 0)   := (others => '0')
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is

    type T_SM           is (ADDING_INPUTS, COMPUTING_OUTPUTS);
    type t_parameters   is array (0 to G_NB_WEIGHTS-1) of T_DATA;

    signal r_sm         : T_SM              := ADDING_INPUTS;
    signal weights      : t_parameters      := (others => (0 => '1', others => '0'));   -- weights[i] = 1
    signal offsets      : t_parameters      := (others => (0 => '1', others => '0'));   -- offsets[i] = 1
    signal inputs_sum   : integer           := 0; 

begin

    -- outputs are computed in two clock cycles to prevent timing errors
    p_outputs : process(clk) is
   
        variable res    : integer   :=  0 ;
    
    begin

        if rising_edge(clk) then
            
            if rstn = '0' then

                res     :=  0 ;

                weights <= (others => (0 => '1', others => '0') );
                offsets <= (others => (0 => '1', others => '0') );
                outputs <= (others => '0');

                r_sm    <= ADDING_INPUTS;

            else 

                case r_sm is

                    when ADDING_INPUTS =>           

                        res     := 0;
                        -- res = i(0) + i(1) + ... + i(n-1)
                        loop_adding_inputs : for i in 0 to G_NB_INPUTS-1 loop
                            res := res + to_integer( signed( inputs(((i*DATA_WIDTH)+DATA_WIDTH-1) downto i*DATA_WIDTH))); 
                        end loop;

                        inputs_sum  <= res;
                        r_sm        <= COMPUTING_OUTPUTS;

                    when COMPUTING_OUTPUTS =>       
                        
                        -- outputs[i] = ( weights[i] * inputs_sum ) + ( NB_INPUTS * offsets[i] )
                        loop_computing_outputs : for i in 0 to G_NB_WEIGHTS-1 loop

                            outputs(i*DATA_WIDTH + DATA_WIDTH - 1 downto i*DATA_WIDTH) <= 
                                std_logic_vector(to_signed(
                                    to_integer(weights(i)) * inputs_sum + (G_NB_INPUTS * to_integer(offsets(i)))
                                , DATA_WIDTH));

                        end loop;

                        r_sm       <= ADDING_INPUTS;

                    when others =>
                        r_sm       <= ADDING_INPUTS;

                end case;
            end if;
        end if;
    end process;

end architecture;

