library ieee;
use ieee.std_logic_1164.all;

library work;
use work.parameters.all;

entity generic_layer_tb is 

    generic (
        g_NB_INPUTS         : integer := 2;
        g_NB_WEIGHTS        : integer := 2
    );

end entity;

architecture behavior of generic_layer_tb is 

    constant CLOCK_PERIOD_2     : time := 5 ns;
    constant CLOCK_PERIOD       : time := 2 * CLOCK_PERIOD_2;

    signal clk                  : std_logic;
    signal rstn                 : std_logic;
    signal inputs               : std_logic_vector(g_NB_INPUTS  * p_DATA_WIDTH - 1 downto 0)   := (others => '0');
    signal outputs              : std_logic_vector(g_NB_WEIGHTS * p_DATA_WIDTH - 1 downto 0)   := (others => '0'); 
    signal s_axi_cfg_awaddr     : std_logic_vector(31 downto 0);
    signal s_axi_cfg_awprot     : std_logic_vector(2 downto 0);
    signal s_axi_cfg_awvalid    : std_logic;
    signal s_axi_cfg_awready    : std_logic;
    signal s_axi_cfg_wdata      : std_logic_vector(p_DATA_WIDTH - 1 downto 0);
    signal s_axi_cfg_wstrb      : std_logic_vector((p_DATA_WIDTH / 8) - 1 downto 0);
    signal s_axi_cfg_wvalid     : std_logic;
    signal s_axi_cfg_wready     : std_logic;
    signal s_axi_cfg_bresp      : std_logic_vector(1 downto 0);     
    signal s_axi_cfg_bvalid     : std_logic;
    signal s_axi_cfg_bready     : std_logic;

begin

    generic_layer : entity work.generic_layer 

        generic map ( 
            g_NB_INPUTS         => g_NB_INPUTS       ,
            g_NB_WEIGHTS        => g_NB_WEIGHTS 
        )

        port map    ( 
            clk                 => clk               ,
            rstn                => rstn              ,
            inputs              => inputs            ,
            outputs             => outputs           ,
            s_axi_cfg_awaddr    => s_axi_cfg_awaddr  ,
            s_axi_cfg_awprot    => s_axi_cfg_awprot  ,
            s_axi_cfg_awvalid   => s_axi_cfg_awvalid ,
            s_axi_cfg_awready   => s_axi_cfg_awready ,
            s_axi_cfg_wdata     => s_axi_cfg_wdata   ,
            s_axi_cfg_wstrb     => s_axi_cfg_wstrb   ,
            s_axi_cfg_wvalid    => s_axi_cfg_wvalid  ,
            s_axi_cfg_wready    => s_axi_cfg_wready  ,
            s_axi_cfg_bresp     => s_axi_cfg_bresp   ,
            s_axi_cfg_bvalid    => s_axi_cfg_bvalid  ,
            s_axi_cfg_bready    => s_axi_cfg_bready  
        );

        inputs      <= (15      => '1',         -- first signed  = -64
                        14      => '1',         -- 
                        1       => '1',         -- second signed = 2
                        others  => '0');

        ---------------------

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

