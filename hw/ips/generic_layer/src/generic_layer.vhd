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

    signal r_weights            : t_int_array(0 to g_NB_OUTPUTS)            := (others => 1);       -- weights[i] = 1
    signal r_offsets            : t_int_array(0 to g_NB_OUTPUTS)            := (others => 0);       -- offsets[i] = 0

    signal r_inputs             : t_data_array(0 to g_NB_INPUTS  - 1);                              -- facilitate I/O manipulation   
    signal r_outputs            : t_data_array(0 to g_NB_OUTPUTS - 1);                              -- facilitate I/O manipulation   

    -- ip address space ( 1 addr / data )
    constant c_WEIGHTS_MEM_BASE : integer                                   := g_MEM_BASE;
    constant c_WEIGHTS_MEM_END  : integer                                   := g_MEM_BASE + g_NB_OUTPUTS;  
    constant c_OFFSETS_MEM_BASE : integer                                   := g_MEM_BASE + g_NB_OUTPUTS + 1;
    constant c_OFFSETS_MEM_END  : integer                                   := g_MEM_BASE + g_NB_OUTPUTS + 1 + g_NB_OUTPUTS;

begin

    -- combinatory process for type conversion
    p_io_conversion : process(inputs, r_outputs) is 
    
    begin

        for i in 0 to g_NB_INPUTS - 1 loop
            r_inputs(i) <= signed(inputs(p_DATA_WIDTH * (g_NB_INPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_INPUTS - i - 1)));
        end loop;


        for i in 0 to g_NB_OUTPUTS - 1 loop
            outputs(p_DATA_WIDTH * (g_NB_OUTPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_OUTPUTS - i - 1)) <= std_logic_vector(r_outputs(i));
        end loop;

    end process;

    -- the configuration interface is write only : there are no read channels
    p_configuration : process(clk) is

        variable v_weight_addr  : std_logic := '0';     -- configuring a weight
        variable v_offset_addr  : std_logic := '0';     -- configuring an offset
        variable v_write_addr   : integer   :=  0 ;     -- configuration addr as an integer

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                v_write_addr    :=  0 ;
                v_weight_addr   := '0';
                v_offset_addr   := '0';

                r_weights       <= (others => 1);
                r_offsets       <= (others => 0);

            else 

                v_write_addr        := to_integer(unsigned(cfg_addr));

                if  v_write_addr >= c_WEIGHTS_MEM_BASE and v_write_addr <= c_WEIGHTS_MEM_END then       -- configuring a weight

                    v_weight_addr   := '1';

                elsif v_write_addr >= c_OFFSETS_MEM_BASE and v_write_addr <= c_OFFSETS_MEM_END then     -- configuring an offset

                    v_offset_addr   := '1';

                end if;

                if v_weight_addr = '1' then

                    r_weights(v_write_addr - g_MEM_BASE)  <= to_integer(signed(cfg_data)); 

                elsif v_offset_addr = '1' then

                    r_offsets(v_write_addr - g_MEM_BASE)  <= to_integer(signed(cfg_data)); 

                end if;

            end if;

        end if;

    end process; 


    p_processing_outputs : process(clk) is
   
        variable v_inputs_sum : integer :=  0 ;    -- sum of all inputs
    
    begin

        if rising_edge(clk) then
            
            if rstn = '0' then

                v_inputs_sum        :=  0 ;
                r_outputs           <= (others => (others => '0'));

            else 

                v_inputs_sum        := 0;

                -- v_inputs_sum = i(0) + i(1) + ... + i(n-1)
                loop_adding_inputs : for i in 0 to g_NB_INPUTS-1 loop           
                    v_inputs_sum    := v_inputs_sum + to_integer( r_inputs(i) );
                end loop;

                -- outputs(i) = weights(i) * inputs_sum + ( nb_inputs * offsets(i) ) 
                loop_computing_outputs : for i in 0 to g_NB_OUTPUTS-1 loop      
                    r_outputs(i)    <= to_signed( r_weights(i) * v_inputs_sum + (g_NB_INPUTS * r_offsets(i)) , p_DATA_WIDTH );
                end loop;

            end if;
        end if;
    end process;

end architecture;

