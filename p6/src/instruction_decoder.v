`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:47:04
// Design Name: 
// Module Name: instruction_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Decodes RISC-V instructions and generates control signals.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Modified for standard JAL/BEQ, refined outputs.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module instruction_decoder (
    input [31:0] instruction,
    input [4:0] current_pc_address, // Current PC word address (for PC-relative)
    input alu_zero,                 // From ALU: indicates if ALUResult was zero
    output reg [2:0] alu_control,
    output reg alu_src,             // 0: rs2_data, 1: immediate
    output reg reg_write,           // Enable writing to register file
    output reg result_src,          // 0: ALU result, (1: Mem data - not used in this CPU)
    output reg branch_taken,        // True if a conditional branch is taken
    output reg jump_taken,          // True if an unconditional jump (JAL, JALR) is taken
     output reg [4:0] computed_target_pc_address   // PC selection: 0=PC+1, 1=BranchTarget, 2=JumpTarget
                                    // Simplified for this lab: direct target for PC
);
    // Output for PC module
    // The target word address for JAL/BEQ

    // Decode fields from standard RISC-V
    wire [6:0] opcode  = instruction[6:0];
    wire [4:0] rd      = instruction[11:7];
    wire [2:0] funct3  = instruction[14:12];
    wire [4:0] rs1     = instruction[19:15];
    wire [4:0] rs2     = instruction[24:20];
    wire [6:0] funct7  = instruction[31:25];

    // Standard RISC-V Opcodes
    parameter OPC_LUI     = 7'b0110111;
    parameter OPC_AUIPC   = 7'b0010111;
    parameter OPC_JAL     = 7'b1101111;
    parameter OPC_JALR    = 7'b1100111;
    parameter OPC_BRANCH  = 7'b1100011; // BEQ, BNE, BLT, BGE, BLTU, BGEU
    parameter OPC_LOAD    = 7'b0000011; // LB, LH, LW, LBU, LHU
    parameter OPC_STORE   = 7'b0100011; // SB, SH, SW
    parameter OPC_OP_IMM  = 7'b0010011; // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    parameter OPC_OP      = 7'b0110011; // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    parameter OPC_FENCE   = 7'b0001111;
    parameter OPC_SYSTEM  = 7'b1110011; // ECALL, EBREAK, CSRxx

    // ALU control signals (internal definition for this decoder)
    // These are the values this decoder will output on 'alu_control'
    parameter ALU_CTRL_ADD     = 3'b000; // For ADD, ADDI
    parameter ALU_CTRL_SUB     = 3'b001; // For SUB, SUBI, BEQ comparison
    parameter ALU_CTRL_SLL     = 3'b010; // For SLL, SLLI
    parameter ALU_CTRL_SLT     = 3'b011; // For SLT, SLTI
    parameter ALU_CTRL_SLTU    = 3'b100; // For SLTU, SLTIU
    parameter ALU_CTRL_XOR     = 3'b101; // For XOR, XORI
    parameter ALU_CTRL_SRL_SRA = 3'b110; // For SRL, SRLI, SRA, SRAI (differentiated by funct7 for SRA)
    parameter ALU_CTRL_OR      = 3'b111; // For OR, ORI
    // Let's remap your ALU's expected inputs to these.
    // Your ALU expected: ADD/ADDI: 010/110, SUB/SUBI: 011/111, SHIFTL:100, SHIFTR:101, NOOP:000
    // Re-mapping decoder's ALU_CTRL to match your ALU's case statements:
    // Original Decoder Params -> Your ALU Case value
    // ALU_ADD (010 from your alu)
    // ALU_SUB (011 from your alu)
    // ALU_SHIFTL (100 from your alu)
    // ALU_SHIFTR (101 from your alu)
    // ALU_ADDI (110 from your alu)
    // ALU_SUBI (111 from your alu)
    // ALU_NOOP (000 from your alu)
    
    // Revised alu_control values to match your ALU's case:
    parameter MY_ALU_NOOP    = 3'b000;
    parameter MY_ALU_ADD     = 3'b010;
    parameter MY_ALU_SUB     = 3'b011;
    parameter MY_ALU_SHIFTL  = 3'b100;
    parameter MY_ALU_SHIFTR  = 3'b101;
    parameter MY_ALU_ADDI    = 3'b110;
    parameter MY_ALU_SUBI    = 3'b111;


    // Immediates
    wire [11:0] i_imm = instruction[31:20]; // For I-type (ADDI, JALR, LOAD)
    wire [11:0] s_imm = {instruction[31:25], instruction[11:7]}; // For S-type (STORE)
    wire [12:0] b_imm_temp = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]}; // For B-type
    wire signed [12:0] b_imm = {b_imm_temp[12], b_imm_temp[11:1], 1'b0}; // Shifted by 1, sign-extended
    
    wire [20:0] j_imm_temp = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]}; // For J-type
    wire signed [20:0] j_imm = {j_imm_temp[20], j_imm_temp[19:1], 1'b0}; // Shifted by 1, sign-extended

    // Target PC calculation (simplified for 5-bit word address)
    // For branches, offset is in bytes. Target = PC_bytes + offset_bytes. Then /4 for word address.
    // current_pc_address is already word address.
    // b_imm is byte offset. So (current_pc_address * 4 + b_imm) / 4 = current_pc_address + (b_imm / 4)
    // j_imm is byte offset. So (current_pc_address * 4 + j_imm) / 4 = current_pc_address + (j_imm / 4)
    
    // Since b_imm and j_imm are already effectively shifted left by 1 (LSB is 0),
    // dividing by 4 means shifting right by 2.
    // So, (b_imm >> 2) or (j_imm >> 2) gives the word offset.
    wire signed [31:0] branch_word_offset = $signed(b_imm) >>> 2; // Arithmetic shift right by 2
    wire signed [31:0] jump_word_offset   = $signed(j_imm) >>> 2;   // Arithmetic shift right by 2


    always @(*) begin
        // Default values
        alu_control       = MY_ALU_NOOP;
        alu_src           = 1'b0;   // Default to rs2_data
        reg_write         = 1'b0;   // Default no write
        result_src        = 1'b0;   // Default to ALU result (as no memory loads to WB)
        branch_taken      = 1'b0;
        jump_taken        = 1'b0;
        computed_target_pc_address = current_pc_address + 1; // Default next PC

        if (instruction == 32'h00000013 || instruction == 32'h0) begin // Canonical NOOP (ADDI x0, x0, 0)
            alu_control = MY_ALU_ADDI; // Or NOOP, but ADDI x0,x0,0 is fine
            alu_src = 1'b1; // Immediate (0)
            reg_write = 1'b0; // (as rd=x0) or 1'b1 if we want to strictly follow ADDI
        end else begin
            case (opcode)
                OPC_OP_IMM: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                    reg_write = (rd != 5'd0); // Write if rd is not x0
                    alu_src   = 1'b1;         // Use immediate
                    case (funct3)
                        3'b000: alu_control = MY_ALU_ADDI;   // ADDI
                        3'b001: alu_control = MY_ALU_SHIFTL; // SLLI (funct7[6] must be 0)
                        // Add others like SLTI, XORI, ORI, ANDI, SRLI, SRAI if needed
                        // 3'b101: // SRLI / SRAI
                        //    if (funct7[5] == 1'b0) alu_control = MY_ALU_SHIFTR; // SRLI
                        //    else alu_control = MY_ALU_SRA; // SRAI (need SRA in ALU)
                        default: alu_control = MY_ALU_NOOP; // Undefined funct3
                    endcase
                end

                OPC_OP: begin // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                    reg_write = (rd != 5'd0);
                    alu_src   = 1'b0;         // Use rs2_data
                    case (funct3)
                        3'b000: begin // ADD or SUB
                            if (funct7 == 7'b0000000) alu_control = MY_ALU_ADD; // ADD
                            else if (funct7 == 7'b0100000) alu_control = MY_ALU_SUB; // SUB
                            else alu_control = MY_ALU_NOOP;
                        end
                        3'b001: begin // SLL
                            if (funct7 == 7'b0000000) alu_control = MY_ALU_SHIFTL;
                            else alu_control = MY_ALU_NOOP;
                        end
                        // Add others like SLT, XOR, SRL, SRA, OR, AND
                        // 3'b101: begin // SRL / SRA
                        //    if (funct7 == 7'b0000000) alu_control = MY_ALU_SHIFTR; // SRL
                        //    else if (funct7 == 7'b0100000) alu_control = MY_ALU_SRA; // SRA
                        //    else alu_control = MY_ALU_NOOP;
                        //end
                        default: alu_control = MY_ALU_NOOP; // Undefined funct3
                    endcase
                end

                OPC_JAL: begin
                    reg_write    = (rd != 5'd0); // JAL writes PC+4 to rd
                    result_src   = 1'b1;         // Indicates result is PC+1 (word addressed)
                                                 // Or handle PC+4 in top module logic.
                                                 // For simplicity here, let's assume ALU does PC+1 for WB
                                                 // This needs a dedicated path or ALU op.
                                                 // A simpler JAL for this CPU: rd gets 0 if x0, or some value
                                                 // if we allow rd!=x0, for now result_src will be ALU result.
                                                 // To match RISC-V, rd should get PC_byte_addr + 4.
                                                 // For now, let's set result_src = 0 (ALU result) and
                                                 // ALU result can be made 0 or PC+1 if needed.
                                                 // Let's assume ALU is not used for rd calculation for JAL for simplicity.
                    result_src   = 1'b0; // We are not implementing the rd=PC+4 part properly yet.
                                         // If rd != x0, it should get PC+4.
                                         // For J (pseudo JAL x0), rd=x0 so no write.
                    alu_control  = MY_ALU_NOOP; // ALU not used for target addr calculation directly here
                    jump_taken   = 1'b1;
                    computed_target_pc_address = current_pc_address + jump_word_offset[4:0]; // Use lower 5 bits of word offset
                end
                
                OPC_BRANCH: begin // BEQ, BNE, etc.
                    reg_write  = 1'b0;    // Branches do not write to register file
                    alu_src    = 1'b0;    // Compare rs1 and rs2
                    // funct3 determines branch type
                    case (funct3)
                        3'b000: begin // BEQ rs1, rs2, offset
                            alu_control = MY_ALU_SUB; // Perform rs1 - rs2
                            if (alu_zero) begin       // If (rs1 - rs2) == 0, then rs1 == rs2
                                branch_taken = 1'b1;
                                computed_target_pc_address = current_pc_address + branch_word_offset[4:0];
                            end
                        end
                        // Add BNE, BLT, etc. if needed
                        // 3'b001: begin // BNE rs1, rs2, offset
                        //    alu_control = MY_ALU_SUB;
                        //    if (!alu_zero) begin
                        //        branch_taken = 1'b1;
                        //        computed_target_pc_address = current_pc_address + branch_word_offset[4:0];
                        //    end
                        // end
                        default: begin // Undefined branch type
                            alu_control = MY_ALU_NOOP;
                        end
                    endcase
                end
                
                // Not implementing LOAD, STORE, LUI, AUIPC, JALR for this example.
                OPC_LOAD: begin // Not implemented - treat as NOOP
                    alu_control = MY_ALU_NOOP;
                end
                OPC_STORE: begin // Not implemented - treat as NOOP
                     alu_control = MY_ALU_NOOP;
                end
                OPC_LUI: begin // Not implemented
                    // reg_write = (rd != 5'd0);
                    // alu_src = 1'b1; // Special immediate handling
                    // alu_control = SOME_LUI_OP;
                     alu_control = MY_ALU_NOOP;
                end
                OPC_AUIPC: begin // Not implemented
                     alu_control = MY_ALU_NOOP;
                end
                
                default: begin // Unknown opcode
                    alu_control       = MY_ALU_NOOP;
                    reg_write         = 1'b0;
                    branch_taken      = 1'b0;
                    jump_taken        = 1'b0;
                end
            endcase
        end
        // `result_src` is 0 because we always write ALU result.
        // If we had loads, it would be 1 to select memory data for WB.
        // For JAL, if rd != x0, it should get PC_of_JAL + 4. This path is not fully built.
        // For now, if JAL writes to rd, it will write whatever alu_result is (likely 0 from NOOP).
        if (opcode == OPC_JAL && rd != 5'd0) begin
           // Special handling for JAL's write_back_data would be needed here
           // to provide PC+4. For now, it will get alu_result (0).
           // This is a simplification.
        end

    end
endmodule