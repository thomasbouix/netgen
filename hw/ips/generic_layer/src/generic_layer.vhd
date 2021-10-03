-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

-----------------------------------

entity generic_layer is 

    generic (
        g_NB_INPUTS         : integer       := 2; 
        g_NB_OUTPUTS        : integer       := 4;
        g_MEM_BASE          : integer       := 16#4000_0000#
    );

    port(
        clk                 : in  std_logic;
        rstn                : in  std_logic;

        ----------------------------------------------------
        ------------------- layer I/O ----------------------
        ----------------------------------------------------
        inputs              : in  std_logic_vector( g_NB_INPUTS  * p_DATA_WIDTH - 1 downto 0);
        outputs             : out std_logic_vector( g_NB_OUTPUTS * p_DATA_WIDTH - 1 downto 0) := (others => '0');

        ----------------------------------------------------
        ------------ configuration interface ---------------
        ----------------------------------------------------
        cfg_addr            : in  std_logic_vector(31 downto 0);
        cfg_data            : in  std_logic_vector(p_DATA_WIDTH - 1 downto 0)

    );

end entity;

-----------------------------------

architecture rtl of generic_layer is

    signal r_weights    : t_weights(0 to g_NB_OUTPUTS - 1, 0 to g_NB_INPUTS - 1)    := (others => (others => 1));   -- weights[i][j] = 1
    signal r_bias       : t_bias   (0 to g_NB_OUTPUTS - 1)                          := (others => 0);               -- bias[i] = 0

    signal r_inputs     : t_int_array(0 to g_NB_INPUTS  - 1);                                                       -- facilitates I/O manipulation   
    signal r_outputs    : t_int_array(0 to g_NB_OUTPUTS - 1)                        := (others => 0);               -- facilitates I/O manipulation   

    -- ip address space ( 1 addr / data )
    constant c_WEIGHTS_MEM_BASE : integer   := g_MEM_BASE;
    constant c_WEIGHTS_MEM_END  : integer   := g_MEM_BASE + g_NB_INPUTS * g_NB_OUTPUTS - 1;  
    constant c_BIAS_MEM_BASE    : integer   := g_MEM_BASE + g_NB_INPUTS * g_NB_OUTPUTS;
    constant c_BIAS_MEM_END     : integer   := g_MEM_BASE + g_NB_INPUTS * g_NB_OUTPUTS + g_NB_OUTPUTS - 1;

begin

    -- combinatory process for I/O type conversion
    p_io_conversion : process(inputs, r_outputs) is 
    
    begin

        for i in 0 to g_NB_INPUTS - 1 loop
            r_inputs(i) <= to_integer(signed(inputs(p_DATA_WIDTH * (g_NB_INPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_INPUTS - i - 1))));
        end loop;


        for i in 0 to g_NB_OUTPUTS - 1 loop
            outputs(p_DATA_WIDTH * (g_NB_OUTPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_OUTPUTS - i - 1)) <= std_logic_vector(to_signed(r_outputs(i), p_DATA_WIDTH));
        end loop;

    end process;

    -- the configuration interface is write only : there are no read channels
    p_configuration : process(clk) is

        variable v_weight_addr  : std_logic := '0';     -- configuring a weight
        variable v_bias_addr    : std_logic := '0';     -- configuring a bias
        variable v_write_addr   : integer   :=  0 ;     -- configuration addr as an integer
        variable v_weight_i     : integer   :=  0 ;     -- index of weight row 
        variable v_weight_j     : integer   :=  0 ;     -- index of weight column 

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                v_write_addr        :=  0 ;
                v_weight_addr       := '0';
                v_bias_addr         := '0';

                v_weight_i          :=  0;
                v_weight_j          :=  0;

                r_weights           <= ( others => (others => 1));
                r_bias              <= ( others => 0);           

            else 

                v_write_addr        := to_integer(unsigned(cfg_addr));

                if v_write_addr >= c_WEIGHTS_MEM_BASE and v_write_addr <= c_WEIGHTS_MEM_END then        -- configuring a weight
                    v_weight_addr   := '1';

                elsif v_write_addr >= c_BIAS_MEM_BASE and v_write_addr <= c_BIAS_MEM_END then           -- configuring a bias
                    v_bias_addr     := '1';

                end if;

                if v_weight_addr = '1' then
                    v_weight_i                              := (to_integer(signed(cfg_addr)) - g_MEM_BASE) /   g_NB_INPUTS; 
                    v_weight_j                              := (to_integer(signed(cfg_addr)) - g_MEM_BASE) mod g_NB_INPUTS; 
                    r_weights(v_weight_i, v_weight_j)       <=  to_integer(signed(cfg_data)); 

                elsif v_bias_addr = '1' then
                    r_bias(v_write_addr - c_BIAS_MEM_BASE)  <=  to_integer(signed(cfg_data)); 

                end if;

                v_weight_addr       := '0';
                v_bias_addr         := '0';

            end if;

        end if;

    end process; 


    p_processing_outputs : process(clk) is

        variable v_res  : integer := 0;
   
    begin

        if rising_edge(clk) then
            
            if rstn = '0' then

                v_res               := 0;
                r_outputs           <= (others => 0);

            else 

                v_res := 0;

                output_i : for i in 0 to g_NB_OUTPUTS - 1 loop
    
                    v_res           := 0;

                    input_j : for j in 0 to g_NB_INPUTS - 1 loop

                        v_res       := v_res + r_inputs(j) * r_weights(i, j);

                    end loop;

                    v_res           := v_res + r_bias(i);

                    r_outputs(i)    <= to_integer(to_signed( v_res, p_DATA_WIDTH ));

                end loop;

            end if;
        end if;
    end process;

end architecture;

