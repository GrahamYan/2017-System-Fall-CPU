`include "defines.v"

module mem(

	input wire                    rst,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  wdata_i,
	input wire[`OpcodeBus]		  opcode_i,
	input wire[`Func3Bus]		  func3_i,
 
	input wire[`RegBus]           mem_addr_i,
	input wire[`RegBus]           reg2_i,
	
	//来自memory的信息
	input wire[`RegBus]           mem_data_i,

	//LLbit_i是LLbit寄存器的值
/*	input wire                  LLbit_i,
	//但不一定是最新值，回写阶段可能要写LLbit，所以还要进一步判断
	input wire                  wb_LLbit_we_i,
	input wire                  wb_LLbit_value_i,*/
	
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]			 wdata_o,

/*	output reg                   LLbit_we_o,
	output reg                   LLbit_value_o,*/
	
	//送到memory的信息
	output reg[`RegBus]          mem_addr_o,
	output wire					 mem_we_o,
	output reg[3:0]              mem_sel_o,
	output reg[`RegBus]          mem_data_o,
	output reg                   mem_ce_o	
	
);

	wire[`RegBus] zero32;
	reg  mem_we;

	assign mem_we_o = mem_we ;
	assign zero32 = `ZeroWord;

/*  //获取最新的LLbit的值
	always @ (*) begin
		if(rst == `RstEnable) begin
			LLbit <= 1'b0;
		end else begin
			if(wb_LLbit_we_i == 1'b1) begin
				LLbit <= wb_LLbit_value_i;
			end else begin
				LLbit <= LLbit_i;
			end
		end
	end*/
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  	wdata_o <= `ZeroWord;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;		      
		end else begin
		    wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;			
			case (opcode_i)
				`OP_LOAD: begin
					case (func3_i)
						`FUNCT3_LB: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteDisable;
							mem_ce_o <= `ChipEnable;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
									mem_sel_o <= 4'b0001;
								end
								2'b01: begin
									wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
									mem_sel_o <= 4'b0010;
								end
								2'b10: begin
									wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
									mem_sel_o <= 4'b0100;
								end
								2'b11: begin
									wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
									mem_sel_o <= 4'b1000;
								end
							endcase
						end
						`FUNCT3_LH: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteDisable;
							mem_ce_o <= `ChipEnable;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
									mem_sel_o <= 4'b0011;
								end
								2'b10: begin
									wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
									mem_sel_o <= 4'b1100;
								end
							endcase
						end
						`FUNCT3_LW: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteDisable;
							mem_ce_o <= `ChipEnable;
							wdata_o <= mem_data_i;
							mem_sel_o <= 4'b1111;
						end
						`FUNCT3_LHU : begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteDisable;
							mem_ce_o <= `ChipEnable;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {16'b0, mem_data_i[15:0]};
									mem_sel_o <= 4'b0011;
								end
								2'b10: begin
									wdata_o <= {16'b0, mem_data_i[31:16]};
									mem_sel_o <= 4'b1100;
								end
							endcase
						end
						`FUNCT3_LBU: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteDisable;
							mem_ce_o <= `ChipEnable;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {24'b0, mem_data_i[7:0]};
									mem_sel_o <= 4'b0001;
								end
								2'b01: begin
									wdata_o <= {24'b0, mem_data_i[15:8]};
									mem_sel_o <= 4'b0010;
								end
								2'b10: begin
									wdata_o <= {24'b0, mem_data_i[23:16]};
									mem_sel_o <= 4'b0100;
								end
								2'b11: begin
									wdata_o <= {24'b0, mem_data_i[31:24]};
									mem_sel_o <= 4'b1000;
								end
								default: begin
									wdata_o <= `ZeroWord;
								end
							endcase
						end
					endcase
				end
				`OP_STORE: begin
					case (func3_i)
						`FUNCT3_SB: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteEnable;
							mem_ce_o <= `ChipEnable;
							mem_data_o <= {4{reg2_i[7:0]}};
							case (mem_addr_i[1:0])
								2'b00: begin
									mem_sel_o <= 4'b0001;
								end
								2'b01: begin
									mem_sel_o <= 4'b0010;
								end
								2'b10: begin
									mem_sel_o <= 4'b0100;
								end
								2'b11: begin
									mem_sel_o <= 4'b1000;
								end
								default: begin
									mem_sel_o <= 4'b0000;
								end
							endcase
						end
						`FUNCT3_SH: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteEnable;
							mem_ce_o <= `ChipEnable;
							mem_data_o <= {2{reg2_i[15:0]}};
							case (mem_addr_i[1:0])
								2'b00: begin
									mem_sel_o <= 4'b0011;
								end
								
								2'b10: begin
									mem_sel_o <= 4'b1100;
								end
								default: begin
									mem_sel_o <= 4'b0000;
								end
							endcase
						end
						`FUNCT3_SW: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WriteEnable;
							mem_ce_o <= `ChipEnable;
							mem_data_o <= reg2_i;
							mem_sel_o <= 4'b1111;
						end
					endcase
				end
				default: begin
					//$display("Error: module mem: < :: unknown opcode >");
				end
			endcase							
		end    //if
	end      //always
			

endmodule
