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
        ------- axi lite slave configuration interface -----
        ----------------------------------------------------

        s_axi_awaddr        : in  std_logic_vector(31 downto 0);
        s_axi_awprot        : in  std_logic_vector(2 downto 0);
        s_axi_awvalid       : in  std_logic;
        s_axi_awready       : out std_logic;

        s_axi_wdata         : in  std_logic_vector(p_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb         : in  std_logic_vector((p_DATA_WIDTH / 8) - 1 downto 0);
        s_axi_wvalid        : in  std_logic;
        s_axi_wready        : out std_logic;

        s_axi_bresp         : out std_logic_vector(1 downto 0);     
        s_axi_bvalid        : out std_logic;
        s_axi_bready        : in  std_logic
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is

    type T_CFG_SM               is (WAIT_ADDR, WAIT_DATA, WRITE_RESP);                              -- axi state machine type

    signal r_cfg_sm             : T_CFG_SM                                  := WAIT_ADDR;
    signal weights              : t_int_array(0 to g_NB_OUTPUTS)            := (others => 1);       -- weights[i] = 1
    signal offsets              : t_int_array(0 to g_NB_OUTPUTS)            := (others => 0);       -- offsets[i] = 0

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
            r_inputs(i)     <= signed(inputs(p_DATA_WIDTH * (g_NB_INPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_INPUTS - i - 1)));
        end loop;


        for i in 0 to g_NB_OUTPUTS - 1 loop
            outputs(p_DATA_WIDTH * (g_NB_OUTPUTS - i) - 1 downto p_DATA_WIDTH * (g_NB_OUTPUTS - i - 1))   <= std_logic_vector(r_outputs(i));
        end loop;

    end process;

    -- the configuration interface is write only : there are no read channels
    p_configuration : process(clk) is

        variable v_write_addr       : integer   :=  0 ;                   
        variable v_weight_addr      : std_logic := '0';     -- the configuration addr is a weight addr
        variable v_offset_addr      : std_logic := '0';     -- the configuration addr is an offset addr

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                v_write_addr    :=  0 ;
                v_weight_addr   := '0';
                v_offset_addr   := '0';

                s_axi_awready   <= '0';
                s_axi_wready    <= '0';
                s_axi_bvalid    <= '0';
                s_axi_bresp     <= "00";

                weights         <= (others => 2);
                offsets         <= (others => 1);
                r_cfg_sm        <= WAIT_ADDR;

            else 
                
                case r_cfg_sm is 

                    when WAIT_ADDR =>

                        v_write_addr            :=  0 ;
                        v_weight_addr           := '0';
                        v_offset_addr           := '0';

                        if s_axi_awvalid = '1' then                  

                            v_write_addr        := to_integer(unsigned(s_axi_awaddr));

                            if  v_write_addr >= c_WEIGHTS_MEM_BASE and v_write_addr <= c_WEIGHTS_MEM_END then       -- configuring a weight
                                v_weight_addr   := '1';
                                s_axi_awready   <= '1';
                                r_cfg_sm        <= WAIT_DATA;

                            elsif v_write_addr >= c_OFFSETS_MEM_BASE and v_write_addr <= c_OFFSETS_MEM_END then     -- configuring an offset
                                v_offset_addr   := '1';
                                s_axi_awready   <= '1';
                                r_cfg_sm        <= WAIT_DATA;

                            else                                                                                    -- cfg addr is not in the ip address space
                                r_cfg_sm        <= WAIT_ADDR;
                            end if;


                        end if;

                    when WAIT_DATA =>

                        s_axi_awready                   <= '0';
                        
                        if s_axi_wvalid = '1' then

                            if v_weight_addr = '1' then
                               weights(v_write_addr)    <= to_integer(signed(s_axi_wdata)); 

                            elsif v_offset_addr = '1' then
                               offsets(v_write_addr)    <= to_integer(signed(s_axi_wdata)); 
                            end if;

                            s_axi_wready                <= '1';
                            r_cfg_sm                    <= WRITE_RESP;
                        end if;

                    when WRITE_RESP =>

                        s_axi_wready                <= '0';
                        s_axi_bvalid                <= '1';
                        s_axi_bresp                 <= "00";

                        if s_axi_bready = '1' then
                            s_axi_bvalid            <= '0';
                            r_cfg_sm                <= WAIT_ADDR;
                        end if;

                end case;
            end if;
        end if;
    end process; 


    p_r_outputs : process(clk) is
   
        variable v_inputs_sum    : integer   :=  0 ;    -- sum of all inputs
    
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
                    r_outputs(i)    <= to_signed( weights(i)*v_inputs_sum + (g_NB_INPUTS * offsets(i)) , p_DATA_WIDTH );
                end loop;

            end if;
        end if;
    end process;

end architecture;

