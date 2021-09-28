-- Generic Fully Convolutionnal Neural Network
-- typical structure : 
-- 2 3 3 3 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

entity generic_fc_nn is 

    generic (
        g_NETWORK_INPUTS    : integer := 2;     -- number of inputs of the first layer
        g_NETWORK_OUTPUTS   : integer := 4;     -- number of outputs of the last layer
        g_NETWORK_HEIGHT    : integer := 3;     -- number of inputs / outputs of middle layers
        g_NETWORK_LAYERS    : integer := 5      -- number of layers inside the network
    );

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
        s_axis_tdata        : in  std_logic_vector(p_DATA_WIDTH * g_NETWORK_INPUTS - 1 downto 0);       -- all inputs are sent in one cycle
        s_axis_tready       : out std_logic;

        ----------------------------------------------------
        ------ axi stream slave data out interface ---------
        ----------------------------------------------------
        m_axis_tvalid       : out std_logic;
        m_axis_tlast        : out std_logic;
        m_axis_tdata        : out std_logic_vector(p_DATA_WIDTH * g_NETWORK_OUTPUTS - 1 downto 0);      -- all outputs are sent in one cycle
        m_axis_tready       : in  std_logic 

    );

end entity;

architecture rtl of generic_fc_nn is

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

            inputs              : in  std_logic_vector( g_NB_INPUTS  * p_DATA_WIDTH - 1 downto 0);
            outputs             : out std_logic_vector( g_NB_OUTPUTS * p_DATA_WIDTH - 1 downto 0) := (others => '0');

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

    end component;

    signal r_network_inputs     : std_logic_vector( g_NETWORK_INPUTS  * p_DATA_WIDTH - 1 downto 0)                          := (others => '0');
    signal r_network_outputs    : std_logic_vector( g_NETWORK_OUTPUTS * p_DATA_WIDTH - 1 downto 0)                          := (others => '0');
    signal r_layer_connections  : std_logic_vector( (g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - 1 downto 0)  := (others => '0');

begin

    layers : for i in 0 to g_NETWORK_LAYERS - 1 generate
        
        first_layer : if i = 0 generate

            FL : generic_layer
                generic map (
                    g_NB_INPUTS     => g_NETWORK_INPUTS,
                    g_NB_OUTPUTS    => g_NETWORK_HEIGHT,
                    g_MEM_BASE      => 16#4000_0000#
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,
                    
                    inputs          => r_network_inputs,

                    outputs         => r_layer_connections((g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - 1 downto 
                                                           (g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - p_DATA_WIDTH * g_NETWORK_HEIGHT),

                    s_axi_awaddr    => s_axi_awaddr, 
                    s_axi_awprot    => s_axi_awprot, 
                    s_axi_awvalid   => s_axi_awvalid,
                    s_axi_awready   => s_axi_awready,
                    s_axi_wdata     => s_axi_wdata,  
                    s_axi_wstrb     => s_axi_wstrb,  
                    s_axi_wvalid    => s_axi_wvalid, 
                    s_axi_wready    => s_axi_wready, 
                    s_axi_bresp     => s_axi_bresp,  
                    s_axi_bvalid    => s_axi_bvalid, 
                    s_axi_bready    => s_axi_bready

                );
        end generate first_layer;

        middle_layers : if i > 0 and i < g_NETWORK_LAYERS - 1 generate

            ML : generic_layer 
                
                generic map (
                    g_NB_INPUTS     => g_NETWORK_HEIGHT,
                    g_NB_OUTPUTS    => g_NETWORK_HEIGHT,
                    g_MEM_BASE      => 16#4000_0000# + i * (g_NETWORK_HEIGHT) * 2
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,

                    inputs          => r_layer_connections((g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - 1 - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i-1) downto 
                                                           (g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH     - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i)),

                    outputs         => r_layer_connections((g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - 1 - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i)   downto 
                                                           (g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH     - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i+1)),

                    s_axi_awaddr    => s_axi_awaddr, 
                    s_axi_awprot    => s_axi_awprot, 
                    s_axi_awvalid   => s_axi_awvalid,
                    s_axi_awready   => s_axi_awready,
                    s_axi_wdata     => s_axi_wdata,  
                    s_axi_wstrb     => s_axi_wstrb,  
                    s_axi_wvalid    => s_axi_wvalid, 
                    s_axi_wready    => s_axi_wready, 
                    s_axi_bresp     => s_axi_bresp,  
                    s_axi_bvalid    => s_axi_bvalid, 
                    s_axi_bready    => s_axi_bready
                );
        end generate middle_layers;

        last_layer : if i = g_NETWORK_LAYERS - 1 generate

            LL : generic_layer
                generic map (
                    g_NB_INPUTS     => g_NETWORK_HEIGHT,
                    g_NB_OUTPUTS    => g_NETWORK_OUTPUTS,
                    g_MEM_BASE      => 16#4000_0000# + i * (g_NETWORK_HEIGHT) * 2
                )

                port map (
                    clk             => clk,  
                    rstn            => rstn,

                    inputs          => r_layer_connections((g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH - 1 - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i-1) downto 
                                                           (g_NETWORK_LAYERS - 1) * g_NETWORK_HEIGHT * p_DATA_WIDTH     - p_DATA_WIDTH * g_NETWORK_HEIGHT * (i)),

                    outputs         => r_network_outputs,

                    s_axi_awaddr    => s_axi_awaddr, 
                    s_axi_awprot    => s_axi_awprot, 
                    s_axi_awvalid   => s_axi_awvalid,
                    s_axi_awready   => s_axi_awready,
                    s_axi_wdata     => s_axi_wdata,  
                    s_axi_wstrb     => s_axi_wstrb,  
                    s_axi_wvalid    => s_axi_wvalid, 
                    s_axi_wready    => s_axi_wready, 
                    s_axi_bresp     => s_axi_bresp,  
                    s_axi_bvalid    => s_axi_bvalid, 
                    s_axi_bready    => s_axi_bready
                );
        end generate last_layer;

    end generate layers;

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

