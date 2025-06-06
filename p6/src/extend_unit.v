`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2025 19:48:55
// Design Name: 
// Module Name: extend_unit
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


module extend_unit (
    input [11:0] immediate_in,
    output [31:0] extended_immediate_out
);

    // Sign-extend the 12-bit immediate to 32 bits
    assign extended_immediate_out = {{20{immediate_in[11]}}, immediate_in};

endmodule