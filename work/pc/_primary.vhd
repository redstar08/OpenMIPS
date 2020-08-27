library verilog;
use verilog.vl_types.all;
entity pc is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        b_flag          : in     vl_logic;
        b_addr          : in     vl_logic_vector(31 downto 0);
        ce              : out    vl_logic;
        pc              : out    vl_logic_vector(31 downto 0)
    );
end pc;
