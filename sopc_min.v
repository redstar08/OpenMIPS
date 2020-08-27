`include "defines.v"
module sopc_min(
    input wire clk,
    input wire rst
);

// openmips连接rom
wire            rom_ce;
wire[`DataBus]  rom_addr;
wire[`DataBus]  rom_data;

// 实例化CPU
openmips openmips0(
    .clk(clk),
    .rst(rst),
    // 输出到rom
    .rom_ce(rom_ce),
    .rom_addr(rom_addr),
    // 来自rom的输入
    .rom_data(rom_data)
);

// 实例化rom
rom rom0(
    // 来自CPU的输入
    .ce(rom_ce),
    .addr(rom_addr),
    // 输出到CPU
    .inst(rom_data)
);

endmodule