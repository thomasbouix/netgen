-- this testbench must be executed with the following parameters :
-- data_width   : 32
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
    signal s_axi_wdata      : std_logic_vector(63 downto 0);
    signal s_axi_wstrb      : std_logic_vector(7 downto 0);
    signal s_axi_wvalid     : std_logic;
    signal s_axi_wready     : std_logic;
    signal s_axi_bresp      : std_logic_vector(1 downto 0);     
    signal s_axi_bvalid     : std_logic;
    signal s_axi_bready     : std_logic;

    signal s_axis_tvalid    : std_logic;
    signal s_axis_tlast     : std_logic;
    signal s_axis_tdata     : std_logic_vector(31 downto 0);       
    signal s_axis_tready    : std_logic;

    signal m_axis_tvalid    : std_logic;
    signal m_axis_tlast     : std_logic;
    signal m_axis_tdata     : std_logic_vector(31 downto 0);     
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

        p_test_bench : process begin

            report "-------------------------------------------";
            report "Data Width           => 31 bits";
            report "Network architecture => 2 : (4 3 2 4 4) : 4";
            report "-------------------------------------------";

            -- configuration
            s_axi_awaddr            <= (others => '0');
            s_axi_awprot            <= "000";
            s_axi_awvalid           <= '0';
            s_axi_wdata             <= (others => '0');
            s_axi_wstrb             <= (others => '0'); 
            s_axi_wvalid            <= '0'; 
            s_axi_bready            <= '0'; 

            -------------------------------------------------------------------------------

            wait until rstn = '1';
            
            report "--";
            report "[0] Settings inputs = (1, 0)";

            report "[0] Setting input(0)";
            wait until rising_edge(clk);
            s_axis_tdata                <= (0 => '1', others => '0');
            s_axis_tvalid               <= '1';
            s_axis_tlast                <= '0';
            wait until s_axis_tready = '1';         -- slave is done with input(0)

            report "[0] Setting input(1)";
            s_axis_tdata                <= (others => '0');
            s_axis_tvalid               <= '1';
            s_axis_tlast                <= '1';
            wait until rising_edge(clk);
            assert s_axis_tready = '1' report "[0] Slave did not see input(1)";

            s_axis_tvalid               <= '0';
            s_axis_tlast                <= '0';

            report "[0] Testing outputs";

            wait until m_axis_tvalid = '1';
            assert m_axis_tdata = X"0000_0060" report "[00] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0060" report "[01] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0060" report "[02] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0060" report "[03] Output error";  

            -------------------------------------------------------------------------------

            report "--";
            report "[1] Settings L0.W00 = 2";

            s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_0000#, 32));
            s_axi_awvalid           <= '1';
            s_axi_wdata(31 downto 0)<= X"0000_0002";
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

            report "[1] Settings inputs = (1, 0)";
            report "[1] Setting input(0)";
            wait until rising_edge(clk);
            s_axis_tdata                <= (0 => '1', others => '0');
            s_axis_tvalid               <= '1';
            s_axis_tlast                <= '0';
            wait until s_axis_tready = '1';         -- slave is done with input(0)

            report "[1] Setting input(1)";
            s_axis_tdata                <= (others => '0');
            s_axis_tvalid               <= '1';
            s_axis_tlast                <= '1';
            wait until rising_edge(clk);
            assert s_axis_tready = '1' report "[1] Slave did not see input(1)";

            s_axis_tvalid               <= '0';
            s_axis_tlast                <= '0';

            report "[1] Testing outputs";
            wait until m_axis_tvalid = '1';
            assert m_axis_tdata = X"0000_0078" report "[20] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0078" report "[21] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0078" report "[22] Output error";  
            wait until rising_edge(clk);
            assert m_axis_tdata = X"0000_0078" report "[23] Output error";  

            -------------------------------------------------------------------------------

--          report "[2] Settings L0.B3  = -1";
--          report "--";

--          s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_000B#, 32));
--          s_axi_awvalid           <= '1';
--          s_axi_wdata             <= X"FF";
--          s_axi_wvalid            <= '1';

--          wait on s_axi_awready, s_axi_wready;

--          if s_axi_awready = '1' and s_axi_wready = '1' then 
--              s_axi_awvalid       <= '0';
--              s_axi_wvalid        <= '0';
--          elsif s_axi_awready = '1' then
--              s_axi_awvalid       <= '0';
--              wait on s_axi_wready;
--              s_axi_wvalid        <= '0';
--          elsif s_axi_wready = '1' then
--              s_axi_wvalid        <= '0';
--              wait on s_axi_awready;
--              s_axi_awvalid       <= '0';
--          end if;

--          wait on s_axi_bvalid;

--          if s_axi_bvalid = '1' then 
--              s_axi_bready <= '1';
--              wait for 2 * CLOCK_PERIOD;
--              s_axi_bready <= '0';
--          end if;

--          wait for 10*CLOCK_PERIOD;
--          report "[2] Testing outputs";
--          assert m_axis_tdata = X"6060_6060" report "[2] Output error";  

--          -------------------------------------------------------------------------------

--          report "[3] Settings L1.W01 = -1";
--          report "--";

--          s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_000D#, 32));
--          s_axi_awvalid           <= '1';
--          s_axi_wdata             <= X"FF";
--          s_axi_wvalid            <= '1';

--          wait on s_axi_awready, s_axi_wready;

--          if s_axi_awready = '1' and s_axi_wready = '1' then 
--              s_axi_awvalid       <= '0';
--              s_axi_wvalid        <= '0';
--          elsif s_axi_awready = '1' then
--              s_axi_awvalid       <= '0';
--              wait on s_axi_wready;
--              s_axi_wvalid        <= '0';
--          elsif s_axi_wready = '1' then
--              s_axi_wvalid        <= '0';
--              wait on s_axi_awready;
--              s_axi_awvalid       <= '0';
--          end if;

--          wait on s_axi_bvalid;

--          if s_axi_bvalid = '1' then 
--              s_axi_bready <= '1';
--              wait for 2 * CLOCK_PERIOD;
--              s_axi_bready <= '0';
--          end if;

--          wait for 10*CLOCK_PERIOD;
--          report "[3] Testing outputs";
--          assert m_axis_tdata = X"5050_5050" report "[3] Output error";  

--          -------------------------------------------------------------------------------

--          report "[4] Settings L4.B3  = -10";
--          report "--";

--          s_axi_awaddr            <= std_logic_vector(to_unsigned(16#4000_0042#, 32));
--          s_axi_awvalid           <= '1';
--          s_axi_wdata             <= X"F6";
--          s_axi_wvalid            <= '1';

--          wait on s_axi_awready, s_axi_wready;

--          if s_axi_awready = '1' and s_axi_wready = '1' then 
--              s_axi_awvalid       <= '0';
--              s_axi_wvalid        <= '0';
--          elsif s_axi_awready = '1' then
--              s_axi_awvalid       <= '0';
--              wait on s_axi_wready;
--              s_axi_wvalid        <= '0';
--          elsif s_axi_wready = '1' then
--              s_axi_wvalid        <= '0';
--              wait on s_axi_awready;
--              s_axi_awvalid       <= '0';
--          end if;

--          wait on s_axi_bvalid;

--          if s_axi_bvalid = '1' then 
--              s_axi_bready <= '1';
--              wait for 2 * CLOCK_PERIOD;
--              s_axi_bready <= '0';
--          end if;

--          wait for 10*CLOCK_PERIOD;
--          report "[4] Testing outputs";
--          assert m_axis_tdata = X"5050_5046" report "[4] Output error";  

--          report "--";
            wait;

        end process;
    
end architecture;

