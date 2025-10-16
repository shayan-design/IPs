`timescale 1 ps / 1 ps

module hex_display (
    input clk,                     // 100 MHz clock
    input [15:0] bin_in,           // 16-bit binary input
    output reg [6:0] seg,          // 7-segment segments (a-g)
    output reg [3:0] an            // 4 anode signals (active-low)
);

    // Split 16-bit input into 4 hex digits
    wire [3:0] hex0, hex1, hex2, hex3;
    assign hex0 = bin_in[3:0];
    assign hex1 = bin_in[7:4];
    assign hex2 = bin_in[11:8];
    assign hex3 = bin_in[15:12];

    // Current digit selector
    reg [1:0] digit_sel = 0;
    reg [3:0] current_digit = 0;

    // Clock divider to slow down display refresh (~1 kHz)
    reg [15:0] clkdiv = 0;
    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
    end

    // Update digit selector at lower frequency
    always @(posedge clkdiv[15]) begin
        digit_sel <= digit_sel + 1;
    end

    // Select digit and corresponding anode
    always @(*) begin
        case (digit_sel)
            2'd0: begin
                an = 4'b1110;          // Enable rightmost display
                current_digit = hex0;
            end
            2'd1: begin
                an = 4'b1101;
                current_digit = hex1;
            end
            2'd2: begin
                an = 4'b1011;
                current_digit = hex2;
            end
            2'd3: begin
                an = 4'b0111;          // Enable leftmost display
                current_digit = hex3;
            end
            default: begin
                an = 4'b1111;
                current_digit = 4'd0;
            end
        endcase
    end

    // Hex to 7-segment decoder (active-low segments)
    always @(*) begin
        case (current_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
