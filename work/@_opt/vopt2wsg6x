library verilog;
use verilog.vl_types.all;
entity mem_wb is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        mem_we          : in     vl_logic;
        mem_waddr       : in     vl_logic_vector(4 downto 0);
        mem_wdata       : in     vl_logic_vector(31 downto 0);
        mem_we_hilo     : in     vl_logic;
        mem_hi          : in     vl_logic_vector(31 downto 0);
        mem_lo          : in     vl_logic_vector(31 downto 0);
        wb_we           : out    vl_logic;
        wb_waddr        : out    vl_logic_vector(4 downto 0);
        wb_wdata        : out    vl_logic_vector(31 downto 0);
        wb_we_hilo      : out    vl_logic;
        wb_hi           : out    vl_logic_vector(31 downto 0);
        wb_lo           : out    vl_logic_vector(31 downto 0)
    );
end mem_wb;
