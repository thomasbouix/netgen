-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

-----------------------------------

entity generic_layer is 
    generic (
        g_NB_INPUTS     : integer   := 2; 
        g_NB_WEIGHTS    : integer   := 4
    );

    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
        inputs          : in  t_data_array(0 to g_NB_INPUTS  - 1); 
        outputs         : out t_data_array(0 to g_NB_WEIGHTS - 1)   := (others => (others => '0'))
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is

    type T_SM           is (ADDING_INPUTS, COMPUTING_OUTPUTS);

    signal r_sm         : T_SM                                  := ADDING_INPUTS;
    signal weights      : t_int_array(0 to g_NB_WEIGHTS)        := (others => 1);       -- weights[i] = 1
    signal offsets      : t_int_array(0 to g_NB_WEIGHTS)        := (others => 1);       -- offsets[i] = 1
    signal inputs_sum   : integer                               := 0;                   -- used to compute the sum of all inputs

begin

    -- outputs are computed in two clock cycles to prevent timing errors
    p_outputs : process(clk) is
   
        variable res    : integer   :=  0 ;
    
    begin

        if rising_edge(clk) then
            
            if rstn = '0' then

                res     :=  0 ;

                weights <= (others => 1);
                offsets <= (others => 1);
                outputs <= (others => (others => '0'));

                r_sm    <= ADDING_INPUTS;

            else 

                case r_sm is

                    when ADDING_INPUTS =>           

                        res             := 0;

                        loop_adding_inputs : for i in 0 to g_NB_INPUTS-1 loop           -- res = i(0) + i(1) + ... + i(n-1)
                            res         := res + to_integer( inputs(i) );
                        end loop;

                        inputs_sum      <= res;
                        r_sm            <= COMPUTING_OUTPUTS;

                    when COMPUTING_OUTPUTS =>       
                        
                        loop_computing_outputs : for i in 0 to g_NB_WEIGHTS-1 loop      
                            outputs(i)  <= to_signed( weights(i)*inputs_sum + (g_NB_INPUTS * offsets(i)) , p_DATA_WIDTH );
                        end loop;

                        r_sm            <= ADDING_INPUTS;

                    when others =>
                        r_sm            <= ADDING_INPUTS;

                end case;
            end if;
        end if;
    end process;

end architecture;

