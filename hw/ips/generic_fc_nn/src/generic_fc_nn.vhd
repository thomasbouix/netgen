-- Generic Fully Convolutionnal Neural Network

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
        s_axi_awaddr        : in  std_logic_vector(31 downto 0);        -- constrained by the PS7
        s_axi_awprot        : in  std_logic_vector(2 downto 0);
        s_axi_awvalid       : in  std_logic;
        s_axi_awready       : out std_logic;
        s_axi_wdata         : in  std_logic_vector(63 downto 0);        -- constrained by the PS7
        s_axi_wstrb         : in  std_logic_vector(7 downto 0);         -- constrained by the PS7
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
        s_axis_tdata        : in  std_logic_vector(31 downto 0);        -- constrained by the PS7
        s_axis_tready       : out std_logic;

        ----------------------------------------------------
        ------ axi stream slave data out interface ---------
        ----------------------------------------------------
        m_axis_tvalid       : out std_logic;
        m_axis_tlast        : out std_logic;
        m_axis_tdata        : out std_logic_vector(31 downto 0);        -- constrained by the PS7
        m_axis_tready       : in  std_logic 

    );

end entity;

architecture rtl of generic_fc_nn is

    -- computes the number of internal connexions between all layers
    -- ex : network = 2 -> 3 -> 4 -> 5
    --      number of interconnected neurons = 2 + 3 + 4 = 9
    --      number of connexions = 9 * data_width 
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
    --      ML1.outputs = [FL0.last - 1 downto f_last_output_index(1) ]
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

    -- computes the base addr of the ith layer in the newtork
    pure function f_compute_layer_addr (i : integer) return integer is 
    begin

        if i = 0 then
            return 16#4000_0000#;
        end if;

        if i = 1 then
            return f_compute_layer_addr(0) + p_NETWORK_INPUTS * p_NETWORK_NEURONS(0) + p_NETWORK_NEURONS(0); 
        end if;

        -- base_addr(layer i) = base_addr(layer i-1) + range(layer i-1)
        return f_compute_layer_addr(i-1) + p_NETWORK_NEURONS(i-2) * p_NETWORK_NEURONS(i-1) + p_NETWORK_NEURONS(i-1); 

    end function;
    
    type T_CFG_SM                 is (PROCESSING_DATA, WRITING_RESP);                                   -- axi state machine type
    type T_OUTPUT_SM              is (WAITING_FOR_OUTPUT, WRITING_OUTPUT);                              -- axi state machine type

    constant c_NB_CONNEXIONS    : integer                                                               := f_nb_connexions      ;

    signal r_cfg_sm             : T_CFG_SM                                                              := PROCESSING_DATA      ;
    signal r_output_sm          : T_OUTPUT_SM                                                           := WAITING_FOR_OUTPUT   ;
    signal r_network_inputs     : std_logic_vector(p_NETWORK_INPUTS  * p_DATA_WIDTH - 1 downto 0)       := (others => '0')      ;
    signal r_network_outputs    : std_logic_vector(p_NETWORK_OUTPUTS * p_DATA_WIDTH - 1 downto 0)       := (others => '0')      ;
    signal r_layer_connexions   : std_logic_vector(c_NB_CONNEXIONS -  1                 downto 0)       := (others => '0')      ;
    signal cfg_addr             : std_logic_vector(31 downto 0)                                         := (others => '0')      ;
    signal cfg_data             : std_logic_vector(p_DATA_WIDTH - 1 downto 0)                           := (others => '0')      ;
    signal r_shift              : std_logic_vector(p_NETWORK_NEURONS'length downto 0)                   := (others => '0')      ;
    signal r_tlast_old          : std_logic                                                             := '0'                  ;

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
                            cfg_data                    <= s_axi_wdata(p_DATA_WIDTH - 1 downto 0);
                            
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
    -- the network is receiving 1 input / clock cycle
    -- if it has 3 inputs, it needs 3 clock cycles to get them all
    p_inputs_processing : process(clk) is

        variable i              : integer range 0 to p_NETWORK_INPUTS                           := 0;               -- input index
        variable v_input_buffer : std_logic_vector(p_NETWORK_INPUTS*p_DATA_WIDTH-1 downto 0)    := (others => '0'); -- input construction

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                v_input_buffer          := (others => '0');     -- input construction
                r_network_inputs        <= (others => '0');     -- real network inputs
                s_axis_tready           <= '0';
                i                       :=  0 ;

            else 

                if s_axis_tvalid = '1' then

                    v_input_buffer(p_DATA_WIDTH*(p_NETWORK_INPUTS-i)-1 downto p_DATA_WIDTH*(p_NETWORK_INPUTS-i-1))  
                                            := s_axis_tdata(p_DATA_WIDTH - 1 downto 0);
                    s_axis_tready           <= '1';                    

                    if s_axis_tlast = '1' then                  -- receiving the last input
                        r_network_inputs    <= v_input_buffer;  -- copying input construction buffer to real first layer input
                        i                   :=  0 ;
                    else 
                        i                   := i+1;             -- still receiving inputs : still building input buffer
                    end if;

                else
                    s_axis_tready <= '0';
                end if;

            end if;
        end if;
    end process;

    -- this process tracks the data flowing through the network from input to output
    -- when an input is fully written, a 1 is pushed into the shifting register (represented by and std_logic_vector)
    -- each bit of the register represents a layer in the network
    -- when the 1 reaches the last bit, it means the data is at the end of the network, so we can display the output
    p_data_tracker : process(clk) is 

    begin

        if rising_edge(clk) then

            if rstn = '0' then
    
                r_tlast_old <= '0';

            else 

                r_tlast_old <= s_axis_tlast;

                if r_tlast_old = '0' and s_axis_tlast = '1' then        -- new input detected, adding a 1 to shifting register
                    r_shift(r_shift'left) <= '1';
                else                                                    -- no new input
                    r_shift(r_shift'left) <= '0';
                end if;

                for i in r_shift'left-1 downto 0 loop
                    r_shift(i) <= r_shift(i+1);
                end loop;
            
            end if;
        end if;

    end process;


    -- formatting outputs to m_axis interface
    -- an input has been fully processed when there is a 1 in the last position of the shifting register
    -- does not check if the slave is ready
    p_outputs_processing : process(clk) is

        variable i : integer range 0 to p_NETWORK_OUTPUTS - 1 := 1; -- current output index

    begin

        if rising_edge(clk) then

            if rstn = '0' then

                m_axis_tdata            <= (others => '0');
                m_axis_tvalid           <= '0';
                m_axis_tlast            <= '0';
                i := 1;

            else 

                case r_output_sm is

                    when WAITING_FOR_OUTPUT =>

                        m_axis_tlast            <= '0';
                            
                        -- outputs are ready to be displayed
                        if r_shift(0) = '1' then                
                            -- writing the first output : output(0)
                            m_axis_tdata(p_DATA_WIDTH-1 downto 0) <=
                                r_network_outputs(p_DATA_WIDTH*p_NETWORK_OUTPUTS-1 downto p_DATA_WIDTH*(p_NETWORK_OUTPUTS-1));
                            m_axis_tvalid       <= '1';
                            r_output_sm         <= WRITING_OUTPUT;
                        else
                            m_axis_tvalid       <= '0';
                            r_output_sm         <= WAITING_FOR_OUTPUT;
                        end if;

                    when WRITING_OUTPUT =>

                        m_axis_tvalid           <= '1';
                        -- writing output(i) from 1 to p_NETWORK_OUTPUT - 1
                        m_axis_tdata(p_DATA_WIDTH-1 downto 0) <=
                            r_network_outputs(p_DATA_WIDTH*(p_NETWORK_OUTPUTS-i)-1 downto p_DATA_WIDTH*(p_NETWORK_OUTPUTS-i-1));

                        if i = p_NETWORK_OUTPUTS - 1 then   -- writing the last output
                            m_axis_tlast        <= '1';
                            r_output_sm         <= WAITING_FOR_OUTPUT;
                            i := 0;
                        else                                -- writing a middle output
                            m_axis_tlast        <= '0';
                            r_output_sm         <= WRITING_OUTPUT;
                            i := i+1;
                        end if;

                    when others =>
                        r_output_sm             <= WAITING_FOR_OUTPUT;
                end case;

            end if;
        end if;

    end process;

end architecture;

