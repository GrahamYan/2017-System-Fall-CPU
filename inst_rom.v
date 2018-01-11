`include "defines.v"

module inst_rom(

//	input	wire										clk,
	input wire                    ce,
	input wire[`InstAddrBus]			addr,
	output reg[`InstBus]					inst
	
);

	reg[`InstBus]  inst_mem[0:`InstMemNum-1];
	reg[31:0] inst1;
	reg[31:0] inst2; 

	initial $readmemh ( "inst_rom.data", inst_mem );

	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
	  end else begin
		  inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
/*		  inst2[31:24] <= inst1[7:0];
		  inst2[23:16] <= inst1[15:8];
		  inst2[15:8] <= inst1[23:16];
		  inst2[7:0] <= inst1[31:24];
		  inst <= inst2;*/
		end
	end

endmodule
