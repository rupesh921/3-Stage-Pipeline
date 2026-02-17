`timescale 1ns / 1ps

module wb_tb;

    // ---------------------------------------------------------
    // DUT Signals
    // ---------------------------------------------------------
    reg clk;
    reg reset;
    reg stall_read_i;
    reg [31:0] fetch_pc_i;
    reg wb_branch_i;
    reg wb_mem_to_reg_i;
    reg mem_write_i;
    reg [31:0] write_address_i;
    reg [31:0] alu_operand2_i;
    reg [2:0]  alu_operation_i;
    reg [2:0]  wb_alu_operation_i;
    reg [1:0]  wb_read_address_i;
    reg [31:0] dmem_read_data_i;
    reg        dmem_write_valid_i;

    // Output Wires
    wire [31:0] inst_mem_address_o;
    wire        inst_mem_is_ready_o;
    wire        wb_stall_o;
    wire [31:0] wb_write_address_o;
    wire [31:0] wb_write_data_o;
    wire [3:0]  wb_write_byte_o;
    wire [31:0] wb_read_data_o;
    wire [31:0] inst_fetch_pc_o;
    wire        wb_stall_first_o;
    wire        wb_stall_second_o;

    // ---------------------------------------------------------
    // File I/O Variables
    // ---------------------------------------------------------
    integer in_file, out_file, status;
    reg [2047:0] header_buffer;
    
    // File Column Mapping Variables
    reg [31:0] f_pc, f_alu1, f_alu2, f_waddr, f_nextpc, f_wb_res;
    reg f_bstall, f_btaken, f_mwr, f_alu2reg, f_wb_br, f_wb_br_nxt, f_m2reg;
    reg [4:0] f_dest;
    reg [1:0] f_raddr;
    reg [2:0] f_alu_op;

    // ---------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------
    wb #(
        .RESET(32'h0000_0000)
    ) uut (
        .clk(clk),
        .reset(reset),
        .stall_read_i(stall_read_i),
        .fetch_pc_i(fetch_pc_i),
        .wb_branch_i(wb_branch_i),
        .wb_mem_to_reg_i(wb_mem_to_reg_i),
        .mem_write_i(mem_write_i),
        .write_address_i(write_address_i),
        .alu_operand2_i(alu_operand2_i),
        .alu_operation_i(alu_operation_i),
        .wb_alu_operation_i(wb_alu_operation_i),
        .wb_read_address_i(wb_read_address_i),
        .dmem_read_data_i(dmem_read_data_i),
        .dmem_write_valid_i(dmem_write_valid_i),
        .inst_mem_address_o(inst_mem_address_o),
        .inst_mem_is_ready_o(inst_mem_is_ready_o),
        .wb_stall_o(wb_stall_o),
        .wb_write_address_o(wb_write_address_o),
        .wb_write_data_o(wb_write_data_o),
        .wb_write_byte_o(wb_write_byte_o),
        .wb_read_data_o(wb_read_data_o),
        .inst_fetch_pc_o(inst_fetch_pc_o),
        .wb_stall_first_o(wb_stall_first_o),
        .wb_stall_second_o(wb_stall_second_o)
    );

    // ---------------------------------------------------------
    // Clock Generation
    // ---------------------------------------------------------
    always #5 clk = ~clk; 

    // ---------------------------------------------------------
    // Main Simulation Block
    // ---------------------------------------------------------
    initial begin
        

        // Signal initialization
        clk = 0;
        reset = 0; // Active Low Reset
        stall_read_i = 0;
        dmem_read_data_i = 32'h0;
        dmem_write_valid_i = 1;

        // Open Files
        in_file = $fopen("execute_output.txt", "r");
        out_file = $fopen("output.txt", "w");

        if (in_file == 0) begin
	       // Simulation must terminate if input file is missing
	       // TODO
			$display("ERROR: Cannot open execute_output.txt");
    		$finish;
        end

     
        status = $fgets(header_buffer, in_file); 
    

        #20 reset = 1; 

     $fdisplay(out_file, "inst_fetch_pc_o | wb_stall_o | wb_stall_first_o | wb_stall_second_o | wb_write_address_o | wb_write_data_o | wb_write_byte_o | wb_read_data_o | inst_mem_address_o | inst_mem_is_ready_o");
        $fdisplay(out_file, "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");

        while (!$feof(in_file)) begin
            status = $fscanf(in_file, "%h %h %h %h %b %h %b %h %b %b %h %b %b %b %b %h", 
                             f_pc, f_alu1, f_alu2, f_waddr, f_bstall, f_nextpc, f_btaken, 
                             f_wb_res, f_mwr, f_alu2reg, f_dest, f_wb_br, f_wb_br_nxt, 
                             f_m2reg, f_raddr, f_alu_op);

            if (status == 16) begin
                @(posedge clk);
                #2; 
                fetch_pc_i         <= f_pc;
                alu_operand2_i     <= f_alu2;
                write_address_i    <= f_waddr;
                mem_write_i        <= f_mwr;
                wb_branch_i        <= f_wb_br;
                wb_mem_to_reg_i    <= f_m2reg;
                wb_read_address_i  <= f_raddr;
                alu_operation_i    <= f_alu_op;
                wb_alu_operation_i <= f_alu_op;
                dmem_read_data_i   <= f_wb_res; 

                @(negedge clk);
                // The formatting below uses %16h to ensure 32-bit hex values stay aligned under their headers
                $fdisplay(out_file, "%16h | %10b | %16b | %17b | %18h | %15h | %15b | %14h | %17h | %18b", 
                         
                          inst_fetch_pc_o, 
                          wb_stall_o, 
                          wb_stall_first_o, 
                          wb_stall_second_o,
                          wb_write_address_o, 
                          wb_write_data_o, 
                          wb_write_byte_o, 
                          wb_read_data_o,
                          inst_mem_address_o, 
                          inst_mem_is_ready_o);
            end
        end

        $display("Simulation Finished. Results saved to output.txt and wb_stage_results.vcd.");

// Close all opened files and cleanly terminate the simulation
// TODO
		$fclose(in_file);
		$fclose(out_file);
		#20 $finish;

    end

endmodule
