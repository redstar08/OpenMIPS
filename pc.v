`include "defines.v"			 //引入宏定义
module pc(
	input wire		    	rst,
	input wire		    	clk,
	input wire[5:0]			stall,
	input wire				b_flag,
	input wire[31:0]  		b_addr,

	output reg		    	ce,   //指令存储器使能信号
	output reg[31:0]    	pc
);

always @ (posedge clk) begin
	if(rst == `Enable) begin
		ce <= `Invalid;          //复位时，指令存储器无效，pc清0
	end else begin
		ce <= `Valid;		     //复位结束，使能指令存储器有效，pc=pc+4
	end
end

// 当stall[0] == 1则暂停pc
always @ (posedge clk) begin
	if(ce == `Invalid) begin
		pc <= `ZeroWord;	     //指令存储器无效时，pc清0
	end else if(stall[0] == `NoStop) begin
		if(b_flag == `Valid) begin
			pc <= b_addr;
		end else begin
			pc <= pc + `pcStep; 
		end
	end
end

endmodule