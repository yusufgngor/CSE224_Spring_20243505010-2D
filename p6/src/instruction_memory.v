`timescale 1ns / 1ps
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
// Description: Holds the program instructions.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Corrected instruction encodings for ADD, JAL, BEQ to standard.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory (
    input [4:0] pc_address,      // Word address from PC
    input control_input,         // General enable (e.g., from button, but typically always on)
    output [31:0] instruction_out
);

    parameter MEM_DEPTH = 32; // Number of memory locations (0 to 31)
    reg [31:0] mem [0:MEM_DEPTH-1];
    
    integer i;
    initial begin
        // Initialize all memory to NOOP first
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013; // Default NOOP (ADDI x0, x0, 0)
        end

        // Command List (1-indexed) to Memory Index (0-indexed) mapping:
        // Command 1 -> mem[0]
        // Command N -> mem[N-1]

        // Lab 5 Instructions
        mem[0] = 32'h00A00513; // 1. ADDI x10, x0, 10 (x10=10)
        mem[1] = 32'h00F00793; // 2. ADDI x15, x0, 15 (x15=15)
        // Corrected mem[2] to write to x25 (rd=11001)
        mem[2] = 32'h00F50CB3; // 3. ADD x25, x10, x15 (x25 = x10 + x15)
        mem[3] = 32'hFFBC8A13; // 4. SUBI x20, x25, 5 (ADDI x20, x25, -5) (x20=x25-5)
        mem[4] = 32'h00200A93; // 5. ADDI x21, x0, 2 (x21=2)

        // Lab 6 New Instructions (Using Standard RISC-V Encodings)
        // Command 6 (mem[5]): J 12 (target is Command 12 -> mem[11])
        // Current PC_idx=5. Target PC_idx=11. Word offset = 11-5 = 6 words. Byte offset = 6*4 = 24 bytes.
        // JAL x0, 24 (Standard J-type immediate encoding for 24)
        // imm[20] = 0 (offset_msb)
        // imm[10:1] = 24[10:1] = 0000110000
        // imm[11] = 24[11] = 0
        // imm[19:12] = 24[19:12] = 00000000
        // rd = x0 (00000)
        // opcode = JAL (1101111)
        // Enc: 0_0000110000_0_00000000_00000_1101111 => 32'h0180006F
        mem[5] = 32'h0180006F; // 6. JAL x0, mem[11] (Jump to instruction at mem[11])

        // Command 7 (mem[6]): SHIFTL reg30, reg7,reg21 (SLL x30, x7, x21)
        // rs1=x7(00111), rs2=x21(10101), rd=x30(11110)
        // funct7=0000000, rs2, rs1, funct3=001 (SLL), rd, opcode=0110011 (OP)
        mem[6] = 32'h01539F33; // 7. SLL x30, x7, x21 (x7 expected to be 0 if not set prior)

        // mem[7]  = NOOP (32'h00000013) // 8.
        // mem[8]  = NOOP (32'h00000013) // 9.
        // mem[9]  = NOOP (32'h00000013) // 10.
        // mem[10] = NOOP (32'h00000013) // 11.

        // Lab 6 Example Run Instructions (Original PC 12 -> our mem[11])
        mem[11] = 32'h00400213; // 12. ADDI x4, x0, 4 (x4=4)
        mem[12] = 32'h000002B3; // 13. ADD x5, x0, x0 (x5=0)

        // Command 14 (mem[13]): BEQ reg4, reg5, 7 (target is Command 7 -> mem[6])
        // Current PC_idx=13. Target PC_idx=6. Word offset = 6-13 = -7 words. Byte offset = -28 bytes.
        // BEQ x4, x5, -28 (Standard B-type immediate encoding for -28)
        // offset = -28 (0xFFFFFFE4)
        // imm[12] = 1 (offset_msb)
        // imm[10:5] = -28[10:5] = 111101
        // rs2=x5(00101), rs1=x4(00100), funct3=000 (BEQ)
        // imm[4:1] = -28[4:1] = 1100
        // imm[11] = -28[11] = 1
        // opcode = BRANCH (1100011)
        // Enc: imm12_imm10_5_rs2_rs1_f3_imm4_1_imm11_opcode
        //      1 _ 111101 _ 00101 _ 00100 _ 000 _ 1100 _ 1 _ 1100011
        //      11111010010100100000110011100011 => 32'hFA520CE3  -- Error in manual encoding.
        // Let's re-encode BEQ x4, x5, -28 (target mem[6] from mem[13])
        // offset = -28. imm values: imm[12], imm[11], imm[10:5], imm[4:1]
        // imm[12] = offset[12] = 1 (from -28 = ...11100100)
        // imm[11] = offset[11] = 1
        // imm[10:5] = offset[10:5] = 111001
        // imm[4:1] = offset[4:1] = 0100
        // Encoding: imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
        // 1_111001_00101_00100_000_0100_1_1100011
        // 11110010010100100000010011100011 => 32'hF25204E3
        mem[13] = 32'hF25204E3; // 14. BEQ x4, x5, (to instruction at mem[6])

        mem[14] = 32'h00100313; // 15. ADDI x6, x0, 1 (x6=1)
        mem[15] = 32'h00100393; // 16. ADDI x7, x0, 1 (x7=1)
        mem[16] = 32'h00730433; // 17. ADD x8, x6, x7 (x8=x6+x7)
        mem[17] = 32'h00038333; // 18. ADD x6, x7, x0 (x6=x7+x0)
        mem[18] = 32'h000403B3; // 19. ADD x7, x8, x0 (x7=x8+x0)
        mem[19] = 32'h00128293; // 20. ADDI x5, x5, 1 (x5=x5+1)

        // Command 21 (mem[20]): J 14 (target is Command 14 -> mem[13])
        // Current PC_idx=20. Target PC_idx=13. Word offset = 13-20 = -7 words. Byte offset = -28 bytes.
        // JAL x0, -28 (Standard J-type immediate encoding for -28)
        // offset = -28 (0xFFFFFFE4)
        // imm[20] = 1 (offset_msb)
        // imm[10:1] = -28[10:1] = 1111101000
        // imm[11] = -28[11] = 1
        // imm[19:12] = -28[19:12] = 11111111
        // rd = x0 (00000)
        // opcode = JAL (1101111)
        // Enc: 1_1111101000_1_11111111_00000_1101111 => 32'hFE4FF06F
        mem[20] = 32'hFE4FF06F; // 21. JAL x0, mem[13] (Jump to instruction at mem[13])
        
        // mem[21] to mem[31] are already NOOPs from the initial loop.
    end

    // Instruction output logic
    assign instruction_out = (control_input == 1'b1) ? mem[pc_address] : 32'h0; // Output 0 if not enabled

endmodule