//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:39:26
// Design Name: 
// Module Name: instruction_memory
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


module instruction_memory (
    input [4:0] pc_address,
    input control_input, // From button, affects output
    output [31:0] instruction_out
);

    reg [31:0] mem [0:31]; // Up to 32 instructions

    initial begin
        // Pre-load instructions as per the lab description
        mem[0] = 32'h00A00513; // 1. ADDI reg10, reg0, 10
        mem[1] = 32'h00F00793; // 2. ADDI reg15, reg0, 15
        mem[2] = 32'h01F50C13; // 3. ADD reg25, reg10, reg15
        mem[3] = 32'h005C9A13; // 4. SUBI reg20, reg25, 5
        mem[4] = 32'h00200293; // 5. ADDI reg5, reg0, 2
        mem[5] = 32'h005CD773; // 6. SHIFTL reg30, reg25, reg5
        mem[6] = 32'h00000013; // ADDI x0, x0, 0 (a common NOOP)
        for (integer i = 6; i < 32; i = i + 1) begin
            mem[i] = 32'h00000013; // Default NOOP for unused memory
        end
    end

    // Instruction output logic
    assign instruction_out = (control_input == 1'b1) ? mem[pc_address] : 32'h0;

endmodule