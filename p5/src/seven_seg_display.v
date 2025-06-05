module hex_to_7seg (
    input [3:0] hex_val,
    output [6:0] seg_out
);

    reg [6:0] seg_reg;

    always @(*) begin
        case (hex_val)
            4'h0: seg_reg = 7'b0111111; // 0
            4'h1: seg_reg = 7'b0000110; // 1
            4'h2: seg_reg = 7'b1011011; // 2
            4'h3: seg_reg = 7'b1001111; // 3
            4'h4: seg_reg = 7'b1100110; // 4
            4'h5: seg_reg = 7'b1101101; // 5
            4'h6: seg_reg = 7'b1111101; // 6
            4'h7: seg_reg = 7'b0000111; // 7
            4'h8: seg_reg = 7'b1111111; // 8
            4'h9: seg_reg = 7'b1101111; // 9
            4'hA: seg_reg = 7'b1110111; // A
            4'hB: seg_reg = 7'b1111100; // B
            4'hC: seg_reg = 7'b0111001; // C
            4'hD: seg_reg = 7'b1011110; // D
            4'hE: seg_reg = 7'b1111001; // E
            4'hF: seg_reg = 7'b1110001; // F
            default: seg_reg = 7'b0000000; // blank
        endcase
    end
    assign seg_out = seg_reg;

endmodule


module seven_seg_controller (
    input clk,
    input [31:0] data_in, // The 32-bit Result
    output reg [6:0] segment,
    output reg [7:0] anode
);

    // For multiplexing 8 digits
    reg [2:0] digit_select_cnt;
    reg [3:0] current_digit_val;

    // Instance of hex_to_7seg converter
    hex_to_7seg u_hex_to_7seg (
        .hex_val(current_digit_val),
        .seg_out(segment)
    );

    // Clock divider for multiplexing speed (adjust as needed)
    reg [20:0] clk_div_cnt = 0;
    wire clk_1kHz;
    assign clk_1kHz = (clk_div_cnt == 21'd50_000_000/1000); // For 100MHz clock, 1kHz refresh

    always @(posedge clk) begin
        if (clk_div_cnt == 21'd50_000_000/1000) begin // 100MHz / 1000Hz = 100000.  (100MHz / 8 digits / refresh rate per digit)
            clk_div_cnt <= 0;
            digit_select_cnt <= digit_select_cnt + 1;
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
        end
    end


    always @(*) begin
        anode = 8'b11111111; // All off by default
        case (digit_select_cnt)
            3'd0: begin anode = 8'b11111110; current_digit_val = data_in[3:0];   end // LSB
            3'd1: begin anode = 8'b11111101; current_digit_val = data_in[7:4];   end
            3'd2: begin anode = 8'b11111011; current_digit_val = data_in[11:8];  end
            3'd3: begin anode = 8'b11110111; current_digit_val = data_in[15:12]; end
            3'd4: begin anode = 8'b11101111; current_digit_val = data_in[19:16]; end
            3'd5: begin anode = 8'b11011111; current_digit_val = data_in[23:20]; end
            3'd6: begin anode = 8'b10111111; current_digit_val = data_in[27:24]; end
            3'd7: begin anode = 8'b01111111; current_digit_val = data_in[31:28]; end // MSB
            default: begin anode = 8'b11111111; current_digit_val = 4'h0; end
        endcase
    end

endmodule