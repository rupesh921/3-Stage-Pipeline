module instr_mem (
	input  wire    	clk,
	input  wire [31:0] pc, 	// byte address
	output reg  [31:0] instr
);

	// 1024 words = 4 KB
	// Declare instruction memory array (word-addressable, 4 KB total)
	(* ram_style = "block" *)
	reg [31:0] imem [0:1023];

	// FPGA ROM initialization
	// Initialize instruction memory from hex file (simulation / FPGA)
	initial begin
    	$readmemh("imem.hex", imem);
	end

	// Synchronous instruction fetch
	// Use word-aligned PC (pc[11:2]) to index memory
	always @(posedge clk) begin
    	instr <= imem[pc[11:2]];	// word address
	end

endmodule



//====================================
// Data Memory (DMEM) - FPGA-safe
//====================================
module data_mem (
	input     	clk,

	// Read port
	input     	re,
	input  [31:0] raddr,   // byte address
	output reg [31:0] rdata,

	// Write port
	input     	we,
	input  [31:0] waddr,   // byte address
	input  [31:0] wdata,
	input  [3:0]  wstrb
);

	// Declare data memory array (word-addressable, 4 KB total)
	// TODO-DMEM-1: Declare dmem
	reg [31:0] dmem [0:1023]; // idhar how to write the order of bits like 0:1023 or 1023:0
	// Decode byte address to word index
	wire [9:0] rindex = raddr[11:2];
	wire [9:0] windex = waddr[11:2];

	// Simulation / FPGA init
	// TODO-DMEM-2: Initialize data memory from dmem.hex file
	initial begin
		$readmemh("dmem.hex", dmem);
	end

	// -------------------------
	// WRITE + READ (SYNC)
	// -------------------------

	// Synchronous write and read logic
	// - Support byte-wise writes using wstrb
	// - Provide 1-cycle read latency
	// - Handle same-cycle read-after-write using byte-level forwarding

	always @(posedge clk) begin
    	// ---- WRITE ----
    	if (we) begin
        	if (wstrb[0]) dmem[windex][7:0]   <= wdata[7:0];
        	if (wstrb[1]) dmem[windex][15:8]  <= wdata[15:8];
			if (wstrb[2]) dmem[windex][23:16] <= wdata[23:16];// TODO-DMEM-3
			if (wstrb[3]) dmem[windex][31:24] <= wdata[31:24];// TODO-DMEM-3
    	end

    	// ---- READ (1-cycle latency, RAW-safe) ----
    	if (re) begin
        	if (we && (rindex == windex)) begin
            	// Byte-level forwarding
            	rdata[7:0]   <= wstrb[0] ? wdata[7:0]   : dmem[rindex][7:0];
				rdata[15:8]  <= wstrb[1] ? wdata[15:8]  : dmem[rindex][15:8];// TODO-DMEM-3
				rdata[23:16] <= wstrb[2] ? wdata[23:16]  : dmem[rindex][23:16];// TODO-DMEM-3
				rdata[31:24] <= wstrb[3] ? wdata[31:24]  : dmem[rindex][31:24];// TODO-DMEM-3
        	end
        	else begin
            	rdata <= dmem[rindex];
        	end
    	end
    	//else: rdata holds value (exact match to original)
		else begin
			rdata <= rdata;// doubt
	end

endmodule
