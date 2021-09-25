-- Generic Layer implementation 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

-----------------------------------

entity generic_layer is 

    generic (
        g_NB_INPUTS             : integer                           := 2; 
        g_NB_WEIGHTS            : integer                           := 4;
        g_BASE_ADDR             : std_logic_vector(31 downto 0)     := X"4000_0000";
        g_END_ADDR              : std_logic_vector(31 downto 0)     := X"7FFF_FFFF"
    );

    port(
        clk                     : in  std_logic;
        rstn                    : in  std_logic;

        ----------------------------------------------------
        ------------------- layer I/O ----------------------
        ----------------------------------------------------

        inputs                  : in  t_data_array(0 to g_NB_INPUTS  - 1); 
        outputs                 : out t_data_array(0 to g_NB_WEIGHTS - 1)   := (others => (others => '0'));

        ----------------------------------------------------
        ------- axi lite slave configuration interface -----
        ----------------------------------------------------

        s_axi_cfg_awaddr        : in  std_logic_vector(31 downto 0);
        s_axi_cfg_awprot        : in  std_logic_vector(2 downto 0);
        s_axi_cfg_awvalid       : in  std_logic;
        s_axi_cfg_awready       : out std_logic;

        s_axi_cfg_wdata         : in  std_logic_vector(p_DATA_WIDTH - 1 downto 0);
        s_axi_cfg_wstrb         : in  std_logic_vector((p_DATA_WIDTH / 8) - 1 downto 0);
        s_axi_cfg_wvalid        : in  std_logic;
        s_axi_cfg_wready        : out std_logic;

        s_axi_cfg_bresp         : out std_logic_vector(1 downto 0);     
        s_axi_cfg_bvalid        : out std_logic;
        s_axi_cfg_bready        : in  std_logic
    );

end entity;

-----------------------------------

architecture rtl of generic_layer is

    type T_CPT_SM       is (ADDING_INPUTS, COMPUTING_OUTPUTS);
    type T_CFG_SM       is (WAIT_ADDR, WAIT_DATA, WRITE_RESP);

    signal r_cpt_sm     : T_CPT_SM                                  := ADDING_INPUTS;
    signal r_cfg_sm     : T_CFG_SM                                  := WAIT_ADDR;
    signal weights      : t_int_array(0 to g_NB_WEIGHTS)            := (others => 1);       -- weights[i] = 1
    signal offsets      : t_int_array(0 to g_NB_WEIGHTS)            := (others => 0);       -- offsets[i] = 0
    signal inputs_sum   : integer                                   := 0;                   -- used to compute the sum of all inputs

begin

    -- the configuration interface is write only
    p_configuration : process(clk) is

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                weights     <= (others => 1);
                offsets     <= (others => 0);
                r_cfg_sm    <= WAIT_ADDR;

            else 
                
                case r_cfg_sm is 

                    when WAIT_ADDR =>

                        if s_axi_cfg_awvalid = '1' then                  

                         -- if s_axi_cfg_awaddr = ... then
                         --     s_axi_cfg_awready   <= '1';
                         --     r_cfg_sm            <= WAIT_DATA;
                         -- end if;

                        end if;

                    when WAIT_DATA =>

                        s_axi_cfg_awready       <= '0';
                        
                        if s_axi_cfg_wvalid = '1' then
                            s_axi_cfg_wready    <= '1';
                         -- weights(addr)       <= data;
                         -- offsets(addr)       <= data;
                            r_cfg_sm            <= WRITE_RESP;
                        end if;

                    when WRITE_RESP =>

                        s_axi_cfg_wready        <= '0';
                        s_axi_cfg_bvalid        <= '1';
                        s_axi_cfg_bresp         <= "00";

                        if s_axi_cfg_bready = '1' then
                            s_axi_cfg_bvalid    <= '0';
                            r_cfg_sm            <= WAIT_ADDR;
                        end if;

                end case;
            end if;
        end if;
    end process; 


    -- outputs are computed in two clock cycles to prevent timing errors
    p_outputs : process(clk) is
   
        variable res    : integer   :=  0 ;
    
    begin

        if rising_edge(clk) then
            
            if rstn = '0' then

                res     :=  0 ;
                outputs <= (others => (others => '0'));
                r_cpt_sm    <= ADDING_INPUTS;

            else 

                case r_cpt_sm is

                    when ADDING_INPUTS =>           

                        res             := 0;

                        loop_adding_inputs : for i in 0 to g_NB_INPUTS-1 loop           -- res = i(0) + i(1) + ... + i(n-1)
                            res         := res + to_integer( inputs(i) );
                        end loop;

                        inputs_sum      <= res;
                        r_cpt_sm            <= COMPUTING_OUTPUTS;

                    when COMPUTING_OUTPUTS =>       
                        
                        loop_computing_outputs : for i in 0 to g_NB_WEIGHTS-1 loop      
                            outputs(i)  <= to_signed( weights(i)*inputs_sum + (g_NB_INPUTS * offsets(i)) , p_DATA_WIDTH );
                        end loop;

                        r_cpt_sm            <= ADDING_INPUTS;

                    when others =>
                        r_cpt_sm            <= ADDING_INPUTS;

                end case;
            end if;
        end if;
    end process;

end architecture;

