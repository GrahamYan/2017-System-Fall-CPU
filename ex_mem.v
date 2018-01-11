`include "defines.v"

module ex_mem(

	input	wire										clk,
	input wire										rst,

	//���Կ���ģ�����Ϣ
	input wire[`CtrlBus]							 stall,	
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]			  ex_wdata, 	
	input wire[`OpcodeBus]		  ex_opcode,
	input wire[`Func3Bus]		  ex_func3,
	input wire[`RegBus]		  	  ex_mem_addr,
	input wire[`RegBus]			  ex_reg2,	

  //Ϊʵ�ּ��ء��ô�ָ������
 /* input wire[`AluOpBus]        ex_aluop,
	input wire[`RegBus]          ex_mem_addr,
	input wire[`RegBus]          ex_reg2,

	input wire[`DoubleRegBus]     hilo_i,	
	input wire[1:0]               cnt_i,	*/
	
	//�͵��ô�׶ε���Ϣ
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			 mem_wdata,
	output reg[`OpcodeBus]		  mem_opcode,
	output reg[`Func3Bus]		  mem_func3,
	output reg[`RegBus]			  mem_mem_addr,
	output reg[`RegBus]			  mem_reg2

  //Ϊʵ�ּ��ء��ô�ָ������
 /* output reg[`AluOpBus]        mem_aluop,
	output reg[`RegBus]          mem_mem_addr,
	output reg[`RegBus]          mem_reg2,
		
	output reg[`DoubleRegBus]    hilo_o,
	output reg[1:0]              cnt_o	*/
	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;
			mem_opcode <= `ZeroWord;
			mem_func3 <= `ZeroWord;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
		end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;
			mem_opcode <= `ZeroWord;
			mem_func3 <= `ZeroWord;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;	
		end else if (stall[3] == `NoStop) begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_opcode <= ex_opcode;
			mem_func3 <= ex_func3;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;			
		end    //if
	end      //always
			

endmodule
