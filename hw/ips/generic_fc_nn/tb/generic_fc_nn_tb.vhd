library ieee;
use ieee.std_logic_1164.all;

library work;
use work.parameters.all;

entity generic_fc_nn_tb is 

    generic (
        g_NETWORK_INPUTS    : integer               := 2;                  -- number of inputs of the first layer
        g_NETWORK_LAYERS    : integer               := 5;                  -- number of layers inside the network
        g_NETWORK_WEIGHTS   : t_int_array(0 to 4)   := (4, 3, 2, 4, 4)     -- number of weights of each layer
    );

end entity;

architecture behavior of generic_fc_nn_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

    signal clk              : std_logic;
    signal rstn             : std_logic;

    signal s_axi_awaddr     : std_logic_vector(31 downto 0);
    signal s_axi_awprot     : std_logic_vector(2 downto 0);
    signal s_axi_awvalid    : std_logic;
    signal s_axi_awready    : std_logic;
    signal s_axi_wdata      : std_logic_vector(p_DATA_WIDTH - 1 downto 0);
    signal s_axi_wstrb      : std_logic_vector((p_DATA_WIDTH / 8) - 1 downto 0);
    signal s_axi_wvalid     : std_logic;
    signal s_axi_wready     : std_logic;
    signal s_axi_bresp      : std_logic_vector(1 downto 0);     
    signal s_axi_bvalid     : std_logic;
    signal s_axi_bready     : std_logic;

    signal s_axis_tvalid    : std_logic;
    signal s_axis_tlast     : std_logic;
    signal s_axis_tdata     : std_logic_vector(p_DATA_WIDTH * g_NETWORK_INPUTS - 1 downto 0);       
    signal s_axis_tready    : std_logic;

    signal m_axis_tvalid    : std_logic;
    signal m_axis_tlast     : std_logic;
    signal m_axis_tdata     : std_logic_vector(p_DATA_WIDTH * p_NETWORK_OUTPUTS - 1 downto 0);     
    signal m_axis_tready    : std_logic;

begin

    generic_fc_nn : entity work.generic_fc_nn 

        generic map ( 
            g_NETWORK_INPUTS    => g_NETWORK_INPUTS ,
            g_NETWORK_WEIGHTS   => g_NETWORK_WEIGHTS,     
            g_NETWORK_LAYERS    => g_NETWORK_LAYERS
        )

        port map    ( 
            clk                 => clk              ,
            rstn                => rstn             ,
            s_axi_awaddr        => s_axi_awaddr     , 
            s_axi_awprot        => s_axi_awprot     , 
            s_axi_awvalid       => s_axi_awvalid    ,
            s_axi_awready       => s_axi_awready    ,
            s_axi_wdata         => s_axi_wdata      ,  
            s_axi_wstrb         => s_axi_wstrb      ,  
            s_axi_wvalid        => s_axi_wvalid     , 
            s_axi_wready        => s_axi_wready     , 
            s_axi_bresp         => s_axi_bresp      ,  
            s_axi_bvalid        => s_axi_bvalid     , 
            s_axi_bready        => s_axi_bready     ,
            s_axis_tvalid       => s_axis_tvalid    ,
            s_axis_tlast        => s_axis_tlast     ,
            s_axis_tdata        => s_axis_tdata     ,
            s_axis_tready       => s_axis_tready    ,
            m_axis_tvalid       => m_axis_tvalid    ,
            m_axis_tlast        => m_axis_tlast     ,
            m_axis_tdata        => m_axis_tdata     ,
            m_axis_tready       => m_axis_tready
        );

        p_reset : process begin

            rstn    <= '0';
            wait for 5 * CLOCK_PERIOD;
            rstn    <= '1';
            wait;

        end process;
   
        p_clock : process begin

            clk     <= '0';
            wait for CLOCK_PERIOD_2;
            clk     <= '1';
            wait for CLOCK_PERIOD_2;

        end process;     
    
end architecture;

