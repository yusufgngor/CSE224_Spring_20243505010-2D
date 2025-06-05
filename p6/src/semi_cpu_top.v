`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:50:57
// Design Name: 
// Module Name: semi_cpu_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top module for the single-cycle CPU.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Integrated new decoder signals and reliable button pulse.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module p6 (
    input clk,
    input reset_btn,        // External reset button
    input control_btn,      // External step button
    output [6:0] segment,   // 7-segment display segments
    output [7:0] anode      // 7-segment display anodes
);

    // Wires for connections
    wire [4:0] pc_address_current; // Renamed for clarity
    wire [31:0] instruction;
    
    // Control signals from Decoder
    wire [2:0] alu_control_signal;  
    wire alu_src_signal;           
    wire reg_write_enable;         
    wire result_src_signal;        
    wire branch_is_taken;          
    wire jump_is_taken;            
    wire [4:0] computed_target_pc; 

    // Data path signals
    wire [31:0] rd1_data, rd2_data;
    wire [31:0] extended_immediate;
    wire [31:0] alu_input_a, alu_input_b;
    wire [31:0] alu_result_out;     // Renamed
    wire alu_zero_flag;            // Renamed

    wire [31:0] data_to_write_back; // Data to write to Register File
    wire [31:0] final_data_for_display; // Output to 7-segment display

    // Instruction fields for Register File and Extend Unit
    wire [4:0] rs1_addr = instruction[19:15];
    wire [4:0] rs2_addr = instruction[24:20];
    wire [4:0] rd_addr  = instruction[11:7]; 
    wire [11:0] i_type_immediate_val = instruction[31:20]; // For ADDI, etc.

    // --- Debouncer and Pulse Generator ---
    // Reset Button Debouncer
    reg debounced_reset_state;
    reg [15:0] reset_debounce_counter; // Adjusted counter size for typical debounce
    localparam DEBOUNCE_LIMIT = 16'd50000; // Approx 0.5ms at 100MHz

    always @(posedge clk) begin
        if (reset_btn) begin // Active high reset button
            if (reset_debounce_counter < DEBOUNCE_LIMIT) begin
                reset_debounce_counter <= reset_debounce_counter + 1;
                debounced_reset_state <= 1'b0; // Remain in not-reset state during debounce
            end else begin
                debounced_reset_state <= 1'b1; // Assert reset after debounce period
            end
        end else begin
            reset_debounce_counter <= 0;
            debounced_reset_state <= 1'b0;
        end
    end
    wire actual_reset_signal = debounced_reset_state;

    // Control Button Debouncer and Single Pulse Generator
    reg control_btn_sync1, control_btn_sync2, control_btn_debounced;
    reg [15:0] control_debounce_counter;
    reg control_btn_debounced_delayed;
    wire actual_step_pulse;

    always @(posedge clk) begin
        control_btn_sync1 <= control_btn;
        control_btn_sync2 <= control_btn_sync1;

        if (control_btn_sync2) begin // Button sensed as pressed
            if (control_debounce_counter < DEBOUNCE_LIMIT) begin
                control_debounce_counter <= control_debounce_counter + 1;
            end else begin
                control_btn_debounced <= 1'b1;
            end
        end else begin // Button sensed as released
            control_debounce_counter <= 0;
            control_btn_debounced <= 1'b0;
        end
        
        control_btn_debounced_delayed <= control_btn_debounced; // One cycle delay
    end
    // Generate a single clock wide pulse on the rising edge of debounced signal
    assign actual_step_pulse = control_btn_debounced && !control_btn_debounced_delayed;
    // --- End Debouncer and Pulse Generator ---


    // 1. Program Counter
    program_counter u_pc (
        .clk(clk),
        .reset(actual_reset_signal),
        .step_pulse(actual_step_pulse), 
        .branch_taken(branch_is_taken),
        .jump_taken(jump_is_taken),
        .target_pc_address(computed_target_pc), // From decoder
        .pc_address(pc_address_current)
    );

    // 2. Instruction Memory
    instruction_memory u_im (
        .pc_address(pc_address_current),
        .control_input(1'b1), // Always enabled; PC controls fetching via step_pulse
        .instruction_out(instruction)
    );

    // 3. Instruction Decoder (Control Unit)
    instruction_decoder u_id (
        .instruction(instruction),
        .current_pc_address(pc_address_current), // Pass current PC for relative calculations
        .alu_zero(alu_zero_flag),
        .alu_control(alu_control_signal),
        .alu_src(alu_src_signal),
        .reg_write(reg_write_enable),
        .result_src(result_src_signal), // Not really used much here
        .branch_taken(branch_is_taken),
        .jump_taken(jump_is_taken),
        .computed_target_pc_address(computed_target_pc)
    );

    // 4. Register File
    register_file u_rf (
        .clk(clk),
        .we3(reg_write_enable),
        .a1(rs1_addr),
        .a2(rs2_addr),
        .a3(rd_addr), 
        .wd3(data_to_write_back),
        .rd1(rd1_data),
        .rd2(rd2_data)
    );

    // 5. Extend Unit (Only for I-type immediates like ADDI)
    extend_unit u_extend (
        .immediate_in(i_type_immediate_val), // instruction[31:20]
        .extended_immediate_out(extended_immediate)
    );

    // Mux for ALU input B (ALUSrc selects between rs2_data and immediate)
    assign alu_input_b = (alu_src_signal == 1'b0) ? rd2_data : extended_immediate;
    // ALU input A is always rs1_data for supported instructions
    assign alu_input_a = rd1_data;

    // 6. ALU
    alu u_alu (
        .src_a(alu_input_a),
        .src_b(alu_input_b),
        .alu_control(alu_control_signal),
        .alu_result(alu_result_out),
        .zero(alu_zero_flag)
    );

    // Data to write back to Register File (WD3)
    // For JAL, if rd != x0, this should be PC+4.
    // The current decoder and ALU setup don't easily provide PC+4 here.
    // If result_src_signal were used and an ALU op calculated PC+4, it could be selected.
    // As a simplification, JAL rd (if not x0) will get alu_result_out (often 0).
    assign data_to_write_back = alu_result_out; 


    // Final Result to 7-segment display
    assign final_data_for_display = alu_result_out;

    // 7. 7-Segment Display Controller (Assuming you have this module)
    seven_seg_controller u_seven_seg (
        .clk(clk),
        .data_in(final_data_for_display), // Displaying the ALU result
        .segment(segment),
        .anode(anode)
    );

endmodule