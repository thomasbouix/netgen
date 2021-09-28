library ieee;
use ieee.std_logic_1164.all;

library work;
use work.parameters.all;

entity generic_layer_tb is 

    generic (
        g_NB_INPUTS         : integer := 2;
        g_NB_OUTPUTS        : integer := 4
    );

end entity;

architecture behavior of generic_layer_tb is 

    constant CLOCK_PERIOD_2 : time := 5 ns;
    constant CLOCK_PERIOD   : time := 2 * CLOCK_PERIOD_2;

    signal clk              : std_logic;
    signal rstn             : std_logic;
    signal inputs           : std_logic_vector(g_NB_INPUTS  * p_DATA_WIDTH - 1 downto 0)   := (others => '0');
    signal outputs          : std_logic_vector(g_NB_OUTPUTS * p_DATA_WIDTH - 1 downto 0)   := (others => '0'); 
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

begin

    generic_layer : entity work.generic_layer 

        generic map ( 
            g_NB_INPUTS     => g_NB_INPUTS       ,
            g_NB_OUTPUTS    => g_NB_OUTPUTS 
        )

        port map    ( 
            clk             => clk               ,
            rstn            => rstn              ,
            inputs          => inputs            ,
            outputs         => outputs           ,
            s_axi_awaddr    => s_axi_awaddr  ,
            s_axi_awprot    => s_axi_awprot  ,
            s_axi_awvalid   => s_axi_awvalid ,
            s_axi_awready   => s_axi_awready ,
            s_axi_wdata     => s_axi_wdata   ,
            s_axi_wstrb     => s_axi_wstrb   ,
            s_axi_wvalid    => s_axi_wvalid  ,
            s_axi_wready    => s_axi_wready  ,
            s_axi_bresp     => s_axi_bresp   ,
            s_axi_bvalid    => s_axi_bvalid  ,
            s_axi_bready    => s_axi_bready  
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

