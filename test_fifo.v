`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*
// ==============================================================
//                     Port Description
// ==============================================================   

clk      -> System clock input. The design operates on the **positive edge** (posedge) 
            of this clock. The frequency is **200 MHz**.

aresetn  -> **Active-low reset** signal. When low, it resets all internal logic and FIFO states.

// ==============================================================
//                 AXI-Stream Interface (Standard)
// ==============================================================   

S_AXIS_tdata  -> Standard **32-bit AXI Stream data bus** used to send data from master to slave.

S_AXIS_tlast  -> Asserted high to indicate the **last data word** in a transfer frame.

S_AXIS_tvalid -> When high, it means the **master has valid data** on `S_AXIS_tdata` and 
                 is ready to send it to the slave.

S_AXIS_tready -> When high, it means the **slave is ready to receive** data from the master.

// ==============================================================
//              Custom Project-Specific Control Ports
// ==============================================================   

switch   -> External FPGA input (like a **push button or toggle switch**) used to manually 
            trigger data output from the FIFO to the LEDs. 
            This provides a simple way to verify FIFO data on hardware.

tready   -> Custom **ready control signal**. When high, it indicates the system is ready 
            to accept new data from the master. 
            It can be controlled through the FPGA input switch - you can modify this 
            behavior as per your design needs.

data_out -> **16-bit data output** used to display FIFO output data on 16 onboard LEDs.

empty    -> Asserted high when the FIFO is **empty**, meaning no data is available to read.

full     -> Asserted high when the FIFO is **full**, meaning no more data can be written.

// ==============================================================
//             Parameterized Configuration
// ==============================================================   

DEPTH -> Defines the **FIFO storage depth** (number of 32-bit words).  
         Example: If DEPTH = 4, the FIFO can store 4 × 32-bit = 128 bits of data.

*/
//////////////////////////////////////////////////////////////////////////////////


module fifo_256 (
    input  wire        clk,
    input  wire        aresetn,
    input  wire [31:0] S_AXIS_tdata,
    input              S_AXIS_tlast,
    input  wire        S_AXIS_tvalid,
    output wire        S_AXIS_tready,
    input  wire        switch,
    input  wire        tready,
    output wire [15:0] data_out,
    output wire        empty,
    output wire        full
);
    
    // User can change depth accoding there project requirement
    localparam DEPTH = 4;
    localparam ADDR_WIDTH = $clog2(DEPTH); 
    // User can change depth accoding there project requirement
    
    reg [31:0] data_out_1;
    assign S_AXIS_tready = tready;

    // FIFO memory
    reg [31:0] fifo_mem [0:DEPTH-1];

    // Read and write pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // Store previous state of switch to detect rising edge
    reg switch_d;

    // Write logic
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            wr_ptr <= 0;
        end else if (S_AXIS_tvalid && !full && tready) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= S_AXIS_tdata;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic (based on switch rising edge)
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            rd_ptr   <= 0;
            data_out_1 <= 0;
            switch_d <= 0;
        end else begin
            switch_d <= switch; // store previous switch value

            if (switch && !switch_d && !empty) begin
                data_out_1 <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Empty and full logic
    assign empty = (wr_ptr == rd_ptr);
    assign full  = ((wr_ptr - rd_ptr) == DEPTH);
    
    assign data_out = data_out_1[15:0];

endmodule

