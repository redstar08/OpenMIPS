library verilog;
use verilog.vl_types.all;
entity ex_mem is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        ex_we           : in     vl_logic;
        ex_waddr        : in     vl_logic_vector(4 downto 0);
        ex_wdata        : in     vl_logic_vector(31 downto 0);
        ex_we_hilo      : in     vl_logic;
        ex_hi           : in     vl_logic_vector(31 downto 0);
        ex_lo           : in     vl_logic_vector(31 downto 0);
        count_i         : in     vl_logic_vector(1 downto 0);
        hilo_i          : in     vl_logic_vector(63 downto 0);
        count_o         : out    vl_logic_vector(1 downto 0);
        hilo_o          : out    vl_logic_vector(63 downto 0);
        mem_we          : out    vl_logic;
        mem_waddr       : out    vl_logic_vector(4 downto 0);
        mem_wdata       : out    vl_logic_vector(31 downto 0);
        mem_we_hilo     : out    vl_logic;
        mem_hi          : out    vl_logic_vector(31 downto 0);
        mem_lo          : out    vl_logic_vector(31 downto 0)
    );
end ex_mem;
