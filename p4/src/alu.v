// alu.v
module alu (
    input wire [31:0] inputA,
    input wire [31:0] inputB,
    input wire [1:0] opcode,    // 00: ADD, 01: SUB, 10: SHIFTL, 11: SHIFTR
    output reg [31:0] ALU_result
);


    always @(*) begin 
        case (opcode)
            2'b00: ALU_result = inputA + inputB;
            2'b01: ALU_result = inputA - inputB;
            2'b10: ALU_result = inputA << inputB; 
            2'b11: ALU_result = inputA >> inputB; 
            default: ALU_result = 32'hxxxxxxxx; // Undefined opcode
        endcase
    end

endmodule