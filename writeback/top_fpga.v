module top_module (
    input  wire        clock,        // 100 MHz
    input  wire        reset,        // Active-HIGH (BTNC)
    output wire [15:0] led           // LED[15:0] ACTIVE-LOW
);

    // --------------------------------------------------
    // Stimulus Memory (177 bits wide)
    // --------------------------------------------------
    reg [7:0] addr = 0;
    wire clk;

    // Based on removing next_pc: 177 bits total (176:0)
    (* rom_style = "block" *)
    reg [176:0] stimulus_mem [0:19]; // Increased depth to match addr limit

    initial begin
        // Use $readmemb for binary files (.mem)
        $readmemb("ex_out_b.mem", stimulus_mem);
    end

    // --------------------------------------------------
    // Clock Divider (Generates 1-sec enable pulse)
    // --------------------------------------------------
    clock_divider #(
        .DIVISOR(100_000_000)
    ) clk_div_u (
        .clk    (clock),
        .reset  (reset),
        .clk_en (clk)
    );

    // Address counter increments once per second
   always @(posedge clk) begin
    if (!reset)
        addr <= 0;
    else begin
        if (addr == 19)
                addr <= TODO
            else
                addr <= TODO
        end
end

    wire [176:0] stim = stimulus_mem[addr];

    // --------------------------------------------------
    // Stimulus Unpacking (177-bit Mapping)
    // --------------------------------------------------

// Unpack the wide stimulus word into individual WB inputs
// - Each field corresponds to a single WB input signal
// - Bit positions are fixed by the stimulus format


    wire [31:0] f_pc              = stim[176:145]; 
    wire [31:0] alu_operand1      = stim[144:113]; 
    wire [31:0] alu_operand2      = stim[112:81];  
    wire [31:0] write_address     = stim[80:49];   
    wire        branch_stall      = stim[48];      
    wire        branch_taken      = stim[47];      
    wire [31:0] wb_result         = stim[46:15];   
    wire        wb_mem_write      = stim[14];      
    wire        wb_alu_to_reg     = stim[13];      
    wire [4:0]  wb_dest_reg_sel   = stim[12:8];    
    wire        wb_branch         = stim[7];       
    wire        wb_branch_nxt     = stim[6];       
    wire        wb_mem_to_reg     = stim[5];       
    wire [1:0]  wb_read_address   = stim[4:3];     
    wire [2:0]  mem_alu_operation = stim[2:0];     

    // Dummy/Internal assignments for missing ports
    wire stall_read_i = branch_stall;
    wire [31:0] dmem_read_data_i = wb_result; 
    wire dmem_write_valid_i = 1'b1;

    // --------------------------------------------------
    // DUT Outputs
    // --------------------------------------------------
    wire [31:0] inst_mem_address_o, wb_write_address_o, wb_write_data_o;
    wire [31:0] wb_read_data_o, inst_fetch_pc_o;
    wire [3:0]  wb_write_byte_o;
    wire        inst_mem_is_ready_o, wb_stall_o, wb_stall_first_o, wb_stall_second_o;

    // --------------------------------------------------
    // DUT Instance
    // --------------------------------------------------
    wb #(
        .RESET(32'h0000_0000)
    ) uut (
        .clk(clk), // Use system clock
        .reset(!reset), // If WB uses Active-Low reset internally
        .stall_read_i(stall_read_i),
        .fetch_pc_i(f_pc),
        .wb_branch_i(wb_branch),
        .wb_mem_to_reg_i(wb_mem_to_reg),
        .mem_write_i(wb_mem_write),
        .write_address_i(write_address),
        .alu_operand2_i(alu_operand2),
        .alu_operation_i(mem_alu_operation),
        .wb_alu_operation_i(mem_alu_operation),
        .wb_read_address_i(wb_read_address),
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

    // Map PC to LEDs (Inverted for Active-Low)
    assign led = f_pc;

endmodule

// --------------------------------------------------
// Clock Divider Module
// --------------------------------------------------
module clock_divider #(
    parameter DIVISOR = 100_000_000
)(
    input  wire clk,
    input  wire reset,
    output reg  clk_en
);
    reg [26:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            clk_en <= 1'b0;
        end
        else if (counter == DIVISOR-1) begin
            counter <= 0;
            clk_en <= 1'b1; // Single cycle pulse
        end
        else begin
            counter <= counter + 1;
            clk_en <= 1'b0;
        end
    end
endmodule
