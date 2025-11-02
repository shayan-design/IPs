`timescale 1ns / 1ps

module AXI_Stream_tb;

  // ======================
  // DUT interface signals
  // ======================
  reg  [31:0] S_AXIS_tdata;
  reg         S_AXIS_tlast;
  reg         S_AXIS_tvalid;
  wire        S_AXIS_tready;

  reg         clk;
  reg         reset;
  reg         NTT_INTT_sel;

  wire [31:0] M_AXIS_tdata;
  wire        M_AXIS_tlast;
  reg         M_AXIS_tready;
  wire        M_AXIS_tvalid;

  wire [7:0]  NTT_counter;

  // ======================
  // DUT instantiation
  // ======================
  NTT_data_frame dut (
    .S_AXIS_tdata (S_AXIS_tdata),
    .S_AXIS_tlast (S_AXIS_tlast),
    .S_AXIS_tready(S_AXIS_tready),
    .S_AXIS_tvalid(S_AXIS_tvalid),
    .clk          (clk),
    .reset        (reset),
    .NTT_INTT_sel (NTT_INTT_sel),
    .M_AXIS_tdata (M_AXIS_tdata),
    .M_AXIS_tlast (M_AXIS_tlast),
    .M_AXIS_tready(M_AXIS_tready),
    .M_AXIS_tvalid(M_AXIS_tvalid),
    .NTT_counter  (NTT_counter)
  );

  // ======================
  // Clock generation
  // ======================
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz clock

  // ======================
  // Reset sequence
  // ======================
  initial begin
    reset = 1;
    NTT_INTT_sel = 1;
    S_AXIS_tdata  = 0;
    S_AXIS_tvalid = 0;
    S_AXIS_tlast  = 0;
    M_AXIS_tready = 1'b1;
    #50;
    reset = 0;
  end

  // ======================
  // 4-cycle toggle + random behavior for VALID and READY
  // ======================
  integer valid_toggle_cnt = 0;
  integer ready_toggle_cnt = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      S_AXIS_tvalid <= 0;
      M_AXIS_tready <= 1;
      valid_toggle_cnt <= 0;
      ready_toggle_cnt <= 0;
    end else begin
      // ---- VALID pattern ----
      valid_toggle_cnt <= valid_toggle_cnt + 1;
      if (valid_toggle_cnt == 4) begin
        S_AXIS_tvalid <= ~S_AXIS_tvalid;
        valid_toggle_cnt <= 0;
      end else begin
        S_AXIS_tvalid <= $urandom_range(0,1);
      end

      // ---- READY pattern ----
      ready_toggle_cnt <= ready_toggle_cnt + 1;
      if (ready_toggle_cnt == 4) begin
        M_AXIS_tready <= ~M_AXIS_tready;
        ready_toggle_cnt <= 0;
      end else begin
        M_AXIS_tready <= $urandom_range(0,1);
      end
    end
  end

  // ======================
  // Stimulus logic (i increments only on handshake)
  // ======================
  integer i;
  initial begin
    wait(!reset);
    @(posedge clk);

    $display("\n=== Starting AXI Stream Stimulus ===");

    i = 0;
    S_AXIS_tdata = i;
    S_AXIS_tlast = 0;

    // Keep running until we send 256 words
    while (i < 257) begin
      @(posedge clk);
      if (S_AXIS_tvalid && S_AXIS_tready) begin
        // Handshake success → log and increment
        $display("[%0t] Sent Data: %0d (last=%0b, valid=%0b, ready=%0b)", 
                 $time, S_AXIS_tdata, S_AXIS_tlast, S_AXIS_tvalid, S_AXIS_tready);

        i = i + 1;

        // Update next data word
        S_AXIS_tdata = i;
        S_AXIS_tlast = (i == 256) ? 1'b1 : 1'b0;
      end
    end

    // After all data sent
    S_AXIS_tvalid = 0;
    S_AXIS_tlast  = 0;
  end

  // ======================
  // Monitor output
  // ======================
  always @(posedge clk) begin
    if (M_AXIS_tvalid && M_AXIS_tready) begin
      $display("[%0t] DUT Output: %0d (last=%0b)", 
               $time, M_AXIS_tdata, M_AXIS_tlast);
      if (M_AXIS_tlast)
        $display("=== End of frame detected ===");
    end
  end

  // ======================
  // Timeout protection
  // ======================
  initial begin
    #50000;
    $display("TIMEOUT: Simulation exceeded limit!");
    $finish;
  end

  // ======================
  // Simulation end
  // ======================
  initial begin
    wait(M_AXIS_tlast);
    #10000;
    $display("\n=== Simulation Complete ===");
    $finish;
  end

endmodule

