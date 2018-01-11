`include "defines.v"

module ex(

	input wire					  rst,

	//送到执行阶段的信息
	input wire[`AluselBus]        alusel_i,
	input wire[`OpcodeBus]        opcode_i,
	input wire[`Func3Bus]         func3_i,
	input wire[`Func7Bus]         func7_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]           link_addr_i,
	input wire[`RegBus] 		  inst_i,
	input wire                    branch_flag_i,
	//sent back to id
	output wire                   branch_flag_o,


	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			  wdata_o,
	output wire[`OpcodeBus]       opcode_o,
	output wire[`Func3Bus]        func3_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus] 		  reg2_o,
	output wire 				  stallreq
	
);

	assign branch_flag_o = branch_flag_i;
	
	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;
	reg[`RegBus] arithres;

	wire reg1_eq_reg2;
	wire reg1_lt_reg2;
	wire[`RegBus] reg2_i_mux;
	wire[`RegBus] reg1_i_not;
	wire[`RegBus] result_sum;
	
	assign opcode_o = opcode_i;
	assign func3_o = func3_i;
	assign reg2_o = reg2_i;
	assign mem_addr_o = (opcode_i == `OP_LOAD)? 
						(reg1_i + {{21{inst_i[31]}}, inst_i[30:20]}) :
						(reg1_i + {{21{inst_i[31]}}, inst_i[30:25], inst_i[11:7]});

	assign reg2_i_mux = ((opcode_i == `OP_OP && func3_i == `FUNCT3_ADD_SUB && func7_i == `FUNCT7_SUB) ||
						 (opcode_i == `OP_OP_IMM && func3_i == `FUNCT3_SLTI) ||
						 (opcode_i == `OP_OP && func3_i == `FUNCT3_SLT)) ?
						 (~reg2_i) + 1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;

	assign reg1_lt_reg2 = ((opcode_i == `OP_OP_IMM && func3_i == `FUNCT3_SLTI) ||
						   (opcode_i == `OP_OP && func3_i == `FUNCT3_SLT))?
						   ((reg1_i[31] && !reg2_i[31]) || 
							 (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
							 (reg1_i[31] && reg2_i[31] && result_sum[31]))
						   : (reg1_i < reg2_i);

	assign reg1_i_not = ~reg1_i;

	always @ (*) begin
		if (rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else if (alusel_i == `ALU_LOG) begin
			case (opcode_i)
				`OP_LUI, `OP_AUIPC: begin
					logicout <= reg1_i;
				end //OP_LUI && OP_AUIPC
				`OP_OP_IMM: begin
					case (func3_i)
						`FUNCT3_ORI: begin
							logicout <= reg1_i | reg2_i;
						end
						`FUNCT3_XORI: begin
							logicout <= reg1_i ^ reg2_i;
						end
						`FUNCT3_ANDI: begin
							logicout <= reg1_i & reg2_i;
						end
						default: begin
							$display("Error: module ex: < logicout :: OP-IMM :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_IMM
				`OP_OP: begin
					case (func3_i)
						`FUNCT3_OR: begin
							logicout <= reg1_i | reg2_i;
						end
						`FUNCT3_XOR: begin
							logicout <= reg1_i ^ reg2_i;
						end
						`FUNCT3_AND: begin
							logicout <= reg1_i & reg2_i;
						end
						default: begin
							$display("Error: module ex: < logicout :: OP-OP :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_OP
				default: begin
					$display("Error: module ex: < logicout :: no matching opcode >");
				end
			endcase
		end //alusel_i == `ALU_LOG
		else begin
			logicout <= `ZeroWord;
		end
	end //logicout
	
	always @ (*) begin
		if (rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else if (alusel_i == `ALU_SHI) begin
			case (opcode_i)
				`OP_OP_IMM: begin
					case (func3_i)
						`FUNCT3_SLLI: begin
							shiftres <= (reg1_i << reg2_i[4:0]);
						end
						`FUNCT3_SRLI_SRAI: begin
							case (func7_i)
								`FUNCT7_SRLI: begin
									shiftres <= (reg1_i >> reg2_i[4:0]);
								end
								`FUNCT7_SRAI: begin
									shiftres <= ({32{reg1_i[31]}} << (6'd32 - {1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
								end
								default: begin
									$display("Error: module ex: < shiftres :: OP-IMM :: SRLI_SRAI :: no matching func7 >");
								end
							endcase //func7_i
						end
						default: begin
							$display("Error: module ex: < shiftres :: OP-IMM :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_IMM
				`OP_OP: begin
					case (func3_i)
						`FUNCT3_SLL: begin
							shiftres <= (reg1_i << reg2_i[4:0]);
						end
						`FUNCT3_SRL_SRA: begin
							case (func7_i)
								`FUNCT7_SRL: begin
									shiftres <= (reg1_i >> reg2_i[4:0]);
								end
								`FUNCT7_SRA: begin
									shiftres <= ({32{reg1_i[31]}} << (6'd32 - {1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
								end
								default: begin
									$display("Error: module ex: < shiftres :: OP-OP :: SRLI_SRAI :: no matching func7 >");
								end
							endcase //func7_i
						end
						default: begin
							$display("Error: module ex: < shiftres :: OP-OP :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_OP
				default: begin
					$display("Error: module ex: < shiftres :: no matching opcode >");
				end
			endcase
		end //alusel_i == `ALU_SHI
		else begin
			shiftres <= `ZeroWord;
		end
	end //shiftres

	always @ (*) begin
		if (rst == `RstEnable) begin
			arithres <= `ZeroWord;
		end else if (alusel_i == `ALU_ARI) begin
			case (opcode_i)
				`OP_OP_IMM: begin
					case (func3_i)
						`FUNCT3_ADDI: begin
							arithres <= result_sum;
						end
						`FUNCT3_SLTI, `FUNCT3_SLTIU: begin
							arithres <= reg1_lt_reg2;
						end
						default: begin
							$display("Error: module ex: < arithres :: OP-IMM :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_IMM
				`OP_OP: begin
					case (func3_i)
						`FUNCT3_SLT, `FUNCT3_SLTU: begin
							arithres <= reg1_lt_reg2;
						end
						`FUNCT3_ADD_SUB: begin
							arithres <= result_sum;
						end
						default: begin
							$display("Error: module ex: < arithres :: OP-OP :: no matching func3 >");
						end
					endcase //func3_i
				end //OP_OP
				default: begin
					$display("Error: module ex: < arithres :: no matching opcode >");
				end
			endcase
		end //alusel_i == `ALU_ARI
		else begin
			arithres <= `ZeroWord;
		end
	end //arithres

	
	

 	always @ (*) begin
		wd_o <= wd_i;	 	 	
		wreg_o <= wreg_i;
		case (alusel_i)
			`ALU_JAB: begin
				wdata_o <= link_addr_i;
			end
			`ALU_LOG: begin
				wdata_o <= logicout;
			end
			`ALU_SHI: begin
				wdata_o <= shiftres;
			end
			`ALU_ARI: begin
				wdata_o <= arithres;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
 	end	

endmodule
