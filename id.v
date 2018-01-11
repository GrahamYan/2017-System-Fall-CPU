`include "defines.v"

module id(

	input wire					  rst,
	input wire[`InstAddrBus]	  pc_i,
	input wire[`InstBus]          inst_i,

	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,
	//input from ex
	input wire					  ex_wreg_i,
	input wire[`RegBus]           ex_wdata_i,
	input wire[`RegAddrBus]       ex_wd_i,
	input wire[`OpcodeBus]        ex_opcode_i,
	input wire[`Func3Bus]		  ex_func3_i,
	input wire                    ex_branch_flag_i,
	//input from mem
	input wire					  mem_wreg_i,
	input wire[`RegBus]           mem_wdata_i,
	input wire[`RegAddrBus]       mem_wd_i,
	//送到regfile的信息
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信息
	output reg[`AluselBus]        alusel_o,
	output reg[`OpcodeBus]        opcode_o,
	output reg[`Func3Bus]         func3_o,
	output reg[`Func7Bus]         func7_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]           link_addr_o,
	output wire[`RegBus]		  inst_o,

	//pc_reg
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_o,
	
	//ctrl
	output wire 			      stallreq
);

    wire[`RegBus] BRA_branch_target;
	wire[`RegBus] JAL_branch_target;
	wire[`RegBus] JALR_branch_target_tmp;
	wire[`RegBus] JALR_branch_target;
	assign BRA_branch_target = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
	assign JAL_branch_target = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;
	assign JALR_branch_target_tmp = {{21{inst_i[31]}}, inst_i[30:20]} + reg1_o;
	assign JALR_branch_target = {JALR_branch_target_tmp[31:1], 1'b0};

  wire[`RegBus] pc_plus_4 = pc_i + 4;
  wire[6:0] op = inst_i[6:0];
  wire[2:0] op2 = inst_i[14:12];
  wire[6:0] op3 = inst_i[31:25];
  reg[`RegBus]	imm;
  reg instvalid;
  wire[`RegBus] result;
	assign result = reg1_o + (~reg2_o) + 1;
	assign inst_o = inst_i;

	//BRANCH related stall
	wire pre_inst_is_branch;
	assign pre_inst_is_branch = (ex_opcode_i == `OP_JAL |
							   ex_opcode_i == `OP_JALR |
							   ex_opcode_i == `OP_BRANCH)? 1'b1 : 1'b0;
	//LOAD related stall
	reg stallreq_for_reg1_loadrelate;
	reg stallreq_for_reg2_loadrelate;
	wire pre_inst_is_load;

	//LOAD relationship judgement
	assign pre_inst_is_load = (ex_opcode_i == `OP_LOAD)? 1'b1 : 1'b0;

  
 
	always @ (*) begin	
		if (rst == `RstEnable) begin
			//regfile
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;	
			//exec
			instvalid <= `InstInvalid;
			alusel_o <= `ALU_NOP;
			opcode_o <= `EXE_OP_NOP;
			func7_o <= `EXE_FUNC7_NOP;
			func3_o <= `EXE_FUNC3_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			link_addr_o <= `ZeroWord;
			imm <= `ZeroWord;
			//pc_reg
			branch_flag_o <= `NotBranch;
			branch_target_o <= `ZeroWord;
	  	end else if (pre_inst_is_branch == 1'b1 &&
		  			 ex_branch_flag_i == 1'b1) begin
			//regfile
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;	
			//exec
			instvalid <= `InstInvalid;
			alusel_o <= `ALU_NOP;
			opcode_o <= `EXE_OP_NOP;
			func7_o <= `EXE_FUNC7_NOP;
			func3_o <= `EXE_FUNC3_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			link_addr_o <= `ZeroWord;
			imm <= `ZeroWord;
			//pc_reg
			branch_flag_o <= `NotBranch;
			branch_target_o <= `ZeroWord;
		end else begin
			//regfile
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[19:15];
			reg2_addr_o <= inst_i[24:20];	
			//exec
			instvalid <= `InstInvalid;
			alusel_o <= `ALU_NOP;
			opcode_o <= `EXE_OP_NOP;
			func7_o <= `EXE_FUNC7_NOP;
			func3_o <= `EXE_FUNC3_NOP;
			wd_o <= inst_i[11:7];
			wreg_o <= `WriteDisable;
			link_addr_o <= `ZeroWord;
			imm <= `ZeroWord;
			//pc_reg
			branch_flag_o <= `NotBranch;
			branch_target_o <= `ZeroWord;
		
		  case (op)
		  	`OP_LUI: begin
		  		alusel_o <= `ALU_LOG; opcode_o <= op;
				wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
				reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;	  	
				imm <= {inst_i[31:12], 12'b0};
				instvalid <= `InstValid;
		  	end
		  	`OP_AUIPC: begin
		  		alusel_o <= `ALU_LOG; opcode_o <= op;
				wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
				reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;	  	
				imm <= {inst_i[31:12], 12'b0} + pc_i;
				instvalid <= `InstValid;
		  	end
		  	`OP_JAL: begin
		  		alusel_o <= `ALU_JAB; opcode_o <= op;
				wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
				reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
				branch_flag_o <= `Branch;	  	
				branch_target_o <= JAL_branch_target;
				link_addr_o <= pc_plus_4;
				instvalid <= `InstValid;
		  	end
		  	`OP_JALR: begin
		  		alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
				wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
				branch_flag_o <= `Branch;	  	
				branch_target_o <= JALR_branch_target;
				link_addr_o <= pc_plus_4;
				instvalid <= `InstValid;
		  	end
		  	`OP_BRANCH: begin
		  		case (op2)
					`FUNCT3_BEQ: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if (reg1_o == reg2_o) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					`FUNCT3_BNE: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if (reg1_o != reg2_o) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					`FUNCT3_BLT: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if ((reg1_o[31] && !reg2_o[31]) || 
							 (!reg1_o[31] && !reg2_o[31] && result[31]) ||
							 (reg1_o[31] && reg2_o[31] && result[31])) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					`FUNCT3_BGE: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if ((!reg1_o[31] && reg2_o[31]) || 
							 (!reg1_o[31] && !reg2_o[31] && !result[31]) ||
							 (reg1_o[31] && reg2_o[31] && !result[31])) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					`FUNCT3_BLTU: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if (reg1_o < reg2_o) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					`FUNCT3_BGEU: begin
						alusel_o <= `ALU_JAB; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable;
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						if (reg1_o >= reg2_o) begin
							branch_flag_o <= `Branch;	  	
							branch_target_o <= BRA_branch_target;
						end
						instvalid <= `InstValid;
					end
					default: begin
					end
				endcase //op2
		  	end
		  	`OP_LOAD: begin
		  		case (op2)
					`FUNCT3_LB: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
						instvalid <= `InstValid;
					end
					`FUNCT3_LH: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
						instvalid <= `InstValid;
					end
					`FUNCT3_LW: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
						instvalid <= `InstValid;
					end
					`FUNCT3_LBU: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
						instvalid <= `InstValid;
					end
					`FUNCT3_LHU: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
						instvalid <= `InstValid;
					end
					default: begin
						//$display("Error: module id: < OP-LOAD :: unknown func3 -> %h >",inst_i);
					end
				endcase //op2
		  	end
		  	`OP_STORE: begin
		  		case (op2)
					`FUNCT3_SB: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						instvalid <= `InstValid;
					end
					`FUNCT3_SH: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						instvalid <= `InstValid;
					end
					`FUNCT3_SW: begin
						alusel_o <= `ALU_LAS; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteDisable; wd_o <= inst_i[11:7];
						reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
						instvalid <= `InstValid;
					end
					default: begin
						//$display("Error: module id: < OP-STORE :: unknown func3 -> %h >",inst_i);
					end
				endcase //op2
		  	end
		  	`OP_OP_IMM: begin                        
		  		case (op2)
		  			///////////////////////ADDI
		  			`FUNCT3_ADDI:		begin
		  				alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////SLTI
		  			`FUNCT3_SLTI:		begin
		  				alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////SLTIU
		  			`FUNCT3_SLTIU:		begin
		  				alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////XORI
		  			`FUNCT3_XORI:		begin
		  				alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////ORI
		  			`FUNCT3_ORI:		begin
		  				alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
		  				wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////ANDI
		  			`FUNCT3_ANDI:		begin
		  				alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {{21{inst_i[31]}}, inst_i[30:20]};
						instvalid <= `InstValid;
		  			end
		  			///////////////////////SLLI
		  			`FUNCT3_SLLI:		begin
						alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
						imm <= {inst_i[24:20]};
						instvalid <= `InstValid;
					 end 
		  			///////////////////////SRLI&SRAI
		  			`FUNCT3_SRLI_SRAI:		begin
		  				case (op3)
							`FUNCT7_SRLI: begin
								alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
								imm <= {inst_i[24:20]};
								instvalid <= `InstValid;
							end
							`FUNCT7_SRAI: begin
								alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;	  	
								imm <= {inst_i[24:20]};
								instvalid <= `InstValid;
							end
							default: begin
								//$display("Error: module id: < OP-OP-IMM :: FUNCT3-SRLI-SRAI :: unknown func7 -> %h >",inst_i);
							end
						endcase //FUNCT3_SRLI_SRAI op3
		  			end
					default: begin
						//$display("Error: module id: < OP-OP-IMM :: unknown func3 -> %h >",inst_i);
					end
		  		endcase        //op2			
		  	end 
			`OP_OP: begin
				case (op2)
					///////////////////////ADD&SUB
					`FUNCT3_ADD_SUB: begin
						case (op3)
							`FUNCT7_ADD: begin
								alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
								imm <= `ZeroWord;
								instvalid <= `InstValid;
							end
							`FUNCT7_SUB: begin
								alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
								imm <= `ZeroWord;
								instvalid <= `InstValid;
							end
							default: begin
								//$display("Error: module id: < OP-O :: ADD_SUB :: unknown func3 -> %h >",inst_i);
							end
						endcase //ADD-SUB func7
					end
					//////////////////////SLL
					`FUNCT3_SLL:		begin
						alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;
					end					
					/////////////////////////SLT
					`FUNCT3_SLT:		begin
						alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;
					end
					/////////////////////////SLTU
					`FUNCT3_SLTU:		begin
						alusel_o <= `ALU_ARI; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;
					end
					///////////////////////XOR
					`FUNCT3_XOR:		begin
						alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;
					end
					/////////////////////SRL&SRA
					`FUNCT3_SRL_SRA:		begin
						case(op3)
							`FUNCT7_SRL: begin
								alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
								imm <= `ZeroWord;
								instvalid <= `InstValid;
							end
							`FUNCT7_SRA: begin
								alusel_o <= `ALU_SHI; opcode_o <= op; func3_o <= op2; func7_o <= op3;
								wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
								reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
								imm <= `ZeroWord;
								instvalid <= `InstValid;
							end
							default: begin
								//$display("Error: module id: < OP-OP :: SRL_SRA :: unknown func7 -> %h >",inst_i);
							end
						endcase//SRL_SRA op3
					end
					/////////////////////////OR
					`FUNCT3_OR:		begin				//ORI指令
		  				alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;	
					end
					////////////////////////AND
					`FUNCT3_AND:		begin
						alusel_o <= `ALU_LOG; opcode_o <= op; func3_o <= op2;
						wreg_o <= `WriteEnable; wd_o <= inst_i[11:7];
		  				reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;	  	
						imm <= `ZeroWord;
						instvalid <= `InstValid;
					end
				endcase        //op3	
			end	
			`OP_MISC_MEM: begin
			
			end						 
		    default: begin
		    	//$display("Error: module id: < :: unknown opcode -> %h , %h>",inst_i, op);
		    end
		  endcase		  //case op			
		end       //if
	end         //always
	

	always @ (*) begin
		stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if ((reg1_read_o == 1'b1) && (reg1_addr_o == 5'b0)) begin
			reg1_o <= `ZeroWord;
		end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o
					&& reg1_read_o == 1'b1) begin
			stallreq_for_reg1_loadrelate <= `Stop;
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1)
					&&(ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i;
		end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1)
					&&(mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i;	
	  	end else if(reg1_read_o == 1'b1) begin
	  		reg1_o <= reg1_data_i;
	  	end else if(reg1_read_o == 1'b0) begin
	  		reg1_o <= imm;
	  	end else begin
	    	reg1_o <= `ZeroWord;
	  	end
	end
	
	always @ (*) begin
		stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if ((reg2_read_o == 1'b1) && (reg2_addr_o == 5'b0)) begin
			reg2_o <= `ZeroWord;
		end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o
				&& reg2_read_o == 1'b1) begin
			stallreq_for_reg2_loadrelate <= `Stop;
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1)
					&&(ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i;
		end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1)
					&&(mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;	
	  	end else if(reg2_read_o == 1'b1) begin
	  		reg2_o <= reg2_data_i;
	  	end else if(reg2_read_o == 1'b0) begin
	  		reg2_o <= imm;
	  	end else begin
	    	reg2_o <= `ZeroWord;
	  	end
	end
	
	assign stallreq = stallreq_for_reg1_loadrelate |
		   stallreq_for_reg2_loadrelate;

endmodule
