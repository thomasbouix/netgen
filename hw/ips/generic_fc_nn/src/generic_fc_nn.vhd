-- Generic Fully Convolutionnal Neural Network
-- typical structure : 
-- 2 3 3 3 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

entity generic_fc_nn is 

    port(
        clk                 : in  std_logic;
        rstn                : in  std_logic;

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
        s_axi_bready        : in  std_logic;

        ----------------------------------------------------
        ------ axi stream slave data in interface ----------
        ----------------------------------------------------
        s_axis_tvalid       : in  std_logic;
        s_axis_tlast        : in  std_logic;
        s_axis_tdata        : in  std_logic_vector(p_DATA_WIDTH * p_NETWORK_INPUTS - 1 downto 0);       -- all inputs are sent in one cycle
        s_axis_tready       : out std_logic;

        ----------------------------------------------------
        ------ axi stream slave data out interface ---------
        ----------------------------------------------------
        m_axis_tvalid       : out std_logic;
        m_axis_tlast        : out std_logic;
        m_axis_tdata        : out std_logic_vector(p_DATA_WIDTH * p_NETWORK_OUTPUTS - 1 downto 0);
        m_axis_tready       : in  std_logic 

    );

end entity;

architecture rtl of generic_fc_nn is

    -- computes the number of internal connexions between all layers
    -- ex : network = 2 -> 3 -> 4 -> 5
    -- ex : number of interconnected neurons = 2 + 3 + 4 = 9
    -- ex : number of connexions = 9 * data_width 
    pure function f_nb_connexions return integer is
        variable v_size : integer := 0;
    begin
        for i in 0 to p_NETWORK_LAYERS - 2 loop
            v_size := v_size + p_NETWORK_NEURONS(i) * p_DATA_WIDTH;
        end loop;
        return v_size;
    end function; 

    -- computes the index of the last output connexion of a layer
    -- ex : FL0.outputs = [MAX downto f_last_output_index(0) ]
    -- ex : ML1.outputs = [FL0.last - 1 downto f_last_output_index(1) ]
    pure function f_last_output_index (layer_index : integer) return integer is 
        variable v_output_index : integer := f_nb_connexions - 1;                                       -- max index of r_layer_connexions
    begin
        for i in 0 to layer_index loop
            v_output_index := v_output_index - p_DATA_WIDTH * p_NETWORK_NEURONS(i);
        end loop;
        return v_output_index + 1;
    end function;

    -- computes the index of the first input connexion of a layer
    -- ex : ML1.inputs = [f_first_input_index(i) downto f_last_output_index(1) ]
    -- cannot be used for the first layer FL0
    pure function f_first_input_index (layer_index : integer range 1 to p_NETWORK_LAYERS - 1) 
    return integer is 
        variable v_input_index : integer := f_nb_connexions - 1;                                        -- max index of r_layer_connexions
    begin
        if layer_index = 1 then                                                                         
            return v_input_index;
        else
            for i in 2 to layer_index loop
                v_input_index := v_input_index - p_DATA_WIDTH * p_NETWORK_NEURONS(i-2);
            end loop;
        end if;
        return v_input_index;
    end function;

    -- computes the base addr of a layer in the newtork
    pure function f_compute_layer_addr (index : integer) return integer is 
        variable v_addr : integer := 16#4000_0000#;
    begin

        if index = 0 then
            return v_addr;
        end if;

        for i in 1 to index loop
            -- base_addr(layer i) = base_addr(layer i-1) + range(layer i-1)
            -- range(layer) := nb_weights = nb_inputs * nb_outputs             + nb_bias = nb_outputs
            v_addr := v_addr + p_NETWORK_NEURONS(i-1) * p_NETWORK_NEURONS(i-1) + p_NETWORK_NEURONS(i-1);    
        end loop;
        return v_addr;
    end function;
    
    type T_CFG_SM                 is (PROCESSING_DATA, WRITING_RESP);                                   -- axi state machine type

    constant c_NB_CONNEXIONS    : integer                                                               := f_nb_connexions;

    signal r_cfg_sm             : T_CFG_SM                                                              := PROCESSING_DATA;
    signal r_network_inputs     : std_logic_vector(p_NETWORK_INPUTS  * p_DATA_WIDTH - 1 downto 0)       := (others => '0');
    signal r_network_outputs    : std_logic_vector(p_NETWORK_OUTPUTS * p_DATA_WIDTH - 1 downto 0)       := (others => '0');
    signal r_layer_connexions   : std_logic_vector(c_NB_CONNEXIONS -  1                 downto 0)       := (others => '0');
    signal cfg_addr             : std_logic_vector(31 downto 0)                                         := (others => '0');
    signal cfg_data             : std_logic_vector(p_DATA_WIDTH - 1 downto 0)                           := (others => '0');

    -- generic_layer class header
    component generic_layer

        generic (
            g_NB_INPUTS         : integer;
            g_NB_OUTPUTS        : integer;
            g_MEM_BASE          : integer
       );

        port (
            clk                 : in  std_logic;
            rstn                : in  std_logic;
            inputs              : in  std_logic_vector(g_NB_INPUTS  * p_DATA_WIDTH - 1 downto 0);
            outputs             : out std_logic_vector(g_NB_OUTPUTS * p_DATA_WIDTH - 1 downto 0);
            cfg_addr            : in  std_logic_vector(31 downto 0);
            cfg_data            : in  std_logic_vector(p_DATA_WIDTH - 1 downto 0)
        );

    end component;

