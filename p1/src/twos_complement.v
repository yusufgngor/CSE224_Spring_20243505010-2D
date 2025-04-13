module p1(
    output [7:0] out,
    input  [7:0] in
);
    assign out = ~in + 1;
endmodule
