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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module instruction_decoder (
    input [31:0] instruction,
    output reg [2:0] alu_control, // 3 bits for 7 ALU ops
    output reg alu_src,           // 0: reg_data, 1: immediate
    output reg reg_write,         // 1: write to register file
    output reg result_src         // 0: alu_result, 1: read_data (from RF)
);

    // Decode fields
    wire [6:0] opcode  = instruction[6:0];
    wire [2:0] funct3  = instruction[14:12];
    wire [6:0] funct7  = instruction[31:25];

    // Define opcodes and functs (adjust if your specific RISC-V setup differs)
    parameter OP_IMM = 7'b0010011; // ADDI, SUBI
    parameter OP     = 7'b0110011; // ADD, SUB, SHIFTL, SHIFTR

    // ALU control codes (from lab description)
    parameter ALU_NOOP    = 3'b000;
    parameter ALU_ADD     = 3'b010;
    parameter ALU_SUB     = 3'b011;
    parameter ALU_SHIFTL  = 3'b100;
    parameter ALU_SHIFTR  = 3'b101;
    parameter ALU_ADDI    = 3'b110;
    parameter ALU_SUBI    = 3'b111;

    always @(*) begin
        // Default values (for NOOP or unrecognized instructions)
        alu_control = ALU_NOOP;
        alu_src     = 1'b0; // Default to register data
        reg_write   = 1'b0; // Default no write
        result_src  = 1'b0; // Default to ALU result

        if (instruction == 32'h0 || instruction == 32'h00000013) begin // Handle NOOP
            alu_control = ALU_NOOP;
            alu_src     = 1'b0;
            reg_write   = 1'b0;
            result_src  = 1'b0;
        end else begin
            case (opcode)
                OP_IMM: begin // ADDI, SUBI
                    reg_write = 1'b1;
                    alu_src   = 1'b1; // Use immediate for I-type
                    case (funct3)
                        3'b000: alu_control = ALU_ADDI; // ADDI
                        3'b001: alu_control = ALU_SUBI; // Custom for SUBI, as defined in problem
                        default: alu_control = ALU_NOOP;
                    endcase
                end
                OP: begin // ADD, SUB, SHIFTL, SHIFTR
                    reg_write = 1'b1;
                    alu_src   = 1'b0; // Use rs2 for R-type
                    case (funct3)
                        3'b000: begin // ADD / SUB
                            if (funct7 == 7'b0000000) alu_control = ALU_ADD;
                            else if (funct7 == 7'b0100000) alu_control = ALU_SUB; // SUB
                            else alu_control = ALU_NOOP;
                        end
                        3'b001: begin // SHIFTL (SLL)
                            if (funct7 == 7'b0000000) alu_control = ALU_SHIFTL;
                            else alu_control = ALU_NOOP;
                        end
                        3'b101: begin // SHIFTR (SRL)
                            if (funct7 == 7'b0000000) alu_control = ALU_SHIFTR; // SRL
                            else alu_control = ALU_NOOP;
                        end
                        default: alu_control = ALU_NOOP;
                    endcase
                end
                default: begin
                end
            endcase
            result_src = 1'b0;
        end
    end

endmodule
