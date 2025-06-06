`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:09:46
// Design Name: 
// Module Name: program_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Program Counter that handles increments, branches, and jumps.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Adapted to new control signals from decoder.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module program_counter (
    input clk,
    input reset,
    input step_pulse,           // Single pulse to advance PC (from debounced button)
    input branch_taken,         // From instruction_decoder
    input jump_taken,           // From instruction_decoder
    input [4:0] target_pc_address, // From instruction_decoder (already calculated target)
    output reg [4:0] pc_address   // Current PC address (word-based for instruction memory)
);

    // Define the maximum address for the instruction memory
    // If MEM_DEPTH is 32, max address is 31 (0 to 31).
    // Your previous PC_MAX_ADDR was 20 for 21 instructions.
    // Let's assume MEM_DEPTH is 32 from instruction_memory.v
    parameter PC_MAX_ADDR = 5'd31; // Max valid address (0 to MEM_DEPTH-1)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_address <= 5'd0;
        end else if (step_pulse) begin // Only advance PC on a single step pulse
            if (jump_taken) begin
                pc_address <= target_pc_address;
            end else if (branch_taken) begin
                pc_address <= target_pc_address;
            end else begin
                // Normal increment for non-branch/jump instructions
                if (pc_address < PC_MAX_ADDR) begin // Check against actual max index
                    pc_address <= pc_address + 5'd1;
                end else begin
                    pc_address <= 5'd0; // Loop back to start for continuous demo
                end
            end
        end
    end
endmodule