library verilog;
use verilog.vl_types.all;
entity id is
    port(
        rst             : in     vl_logic;
        stall           : out    vl_logic;
        pc              : in     vl_logic_vector(31 downto 0);
        inst            : in     vl_logic_vector(31 downto 0);
        ex_we           : in     vl_logic;
        ex_waddr        : in     vl_logic_vector(4 downto 0);
        ex_wdata        : in     vl_logic_vector(31 downto 0);
        mem_we          : in     vl_logic;
        mem_waddr       : in     vl_logic_vector(4 downto 0);
        mem_wdata       : in     vl_logic_vector(31 downto 0);
        is_in_slot_i    : in     vl_logic;
        next_in_slot    : out    vl_logic;
        b_flag          : out    vl_logic;
        b_addr          : out    vl_logic_vector(31 downto 0);
        is_in_slot_o    : out    vl_logic;
        link_addr       : out    vl_logic_vector(31 downto 0);
        read1           : out    vl_logic;
        read2           : out    vl_logic;
        raddr1          : out    vl_logic_vector(4 downto 0);
        raddr2          : out    vl_logic_vector(4 downto 0);
        rdata1          : in     vl_logic_vector(31 downto 0);
        rdata2          : in     vl_logic_vector(31 downto 0);
        aluop           : out    vl_logic_vector(7 downto 0);
        alusel          : out    vl_logic_vector(2 downto 0);
        reg1            : out    vl_logic_vector(31 downto 0);
        reg2            : out    vl_logic_vector(31 downto 0);
        we              : out    vl_logic;
        waddr           : out    vl_logic_vector(4 downto 0)
    );
end id;
