library verilog;
use verilog.vl_types.all;
entity id_ex is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        id_aluop        : in     vl_logic_vector(7 downto 0);
        id_alusel       : in     vl_logic_vector(2 downto 0);
        id_reg1         : in     vl_logic_vector(31 downto 0);
        id_reg2         : in     vl_logic_vector(31 downto 0);
        id_we           : in     vl_logic;
        id_waddr        : in     vl_logic_vector(4 downto 0);
        id_is_in_slot   : in     vl_logic;
        id_link_addr    : in     vl_logic_vector(31 downto 0);
        next_in_slot    : in     vl_logic;
        is_in_slot      : out    vl_logic;
        ex_is_in_slot   : out    vl_logic;
        ex_link_addr    : out    vl_logic_vector(31 downto 0);
        ex_aluop        : out    vl_logic_vector(7 downto 0);
        ex_alusel       : out    vl_logic_vector(2 downto 0);
        ex_reg1         : out    vl_logic_vector(31 downto 0);
        ex_reg2         : out    vl_logic_vector(31 downto 0);
        ex_we           : out    vl_logic;
        ex_waddr        : out    vl_logic_vector(4 downto 0)
    );
end id_ex;
