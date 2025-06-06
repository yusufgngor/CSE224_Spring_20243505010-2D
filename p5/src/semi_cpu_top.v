module p5 (
    input clk,
    input reset_btn, // Nexys4 btnC (Center button)
    input control_btn, // Nexys4 btnL (Left button)
    output [6:0] segment, // 7-segment display segments
    output [7:0] anode // 7-segment display anodes
);

    wire [4:0] pc_address;
    wire [31:0] instruction;
    wire [2:0] alu_control;
    wire alu_src;
    wire reg_write;
    wire result_src;
    wire [31:0] rd1_data, rd2_data;
    wire [31:0] extended_immediate;
    wire [31:0] alu_input_a, alu_input_b;
    
    wire [31:0] alu_result; // Data to write to Register File

    wire [4:0] rs1_addr = instruction[19:15];
    wire [4:0] rs2_addr = instruction[24:20];
    wire [4:0] rd_addr  = instruction[11:7];
    wire [11:0] immediate_val = instruction[31:20]; // For I-type (ADDI, SUBI)

    program_counter u_pc (
        .clk(clk),
        .reset(reset_btn),
        .control_input(control_btn),
        .pc_address(pc_address)
    );

    // 2. Instruction Memory
    instruction_memory u_im (
        .pc_address(pc_address),
        .control_input(control_btn), // Only fetch if control is active
        .instruction_out(instruction)
    );

    // 3. Instruction Decoder (Control Unit)
    instruction_decoder u_id (
        .instruction(instruction),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .result_src(result_src)
    );

    // 4. Register File
    register_file u_rf (
        .clk(clk),
        .we3(reg_write),       // Write enable from control unit
        .a1(rs1_addr),         // Read address 1 (rs1)
        .a2(rs2_addr),         // Read address 2 (rs2)
        .a3(rd_addr),          // Write address (rd)
        .wd3(alu_result), // Data to write back
        .rd1(rd1_data),        // Data read from rs1
        .rd2(rd2_data)         // Data read from rs2
    );

    // 5. Extend Unit
    extend_unit u_extend (
        .immediate_in(immediate_val),
        .extended_immediate_out(extended_immediate)
    );

    // Mux for ALU input B (ALUSrc)
    assign alu_input_b = (alu_src == 1'b0) ? rd2_data : extended_immediate;
    // ALU input A is always rd1_data for this CPU
    assign alu_input_a = rd1_data;


    // 6. ALU
    alu u_alu (
        .src_a(alu_input_a),
        .src_b(alu_input_b),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );

    seven_seg_controller u_seven_seg (
        .clk(clk),
        .data_in(alu_result),
        .segment(segment),
        .anode(anode)
    );

endmodule
