`include "defines.v"

module openmips(

	input wire					   clk,
	input wire					   rst,
 
	input wire[`RegBus]            rom_data_i,
	output wire[`RegBus]           rom_addr_o,
	output wire                    rom_ce_o,
	
	//RAM
	input wire[`RegBus]            ram_data_i,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire                    ram_ce_o   
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//��������׶�IDģ��������ID/EXģ�������
	wire[`AluselBus] id_alusel_o;
	wire[`OpcodeBus] id_opcode_o;
	wire[`Func3Bus] id_func3_o;
	wire[`Func7Bus] id_func7_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire[`RegBus] id_link_addr_o;
	wire[`RegBus] id_inst_o;

	//����Ctrlģ��
	wire stallreq_from_id;	
	wire stallreq_from_ex;
	wire[`CtrlBus] stall;

	//����PCģ��
	wire id_branch_flag_o;
	wire[`RegBus] id_branch_target_o;
	wire id_ie;
	//����ID/EXģ��������ִ�н׶�EXģ�������
	wire[`AluselBus] ex_alusel_i;
	wire[`OpcodeBus] ex_opcode_i;
	wire[`Func3Bus] ex_func3_i;
	wire[`Func7Bus] ex_func7_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_wreg_i;
	wire[`RegBus] ex_link_addr_i;
	wire[`RegBus] ex_inst_i;
	wire ex_branch_flag_i;
	//����ִ�н׶�EXģ��������EX/MEMģ�������
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`OpcodeBus] ex_opcode_o;
	wire[`Func3Bus] ex_func3_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	wire ex_branch_flag_o;
	//����EX/MEMģ��������ô�׶�MEMģ�������
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`OpcodeBus] mem_opcode_i;
	wire[`Func3Bus] mem_func3_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;


	//���ӷô�׶�MEMģ��������MEM/WBģ�������
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	
	//����MEM/WBģ���������д�׶ε�����	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	
	//��������׶�IDģ����ͨ�üĴ���Regfileģ��
  	wire reg1_read;
  	wire reg2_read;
  	wire[`RegBus] reg1_data;
  	wire[`RegBus] reg2_data;
  	wire[`RegAddrBus] reg1_addr;
  	wire[`RegAddrBus] reg2_addr;
  
  //pc_reg����
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		//IDģ���branch�ź�
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(id_branch_target_o),

		.pc(pc),
		.ce(rom_ce_o)
	);
	
  assign rom_addr_o = pc;

  	//IF/IDģ������
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)	
	);
	
	//����׶�IDģ��
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

		//����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		.ex_opcode_i(ex_opcode_o),
		.ex_func3_i(ex_func3_o),
		.ex_branch_flag_i(ex_branch_flag_o),

	    //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

		//�͵�regfile����Ϣ
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//�͵�ID/EXģ�����Ϣ
		.alusel_o(id_alusel_o),
		.opcode_o(id_opcode_o),
		.func3_o(id_func3_o),
		.func7_o(id_func7_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.link_addr_o(id_link_addr_o),
		.inst_o(id_inst_o),
		//�͵�pc_regģ�����Ϣ
		.branch_flag_o(id_branch_flag_o),
		.branch_target_o(id_branch_target_o),

		//�͵�ctrlģ�����Ϣ
		.stallreq(stallreq_from_id)
	);

  	//ͨ�üĴ���Regfile����
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID/EXģ��
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		//������׶�IDģ�鴫�ݵ���Ϣ
		.id_alusel(id_alusel_o),
		.id_opcode(id_opcode_o),
		.id_func3(id_func3_o),
		.id_func7(id_func7_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_addr(id_link_addr_o),
		.id_inst(id_inst_o),
		.id_branch_flag(id_branch_flag_o),

		//���ݵ�ִ�н׶�EXģ�����Ϣ
		.ex_alusel(ex_alusel_i),
		.ex_opcode(ex_opcode_i),
		.ex_func3(ex_func3_i),
		.ex_func7(ex_func7_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_addr(ex_link_addr_i),
		.ex_inst(ex_inst_i),
		.ex_branch_flag(ex_branch_flag_i)
	);		
	
	//EXģ��
	ex ex0(
		.rst(rst),
	
		//�͵�ִ�н׶�EXģ�����Ϣ
		.alusel_i(ex_alusel_i),
		.opcode_i(ex_opcode_i),
		.func3_i(ex_func3_i),
		.func7_i(ex_func7_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
	  	.link_addr_i(ex_link_addr_i),
		.inst_i(ex_inst_i),
		.branch_flag_i(ex_branch_flag_i),

		.branch_flag_o(ex_branch_flag_o),
	  	//EXģ��������EX/MEMģ����Ϣ
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.opcode_o(ex_opcode_o),
		.func3_o(ex_func3_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

		.stallreq(stallreq_from_ex)
	);

  	//EX/MEMģ��
  	ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	    .stall(stall),

		//����ִ�н׶�EXģ�����Ϣ	
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_opcode(ex_opcode_o),
		.ex_func3(ex_func3_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),

		//�͵��ô�׶�MEMģ�����Ϣ
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_opcode(mem_opcode_i),
		.mem_func3(mem_func3_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i)
						       	
	);
	
  	//MEMģ������
	mem mem0(
		.rst(rst),
	
		//����EX/MEMģ�����Ϣ	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	  	.opcode_i(mem_opcode_i),
		.func3_i(mem_func3_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),

		//�����ڴ�RAM����Ϣ
		.mem_data_i(ram_data_i),
		
		//�͵�MEM/WBģ�����Ϣ
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),

		//�͵�RAM����Ϣ
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)
	);

 	 //MEM/WBģ��
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		//���Էô�׶�MEMģ�����Ϣ	
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
	
		//�͵���д�׶ε���Ϣ
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)
									       	
	);
	ctrl ctrl0(
		.rst(rst),

		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.stall(stall)
	);
endmodule
