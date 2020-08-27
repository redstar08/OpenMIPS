`include "defines.v"

module if_id(
    input wire              rst,
    input wire              clk,
    input wire[5:0]			stall,
    // sign from IF
    input wire[`DataBus]    if_pc,
    input wire[`DataBus]    if_inst,
    // sign to ID
    output reg[`DataBus]    id_pc,
    output reg[`DataBus]    id_inst
);

always @ (posedge clk) begin
    if(rst == `Enable) begin    //reset, 0 to ID
        id_pc   <=  `ZeroWord;
        id_inst <=  `ZeroWord;
    end else if(stall[1] == `Stop && stall[2] == `NoStop) begin //IF stall ID继续执行
        id_pc   <=  `ZeroWord;
        id_inst <=  `ZeroWord;
    end else if(stall[1] == `NoStop) begin      //not reset, IF sign to ID
        id_pc   <=  if_pc;
        id_inst <=  if_inst;
    end
end

endmodule
