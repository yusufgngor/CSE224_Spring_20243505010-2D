module register_file (
    input wire CLK,
    input wire WE3,           
    input wire [4:0] A1,     
    input wire [4:0] A2,     
    input wire [4:0] A3,     
    input wire [31:0] WD3,    
    output wire [31:0] RD1,  
    output wire [31:0] RD2 
);
    reg [31:0] registers [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    assign RD1 = registers[A1];
    assign RD2 = registers[A2];

    always @(posedge CLK) begin
        if (WE3) begin
            registers[A3] <= WD3;
        end
    end

endmodule