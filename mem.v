`include "defines.v"
module mem(
    input wire              rst,
    // sign from ex
    input wire              we_i,
    input wire[`RegAddr]    waddr_i,
    input wire[`DataBus]    wdata_i,
    input wire              we_hilo_i,
    input wire[`DataBus]    hi_i,
    input wire[`DataBus]    lo_i,
    // sign from ex to mem
    output reg              we_o,
    output reg[`RegAddr]    waddr_o,
    output reg[`DataBus]    wdata_o,
    output reg              we_hilo_o,
    output reg[`DataBus]    hi_o,
    output reg[`DataBus]    lo_o
);

always @ (*) begin
    if(rst == `Enable) begin
        we_o      <=  `Invalid;
        waddr_o   <=  `NOPAddr;
        wdata_o   <=  `ZeroWord;
        we_hilo_o <=  `Invalid;
        hi_o      <=  `ZeroWord;
        lo_o      <=  `ZeroWord;
    end else begin
        we_o     <=  we_i;
        waddr_o  <=  waddr_i;
        wdata_o  <=  wdata_i;
        we_hilo_o <=  we_hilo_i;
        hi_o      <=  hi_i;
        lo_o      <=  lo_i;
    end
end

endmodule