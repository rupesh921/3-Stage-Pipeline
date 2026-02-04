`timescale 1ns/1ps
module tb_execute;

/////////////////////////////////////////////// PARAMETERS/////////////////////////////////////////////////////////////
parameter INPUT_LOG  = "if_id_output.txt";
parameter OUTPUT_LOG = "execute_output.txt";

/////////////////////////////////////////////////////////////// CLOCK & RESET////////////////////////////////////////
reg clk;
reg reset;

/////////////////////////////////////////////////////////////// DUT INPUTS/////////////////////////////////////////////////////////////
reg [31:0] reg_rdata1;
reg [31:0] reg_rdata2;
reg [31:0] execute_imm;
reg [31:0] pc;
reg [31:0] fetch_pc;

reg immediate_sel;
reg mem_write;
reg jal;
reg jalr;
reg lui;
reg alu;
reg branch;
reg arithsubtype;
reg mem_to_reg;
reg stall_read;

reg [4:0] dest_reg_sel;
reg [2:0] alu_op;
reg [1:0] dmem_raddr;

reg wb_branch_i;
reg wb_branch_nxt_i;

/////////////////////////////////////////////////////////////// DUT OUTPUTS/////////////////////////////////////////////////////////////
   wire [31:0] alu_operand1;
   wire [31:0] alu_operand2;
	wire [31:0] write_address;
	wire    	branch_stall;

	wire  [31:0] next_pc;
	wire     	branch_taken;

	// -----------------------------
	// EX → WB
	// -----------------------------
	wire [31:0] wb_result;
	wire    	wb_mem_write;
	wire    	wb_alu_to_reg;
	wire [4:0]  wb_dest_reg_sel;
	wire    	wb_branch;
	wire    	wb_branch_nxt;
	wire    	wb_mem_to_reg;
	wire [1:0]  wb_read_address;
	wire [2:0]  mem_alu_operation;

/////////////////////////////////////////////////////////////// FILE HANDLES/////////////////////////////////////////////////////////////
integer in_fd;
integer out_fd;
reg [1023:0] line;

reg illegal_inst_w;
reg exception_w;

/////////////////////////////////////////////////////////////// DUT INSTANCE/////////////////////////////////////////////////////////////
execute dut (
	.clk           	(clk),
	.reset         	(reset),

	.reg_rdata1    	(reg_rdata1),
	.reg_rdata2    	(reg_rdata2),
	.execute_imm   	(execute_imm),
	.pc            	(pc),
	.fetch_pc      	(fetch_pc),

	.immediate_sel 	(immediate_sel),
	.mem_write     	(mem_write),
	.jal           	(jal),
	.jalr          	(jalr),
	.lui           	(lui),
	.alu           	(alu),
	.branch        	(branch),
	.arithsubtype  	(arithsubtype),
	.mem_to_reg    	(mem_to_reg),
	.stall_read    	(stall_read),

	.dest_reg_sel  	(dest_reg_sel),
	.alu_op        	(alu_op),
	.dmem_raddr    	(dmem_raddr),

	.wb_branch_i   	(wb_branch_i),
	.wb_branch_nxt_i   (wb_branch_nxt_i),

	.alu_operand1 	(alu_operand1),
	.alu_operand2 	(alu_operand2),
	.write_address	(write_address),

	.next_pc       	(next_pc),
	.branch_taken  	(branch_taken),
	.branch_stall  	(branch_stall),

	.wb_result     	(wb_result),
	.wb_mem_write  	(wb_mem_write),
	.wb_alu_to_reg 	(wb_alu_to_reg),
	.wb_dest_reg_sel   (wb_dest_reg_sel),
	.wb_branch     	(wb_branch),
	.wb_branch_nxt 	(wb_branch_nxt),
	.wb_mem_to_reg 	(wb_mem_to_reg),
	.wb_read_address   (wb_read_address),
	.mem_alu_operation (mem_alu_operation)
);

/////////////////////////////////////////////////////////////// CLOCK/////////////////////////////////////////////////////////////
always #5 clk = ~clk;

/////////////////////////////////////////////////////////////// TEST SEQUENCE/////////////////////////////////////////////////////////////
initial begin
	clk = 0;
	reset = 0;

	// Stable defaults
	reg_rdata1 = 32'h10;
	reg_rdata2 = 32'h04;
	stall_read = 0;
	wb_branch_i = 0;
	wb_branch_nxt_i = 0;
	dmem_raddr = 2'b00;


	// TODO-TB-1:
	// Initialize file handles for trace-driven simulation
	// - Open the input trace file for reading IF/ID stage outputs (which are inputs to execute stage)
	// - Open the output log file for writing Execute-stage results
	// - Simulation must terminate with an error if either file cannot be opened
	// - These file handles will be used throughout the testbench for I/O

	in_fd  = INPUT_LOG;
	out_fd = OUTPUT_LOG;

	if (in_fd == 0) begin
    	$display("ERROR: Cannot open if_id_output.txt");
    	$finish;
	end

	// Skip header
	$fgets(line, in_fd);

 
	// Apply reset
	#20 reset = 1;
 	$fwrite(out_fd,
 	"pc alu_operand1 alu_operand2 write_address branch_stall next_pc branch_taken wb_result wb_mem_write wb_alu_to_reg wb_dest_reg_sel wb_branch wb_branch_nxt wb_mem_to_reg wb_read_address mem_alu_operation\n",
	);
	/////////////////////////////////////////////////////////////// MAIN TRACE-DRIVEN LOOP///////////////////////////////////////
	while (!$feof(in_fd)) begin
    	$fgets(line, in_fd);
    	@(posedge clk);

    	// Parse IF/ID output line
    	$sscanf(line,
      	"%h %h %b %b %b %b %b %b %b %b %b %b %b %b",
      	pc,
      	execute_imm,
      	immediate_sel,
      	alu,
      	lui,
      	jal,
      	jalr,
      	branch,
      	mem_write,
      	mem_to_reg,
      	dest_reg_sel,
      	alu_op,
      	illegal_inst_w,
      	exception_w
    	);

    	fetch_pc 	= pc;
    	arithsubtype = alu_op[2];

    	@(posedge clk); // allow EX/MEM/WB register update
	// Output header

    	// Log EX outputs
$fwrite(out_fd,
"%h %h %h %h %b %h %b %h %b %b %b %b %b %b %b %b\n",
pc,
alu_operand1,
alu_operand2,
write_address,
branch_stall,

next_pc,
branch_taken,
wb_result,
wb_mem_write,
wb_alu_to_reg,
wb_dest_reg_sel,
wb_branch,
wb_branch_nxt,
wb_mem_to_reg,
wb_read_address,
mem_alu_operation
);
	end
	$fclose(in_fd);
	$fclose(out_fd);
	#20 $finish;
end
endmodule
