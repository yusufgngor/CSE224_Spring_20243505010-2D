//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:48:10
// Design Name: 
// Module Name: register_file
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

module register_file (
    input clk,
    input we3,           // Write Enable
    input [4:0] a1, a2,  // Read Addresses
    input [4:0] a3,      // Write Address
    input [31:0] wd3,    // Write Data
    output [31:0] rd1, rd2 // Read Data
);

    reg [31:0] registers [0:31];

    initial begin
        registers[0] = 32'h0;
    end

    assign rd1 = registers[a1];
    assign rd2 = registers[a2];

    always @(posedge clk) begin
        if (we3) begin
            if (a3 != 5'd0) begin 
                registers[a3] <= wd3;
            end
        end
    end

endmodule