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
        g_NETWORK_INPUTS        : integer := 2;     -- number of inputs of the first layer
        g_NETWORK_OUTPUTS       : integer := 4;     -- number of outputs of the last layer
        g_NETWORK_HEIGHT        : integer := 3;     -- number of inputs / outputs of middle layers
        g_NETWORK_LAYERS        : integer := 5      -- number of layers inside the network
    );

    port(
        clk                     : in  std_logic;
        rstn                    : in  std_logic;

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

architecture rtl of generic_fc_nn is

    -- generic_layer class header
    component generic_layer

        generic (
            g_NB_INPUTS         : integer;
            g_NB_WEIGHTS        : integer;
            g_MEM_BASE          : integer
       );

        port (
            clk                 : in  std_logic;
            rstn                : in  std_logic;

            inputs              : in  t_data_array(0 to g_NB_INPUTS  - 1);
            outputs             : out t_data_array(0 to g_NB_WEIGHTS - 1);

            s_axi_cfg_awaddr    : in  std_logic_vector(31 downto 0);
            s_axi_cfg_awprot    : in  std_logic_vector(2 downto 0);
            s_axi_cfg_awvalid   : in  std_logic;
            s_axi_cfg_awready   : out std_logic;

            s_axi_cfg_wdata     : in  std_logic_vector(p_DATA_WIDTH - 1 downto 0);
            s_axi_cfg_wstrb     : in  std_logic_vector((p_DATA_WIDTH / 8) - 1 downto 0);
            s_axi_cfg_wvalid    : in  std_logic;
            s_axi_cfg_wready    : out std_logic;

            s_axi_cfg_bresp     : out std_logic_vector(1 downto 0);     
            s_axi_cfg_bvalid    : out std_logic;
            s_axi_cfg_bready    : in  std_logic
        );

    end component;

    signal network_inputs       : t_data_array(0 to g_NETWORK_INPUTS  - 1)                      := (others => (others => '0'));
    signal network_outputs      : t_data_array(0 to g_NETWORK_OUTPUTS - 1)                      := (others => (others => '0'));
    signal r_layer_connections  : t_data_array(0 to g_NETWORK_LAYERS * g_NETWORK_HEIGHT - 1)    := (others => (others => '0'));

begin

    layers : for i in 0 to g_NETWORK_LAYERS - 1 generate
        
        first_layer : if i = 0 generate

            FL : generic_layer
                generic map (
                    g_NB_INPUTS         => g_NETWORK_INPUTS,
                    g_NB_WEIGHTS        => g_NETWORK_HEIGHT,
                    g_MEM_BASE          => 16#4000_0000#
                )

                port map (
                    clk                 => clk,  
                    rstn                => rstn,
                    inputs              => network_inputs,
                    outputs             => r_layer_connections(0 to g_NETWORK_HEIGHT - 1),
                    s_axi_cfg_awaddr    => s_axi_cfg_awaddr, 
                    s_axi_cfg_awprot    => s_axi_cfg_awprot, 
                    s_axi_cfg_awvalid   => s_axi_cfg_awvalid,
                    s_axi_cfg_awready   => s_axi_cfg_awready,
                    s_axi_cfg_wdata     => s_axi_cfg_wdata,  
                    s_axi_cfg_wstrb     => s_axi_cfg_wstrb,  
                    s_axi_cfg_wvalid    => s_axi_cfg_wvalid, 
                    s_axi_cfg_wready    => s_axi_cfg_wready, 
                    s_axi_cfg_bresp     => s_axi_cfg_bresp,  
                    s_axi_cfg_bvalid    => s_axi_cfg_bvalid, 
                    s_axi_cfg_bready    => s_axi_cfg_bready

                );
        end generate first_layer;

        middle_layers : if i > 0 and i < g_NETWORK_LAYERS - 1 generate

            ML : generic_layer 
                
                generic map (
                    g_NB_INPUTS         => g_NETWORK_HEIGHT,
                    g_NB_WEIGHTS        => g_NETWORK_HEIGHT,
                    g_MEM_BASE          => 16#4000_0000# + i * (g_NETWORK_HEIGHT) * 2
                )

                port map (
                    clk                 => clk,  
                    rstn                => rstn,
                    inputs              => r_layer_connections( g_NETWORK_HEIGHT*(i-1) to g_NETWORK_HEIGHT*(i)   - 1),
                    outputs             => r_layer_connections( g_NETWORK_HEIGHT*(i)   to g_NETWORK_HEIGHT*(i+1) - 1) ,
                    s_axi_cfg_awaddr    => s_axi_cfg_awaddr, 
                    s_axi_cfg_awprot    => s_axi_cfg_awprot, 
                    s_axi_cfg_awvalid   => s_axi_cfg_awvalid,
                    s_axi_cfg_awready   => s_axi_cfg_awready,
                    s_axi_cfg_wdata     => s_axi_cfg_wdata,  
                    s_axi_cfg_wstrb     => s_axi_cfg_wstrb,  
                    s_axi_cfg_wvalid    => s_axi_cfg_wvalid, 
                    s_axi_cfg_wready    => s_axi_cfg_wready, 
                    s_axi_cfg_bresp     => s_axi_cfg_bresp,  
                    s_axi_cfg_bvalid    => s_axi_cfg_bvalid, 
                    s_axi_cfg_bready    => s_axi_cfg_bready
                );
        end generate middle_layers;

        last_layer : if i = g_NETWORK_LAYERS - 1 generate

            LL : generic_layer
                generic map (
                    g_NB_INPUTS         => g_NETWORK_HEIGHT,
                    g_NB_WEIGHTS        => g_NETWORK_OUTPUTS,
                    g_MEM_BASE          => 16#4000_0000# + i * (g_NETWORK_HEIGHT) * 2
                )

                port map (
                    clk                 => clk,  
                    rstn                => rstn,
                    inputs              => r_layer_connections( g_NETWORK_HEIGHT*(i-1) to g_NETWORK_HEIGHT*(i) - 1),
                    outputs             => network_outputs,
                    s_axi_cfg_awaddr    => s_axi_cfg_awaddr, 
                    s_axi_cfg_awprot    => s_axi_cfg_awprot, 
                    s_axi_cfg_awvalid   => s_axi_cfg_awvalid,
                    s_axi_cfg_awready   => s_axi_cfg_awready,
                    s_axi_cfg_wdata     => s_axi_cfg_wdata,  
                    s_axi_cfg_wstrb     => s_axi_cfg_wstrb,  
                    s_axi_cfg_wvalid    => s_axi_cfg_wvalid, 
                    s_axi_cfg_wready    => s_axi_cfg_wready, 
                    s_axi_cfg_bresp     => s_axi_cfg_bresp,  
                    s_axi_cfg_bvalid    => s_axi_cfg_bvalid, 
                    s_axi_cfg_bready    => s_axi_cfg_bready
                );
        end generate last_layer;

    end generate layers;

end architecture;

