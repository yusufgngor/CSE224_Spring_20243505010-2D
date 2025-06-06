//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:49:17
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu (
    input [31:0] src_a,
    input [31:0] src_b,
    input [2:0] alu_control, // 3 bits for 7 operations
    output reg [31:0] alu_result
);

    // ALU control codes (defined in instruction_decoder)
    parameter ALU_NOOP    = 3'b000;
    parameter ALU_ADD     = 3'b010;
    parameter ALU_SUB     = 3'b011;
    parameter ALU_SHIFTL  = 3'b100;
    parameter ALU_SHIFTR  = 3'b101;
    parameter ALU_ADDI    = 3'b110;
    parameter ALU_SUBI    = 3'b111;

    always @(*) begin
        case (alu_control)
            ALU_ADD, ALU_ADDI:   alu_result = src_a + src_b;
            ALU_SUB, ALU_SUBI:   alu_result = src_a - src_b;
            ALU_SHIFTL: alu_result = src_a << src_b[4:0]; // Shift amount is 5 bits for RISC-V
            ALU_SHIFTR: alu_result = src_a >> src_b[4:0];
            ALU_NOOP:   alu_result = 32'h0; // Or src_a, as it won't be written anyway
            default:    alu_result = 32'hX; // Undefined behavior
        endcase
    end

endmodule