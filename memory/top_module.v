`timescale 1ns / 1ps

//======================================================
// Top-level FPGA module
//======================================================
module top_fpga (
	input  wire    	CLK100MHZ,   // 100 MHz board clock
	input  wire [15:0] sw,       	// sw[3:0] = address, sw[15] = hi/lo select
	output wire [15:0] led        	// 16 onboard LEDs
);

	wire [31:0] full_instr;
	wire    	clk_en;

	// Map switches to word-aligned PC
	wire [31:0] current_pc = {26'b0, sw[3:0], 2'b00};

	// Clock divider (generates 1-cycle enable pulse)
	clock_divider #(
    	.DIVISOR(100_000_000)     	// 1 Hz enable from 100 MHz clock
	) clk_div_inst (
    	.clk	(CLK100MHZ),
    	.reset  (1'b0),           	// no external reset
    	.clk_en (clk_en)
	);

	// Instruction memory
	instr_mem imem_inst (
    	.clk   (CLK100MHZ),       	// run at full speed
		.pc(current_pc)
	// TODO-TOP-MEM-1: Instantiate IMEM
	);

	// Display upper or lower 16 bits of instruction
   // Only output the lower 16 bits to the LEDs
assign led = full_instr[15:0];

endmodule


//======================================================
// Clock Divider (clock enable generator)
//======================================================
module clock_divider #(
	parameter DIVISOR = 100_000_000
)(
	input  wire clk,
	input  wire reset,
	output reg  clk_en
);

	reg [$clog2(DIVISOR)-1:0] counter;

	always @(posedge clk) begin
    	if (reset) begin
        	counter <= 0;// TODO
        	clk_en  <= 1'b0;
    	end else if (counter == DIVISOR - 1) begin
        	counter <= 0;
        	clk_en  <= 1'b1;   // one-cycle pulse
    	end else begin
        	counter <= counter + 1;// TODO: Counter?
        	clk_en  <= 1'b0;
    	end
	end

endmodule


