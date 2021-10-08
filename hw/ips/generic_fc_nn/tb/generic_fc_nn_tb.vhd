-- this testbench must be executed with the following parameters :
-- data_width   : 8
-- nb_inputs    : 2
-- neurons      : (4, 3, 2, 4, 4) 
-- nb_outputs   : 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.parameters.all;

entity generic_fc_nn_tb is 
end entity;

architecture behavior of generic_fc_nn_tb is 

    constant CLOCK_PERIOD   : time := 10 ns;

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
    signal s_axis_tdata     : std_logic_vector(p_DATA_WIDTH * p_NETWORK_INPUTS - 1 downto 0);       
    signal s_axis_tready    : std_logic;

    signal m_axis_tvalid    : std_logic;
    signal m_axis_tlast     : std_logic;
    signal m_axis_tdata     : std_logic_vector(p_DATA_WIDTH * p_NETWORK_OUTPUTS - 1 downto 0);     
    signal m_axis_tready    : std_logic;

begin

    generic_fc_nn : entity work.generic_fc_nn 

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

        p_clock : process begin
            clk     <= '0'; wait for CLOCK_PERIOD / 2;
            clk     <= '1'; wait for CLOCK_PERIOD / 2;
        end process;     

        p_reset : process begin
            rstn    <= '0'; wait for 5 * CLOCK_PERIOD;
            rstn    <= '1'; wait;
        end process;

        p_input_data : process begin
            wait until rstn = '1';
            wait;
        end process;

        p_test_bench : process begin

            report "-------------------------------------------";
            report "Data Width           => 8 bits";
            report "Network architecture => 2 : (4 3 2 4 4) : 4";
            report "-------------------------------------------";

            -- configuration
            s_axi_awaddr            <= (others => '0');
            s_axi_awprot            <= "000";
            s_axi_awvalid           <= '0';
            s_axi_wdata             <= (others => '0');
            s_axi_wstrb             <= "0"; 
            s_axi_wvalid            <= '0'; 
            s_axi_bready            <= '0'; 

            -------------------------------------------------------------------------------

            report "[0] Settings inputs = (1, 0)";
            report "--";

            s_axis_tdata            <= (8 => '1', 0 => '0', others  => '0'); 
            s_axis_tvalid           <= '1';

            wait until rstn = '1';
            wait for 10*CLOCK_PERIOD;
            report "[0] Testing outputs";
            assert m_axis_tdata = X"6060_6060" report "[0] Output error";  

            -------------------------------------------------------------------------------

            report "[1] Settings L0.W00 = 2";
            report "--";

            s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_0000#, 32));
            s_axi_awvalid           <= '1';
            s_axi_wdata             <= "00000010";
            s_axi_wvalid            <= '1';

            wait on s_axi_awready, s_axi_wready;

            if s_axi_awready = '1' and s_axi_wready = '1' then 
                s_axi_awvalid       <= '0';
                s_axi_wvalid        <= '0';
            elsif s_axi_awready = '1' then
                s_axi_awvalid       <= '0';
                wait on s_axi_wready;
                s_axi_wvalid        <= '0';
            elsif s_axi_wready = '1' then
                s_axi_wvalid        <= '0';
                wait on s_axi_awready;
                s_axi_awvalid       <= '0';
            end if;

            wait on s_axi_bvalid;

            if s_axi_bvalid = '1' then 
                s_axi_bready <= '1';
                wait for 2 * CLOCK_PERIOD;
                s_axi_bready <= '0';
            end if;

            wait for 10*CLOCK_PERIOD;
            report "[1] Testing outputs";
            assert m_axis_tdata = X"7878_7878" report "[1] Output error";  

            -------------------------------------------------------------------------------

            report "[2] Settings L0.B3  = -1";
            report "--";

            s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_000B#, 32));
            s_axi_awvalid           <= '1';
            s_axi_wdata             <= X"FF";
            s_axi_wvalid            <= '1';

            wait on s_axi_awready, s_axi_wready;

            if s_axi_awready = '1' and s_axi_wready = '1' then 
                s_axi_awvalid       <= '0';
                s_axi_wvalid        <= '0';
            elsif s_axi_awready = '1' then
                s_axi_awvalid       <= '0';
                wait on s_axi_wready;
                s_axi_wvalid        <= '0';
            elsif s_axi_wready = '1' then
                s_axi_wvalid        <= '0';
                wait on s_axi_awready;
                s_axi_awvalid       <= '0';
            end if;

            wait on s_axi_bvalid;

            if s_axi_bvalid = '1' then 
                s_axi_bready <= '1';
                wait for 2 * CLOCK_PERIOD;
                s_axi_bready <= '0';
            end if;

            wait for 10*CLOCK_PERIOD;
            report "[2] Testing outputs";
            assert m_axis_tdata = X"6060_6060" report "[2] Output error";  

            -------------------------------------------------------------------------------

            report "[3] Settings L1.W01 = -1";
            report "--";

            s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_000D#, 32));
            s_axi_awvalid           <= '1';
            s_axi_wdata             <= X"FF";
            s_axi_wvalid            <= '1';

            wait on s_axi_awready, s_axi_wready;

            if s_axi_awready = '1' and s_axi_wready = '1' then 
                s_axi_awvalid       <= '0';
                s_axi_wvalid        <= '0';
            elsif s_axi_awready = '1' then
                s_axi_awvalid       <= '0';
                wait on s_axi_wready;
                s_axi_wvalid        <= '0';
            elsif s_axi_wready = '1' then
                s_axi_wvalid        <= '0';
                wait on s_axi_awready;
                s_axi_awvalid       <= '0';
            end if;

            wait on s_axi_bvalid;

            if s_axi_bvalid = '1' then 
                s_axi_bready <= '1';
                wait for 2 * CLOCK_PERIOD;
                s_axi_bready <= '0';
            end if;

            wait for 10*CLOCK_PERIOD;
            report "[3] Testing outputs";
            assert m_axis_tdata = X"5050_5050" report "[3] Output error";  

            -------------------------------------------------------------------------------

            report "[4] Settings L4.B3  = -10";
            report "--";

            s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_0042#, 32));
            s_axi_awvalid           <= '1';
            s_axi_wdata             <= X"F6";
            s_axi_wvalid            <= '1';

            wait on s_axi_awready, s_axi_wready;

            if s_axi_awready = '1' and s_axi_wready = '1' then 
                s_axi_awvalid       <= '0';
                s_axi_wvalid        <= '0';
            elsif s_axi_awready = '1' then
                s_axi_awvalid       <= '0';
                wait on s_axi_wready;
                s_axi_wvalid        <= '0';
            elsif s_axi_wready = '1' then
                s_axi_wvalid        <= '0';
                wait on s_axi_awready;
                s_axi_awvalid       <= '0';
            end if;

            wait on s_axi_bvalid;

            if s_axi_bvalid = '1' then 
                s_axi_bready <= '1';
                wait for 2 * CLOCK_PERIOD;
                s_axi_bready <= '0';
            end if;

            wait for 10*CLOCK_PERIOD;
            report "[4] Testing outputs";
            assert m_axis_tdata = X"5050_5046" report "[4] Output error";  

            report "--";
            wait;

        end process;
    
end architecture;

