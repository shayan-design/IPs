`timescale 1ns / 1ps

module preprocess (
    input [11:0] x, 
    input NTT_INTT_sel, 
    output [11:0] z
);

    //           precompute constants
    
    wire [12:0] x2    = {x, 1'b0};  // x << 1 (fast shift)
    wire [12:0] base  = (x < 12'd1665) ? 13'd3329 : 13'd6658;
    wire [12:0] in_1  = base - x2;        // one subtraction only

    //           multiply by 13
    
    wire [7:0] low  = in_1[7:0];
    wire [3:0] high = in_1[11:8];

    wire [12:0] mul13_low;
    wire [9:0]  low_x4  = {low, 2'b00};   // low << 2
    wire [10:0] low_x8  = {low, 3'b000};  // low << 3

    // Balanced adder: (low_x8 + low_x4) + low  → less carry chain depth
    
    wire [11:0] tmp_sum = low_x8 + low_x4;
    assign mul13_low = tmp_sum + low - {9'd0, high};

    //          Conditional correction with precomputed constant

    wire [12:0] y_corr = mul13_low[12] ? (mul13_low + 13'd3329) : mul13_low;

    assign z = NTT_INTT_sel ? x : y_corr[11:0];

endmodule
