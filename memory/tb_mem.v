`timescale 1ns / 1ps

module tb_mem_top();

	// Clock and Control Signals
	reg clk;
	reg [31:0] pc;
	wire [31:0] instr;

	// DMEM Signals
	reg re, we;
	reg [31:0] raddr, waddr, wdata;
	reg [3:0]  wstrb;
	wire [31:0] rdata;

	instr_mem uut_imem (
		.clk(clk),
		.pc(pc),
		.instr(instr)
	);

	data_mem uut_dmem (
    	// TODO-TB-MEM-2: Instantiate DMEM
		.clk(clk),
		.re(re),
		.raddr(raddr),
		.we(we),
		.waddr(waddr),
		.wdata(wdata),
		.wstrb(wstrb)
	);

	// 100MHz Clock Generation
	always #5 clk = ~clk;
	integer i, f;
	initial begin
    	// Initialize Signals
    	clk = 0;
    	pc = 0;
    	re = 0;
    	we = 0;
    	raddr = 0;
    	waddr = 0;
    	wdata = 0;
    	wstrb = 4'b0000;
    	// Wait for memory to load from hex via internal initial block
    	#20;
    	f = $fopen("output.txt", "w");
    	if (f == 0) begin
        	$display("Error: Could not create output.txt");
        	$finish;
    	end
    	for (i = 0; i < 17; i = i + 1) begin
        	$fwrite(f, "%h\n", uut_imem.imem[i]);
    	end
    	$fclose(f);
    	@(posedge clk);
    	for (i = 0; i < 20; i = i + 1) begin
        	pc = i * 4; // Byte addressing: 0, 4, 8, 12...
        	@(posedge clk);
        	#1; // Wait for sync output
        	$display("PC: %h | Instr: %h", pc, instr);
    	end

    	$display("Starting DMEM Write/Read Test...");
    	@(posedge clk);
    	we = 1;
    	waddr = 32'h0000_0010;
    	wdata = 32'hDEADBEEF;
    	wstrb = 4'b1111; // Full word write
            	// Read same cycle to test byte-level forwarding logic
    	re = 1;
    	raddr = 32'h0000_0010;
    	@(posedge clk);
    	#1;
    	we = 0;
    	re = 0;
    	$display("DMEM Readback (Forwarded): %h", rdata);
    	#50;
    	$display("Simulation Finished.");
    	$finish;
	end
endmodule
