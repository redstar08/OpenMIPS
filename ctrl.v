`include "defines.v"			 //引入宏定义
module ctrl(
	input wire		    	rst,
	input wire		    	id_stall,
	input wire		    	ex_stall,
	output reg[5:0]    	    stall
);
// stall[0] = 1     暂停PC
// stall[1] = 1     暂停IF
// stall[2] = 1     暂停ID
// stall[3] = 1     暂停EX
// stall[4] = 1     暂停MEM
// stall[5] = 1     暂停WB

always @ (*) begin
	if(rst == `Enable) begin
		stall <= 6'b000000;                 //复位时，全部不暂停
	end else if(id_stall == `Stop) begin
		stall <= 6'b000111;		            //ID阶段暂停，EX MEM WB继续执行
    end else if(ex_stall == `Stop) begin    //EX阶段暂停，MEM WB继续执行
		stall <= 6'b001111;		     
	end else begin
		stall <= 6'b000000;
	end
end

endmodule