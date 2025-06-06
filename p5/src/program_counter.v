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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module program_counter (
    input clk,
    input reset,
    input control_input, // Increment control from button
    output reg [4:0] pc_address // 5-bit for up to 32 instructions
);

    always @(posedge clk) begin
        if (reset) begin
            pc_address <= 5'd0; // Reset PC to 0
        end else if (control_input) begin
            if (pc_address < 5'd5) begin // Assuming 6 instructions (0-5)
                pc_address <= pc_address + 5'd1;
            end else begin
                pc_address <= 5'd0;
            end
        end
    end
endmodule