begin

    layers : for i in 0 to p_NETWORK_LAYERS - 1 generate
        
        first_layer : if i = 0 generate

            FL : generic_layer
                generic map (
                    g_NB_INPUTS     => p_NETWORK_INPUTS,
                    g_NB_OUTPUTS    => p_NETWORK_NEURONS(0),
                    g_MEM_BASE      => f_compute_layer_addr(0)
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,
                    
                    inputs          => r_network_inputs,
                    outputs         => r_layer_connexions(c_NB_CONNEXIONS - 1 downto f_last_output_index(0)),

                    cfg_addr        => cfg_addr,
                    cfg_data        => cfg_data
                );
        end generate first_layer;

        middle_layers : if i > 0 and i < p_NETWORK_LAYERS - 1 generate

            ML : generic_layer 
                
                generic map (
                    g_NB_INPUTS     => p_NETWORK_NEURONS(i-1),
                    g_NB_OUTPUTS    => p_NETWORK_NEURONS(i),
                    g_MEM_BASE      => f_compute_layer_addr(i)
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,

                    inputs          => r_layer_connexions(f_first_input_index(i)   downto f_last_output_index(i-1)),        
                    outputs         => r_layer_connexions(f_first_input_index(i+1) downto f_last_output_index(i)),          
                    
                    cfg_addr        => cfg_addr,
                    cfg_data        => cfg_data
                );
        end generate middle_layers;

        last_layer : if i = p_NETWORK_LAYERS - 1 generate

            LL : generic_layer
                generic map (
                    g_NB_INPUTS     => p_NETWORK_NEURONS(p_NETWORK_LAYERS - 2),
                    g_NB_OUTPUTS    => p_NETWORK_OUTPUTS,
                    g_MEM_BASE      => f_compute_layer_addr(i)
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,

                    inputs          => r_layer_connexions(f_first_input_index(i) downto f_last_output_index(i-1)),        
                    outputs         => r_network_outputs,

                    cfg_addr        => cfg_addr,
                    cfg_data        => cfg_data
                );
        end generate last_layer;

    end generate layers;

    -- process transfering axi signals to shared configuration bus
    -- the axi lite configuration interface is write only : there are no read channels
    p_configuration : process(clk) is

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                s_axi_awready   <= '0';
                s_axi_wready    <= '0';
                s_axi_bvalid    <= '0';
                s_axi_bresp     <= "00";

                r_cfg_sm        <= PROCESSING_DATA;

            else 
                
                case r_cfg_sm is 

                    when PROCESSING_DATA =>

                        if s_axi_awvalid = '1' and s_axi_wvalid = '1' then

                            cfg_addr                    <= s_axi_awaddr;
                            cfg_data                    <= s_axi_wdata;
                            
                            s_axi_awready               <= '1';
                            s_axi_wready                <= '1';
                            r_cfg_sm                    <= WRITING_RESP;

                        end if;

                    when WRITING_RESP =>

                        s_axi_awready                   <= '0';
                        s_axi_wready                    <= '0';
                        s_axi_bvalid                    <= '1';
                        s_axi_bresp                     <= "00";

                        if s_axi_bready = '1' then
                            s_axi_bvalid                <= '0';
                            r_cfg_sm                    <= PROCESSING_DATA;
                        end if;

                end case;
            end if;
        end if;
    end process; 

    -- receiving inputs through s_axis interface
    p_inputs_processing : process(clk) is

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                r_network_inputs        <= (others => '0');
                s_axis_tready           <= '0';

            else 

                if s_axis_tvalid = '1' then
                    r_network_inputs    <= s_axis_tdata;
                    s_axis_tready       <= '1';                    
                else
                    s_axis_tready       <= '0';
                end if;

            end if;
        end if;
    end process;

    -- formatting outputs to m_axis interface
    -- TO DO : IS THE SLAVE IS READY ?
    p_outputs_processing : process(clk) is

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                m_axis_tdata            <= (others => '0');
                m_axis_tvalid           <= '0';
                m_axis_tlast            <= '0';

            else 

                m_axis_tvalid           <= '1';
                m_axis_tlast            <= '0';
                m_axis_tdata            <= r_network_outputs;

            end if;
        end if;


    end process;

end architecture;

