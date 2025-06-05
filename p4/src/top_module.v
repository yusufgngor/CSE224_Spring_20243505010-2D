// top_module.v
// This is the top-level module for synthesizing the RegFile and ALU on a Xilinx Artix-7 (or similar FPGA).

module p4 (
    // System Clock Input
    input           clk_i,      // Main clock input

    // Register File Control Inputs
    input           rf_we_i,    // Register File Write Enable
    input [4:0]     rf_A1_i,    // Register File Read Address 1
    input [4:0]     rf_A2_i,    // Register File Read Address 2
    input [4:0]     rf_A3_i,    // Register File Write Address

    // ALU Control Input
    input [1:0]     alu_opcode_i, // ALU operation select (00:ADD, 01:SUB, 10:SHIFTL, 11:SHIFTR)

    // Register File Read Outputs (for observation/further processing)
    output [31:0]   rf_RD1_o,   // Register File Read Data 1
    output [31:0]   rf_RD2_o,   // Register File Read Data 2

    // ALU Result Output (for observation/further processing)
    output [31:0]   alu_result_o // ALU Computed Result
);

    // Internal Wires for connecting the Register File and ALU
    wire [31:0] rf_rd1_internal;  // Data read from RF A1, fed to ALU inputA
    wire [31:0] rf_rd2_internal;  // Data read from RF A2, fed to ALU inputB
    wire [31:0] alu_result_internal; // Result from ALU, fed to RF write data WD3

    // Instantiate the Register File
    register_file rf_inst (
        .CLK(clk_i),               // Connect top-level clock to RF clock
        .WE3(rf_we_i),             // Connect top-level write enable to RF
        .A1(rf_A1_i),              // Connect top-level read address 1 to RF
        .A2(rf_A2_i),              // Connect top-level read address 2 to RF
        .A3(rf_A3_i),              // Connect top-level write address to RF
        .WD3(alu_result_internal), // Connect ALU's result to RF's write data
        .RD1(rf_rd1_internal),     // RF read data 1 output to internal wire
        .RD2(rf_rd2_internal)      // RF read data 2 output to internal wire
    );

    // Instantiate the ALU
    alu alu_inst (
        .inputA(rf_rd1_internal),  // Connect RF read data 1 to ALU inputA
        .inputB(rf_rd2_internal),  // Connect RF read data 2 to ALU inputB
        .opcode(alu_opcode_i),     // Connect top-level ALU opcode to ALU
        .ALU_result(alu_result_internal) // ALU result output to internal wire
    );

    // Connect internal wires to top-level outputs for external visibility
    assign rf_RD1_o     = rf_rd1_internal;
    assign rf_RD2_o     = rf_rd2_internal;
    assign alu_result_o = alu_result_internal;

endmodule