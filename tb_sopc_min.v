`include "defines.v"
`include "sopc_min.v"

module tb_sopc_min();

reg clk;
reg rst;

// clk定义，10ns为一个周期(100MHz)
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// 先复位，100ns后开始仿真，500ns后停止仿真
initial begin
    #0 rst = `Enable;
    #50 rst = `Disable;
    #2000 $stop;

end

sopc_min sopc_min0(
    .rst (rst),
    .clk (clk)
);

endmodule
