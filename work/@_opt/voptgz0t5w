library verilog;
use verilog.vl_types.all;
entity div is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        start           : in     vl_logic;
        annul           : in     vl_logic;
        div_signed      : in     vl_logic;
        opdata1         : in     vl_logic_vector(31 downto 0);
        opdata2         : in     vl_logic_vector(31 downto 0);
        ready           : out    vl_logic;
        result          : out    vl_logic_vector(63 downto 0)
    );
end div;
