library verilog;
use verilog.vl_types.all;
entity hi_lo is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        we              : in     vl_logic;
        whi             : in     vl_logic_vector(31 downto 0);
        wlo             : in     vl_logic_vector(31 downto 0);
        rhi             : out    vl_logic_vector(31 downto 0);
        rlo             : out    vl_logic_vector(31 downto 0)
    );
end hi_lo;
