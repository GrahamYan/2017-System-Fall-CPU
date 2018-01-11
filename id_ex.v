`include "defines.v"

module id_ex(

	input wire					  clk,
	input wire					  rst,
	//来自控制模块的信息
	input wire[`CtrlBus]          stall,
	
	//从译码阶段传递的信息
	input wire[`AluselBus]         id_alusel,
	input wire[`OpcodeBus]    	  id_opcode,
	input wire[`Func3Bus]         id_func3,
	input wire[`Func7Bus]         id_func7,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[`RegBus]           id_link_addr,
	input wire[`RegBus]			  id_inst,
	input wire                    id_branch_flag,		
	
	//传递到执行阶段的信息
	output reg[`AluselBus]         ex_alusel,
	output reg[`OpcodeBus]    	  ex_opcode,
	output reg[`Func3Bus]         ex_func3,
	output reg[`Func7Bus]         ex_func7,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_wreg,
	output reg[`RegBus]           ex_link_addr,
	output reg[`RegBus]			  ex_inst,
	output reg                    ex_branch_flag 	
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_alusel <= `ALU_NOP;
			ex_opcode <= `EXE_OP_NOP;
			ex_func3 <= `EXE_FUNC3_NOP;
			ex_func7 <= `EXE_FUNC7_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_addr <= `ZeroWord;
			ex_inst <= `ZeroWord;
			ex_branch_flag <= 1'b0;
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_alusel <= `ALU_NOP;
			ex_opcode <= `EXE_OP_NOP;
			ex_func3 <= `EXE_FUNC3_NOP;
			ex_func7 <= `EXE_FUNC7_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_addr <= `ZeroWord;
			ex_inst <= `ZeroWord;
			ex_branch_flag <= 1'b0;			
		end else if(stall[2] == `NoStop) begin		
			ex_alusel <= id_alusel;
			ex_opcode <= id_opcode;
			ex_func3 <= id_func3;
			ex_func7 <= id_func7;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			ex_link_addr <= id_link_addr;
			ex_inst <= id_inst;
			ex_branch_flag <= id_branch_flag;			
		end
	end
	
endmodule
