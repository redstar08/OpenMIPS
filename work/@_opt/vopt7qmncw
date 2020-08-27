library verilog;
use verilog.vl_types.all;
entity mem is
    port(
        rst             : in     vl_logic;
        we_i            : in     vl_logic;
        waddr_i         : in     vl_logic_vector(4 downto 0);
        wdata_i         : in     vl_logic_vector(31 downto 0);
        we_hilo_i       : in     vl_logic;
        hi_i            : in     vl_logic_vector(31 downto 0);
        lo_i            : in     vl_logic_vector(31 downto 0);
        we_o            : out    vl_logic;
        waddr_o         : out    vl_logic_vector(4 downto 0);
        wdata_o         : out    vl_logic_vector(31 downto 0);
        we_hilo_o       : out    vl_logic;
        hi_o            : out    vl_logic_vector(31 downto 0);
        lo_o            : out    vl_logic_vector(31 downto 0)
    );
end mem;
