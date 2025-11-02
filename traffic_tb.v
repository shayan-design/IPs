`timescale 1 ns / 1 ps

module trafficgen_tb();

parameter integer C_S00_AXI_DATA_WIDTH	= 32;
parameter integer C_S00_AXI_ADDR_WIDTH	= 4;

// Parameters of Axi Master Bus Interface M00_AXIS
parameter integer C_M00_AXIS_TDATA_WIDTH	= 32;
parameter integer C_M00_AXIS_START_COUNT	= 32;

reg s00_axi_aclk;	
reg  s00_axi_aresetn;
reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
reg [2 : 0] s00_axi_awprot;
reg  s00_axi_awvalid;
wire  s00_axi_awready;
reg [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
reg [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
reg  s00_axi_wvalid;
wire  s00_axi_wready;

wire [1 : 0] s00_axi_bresp;
wire  s00_axi_bvalid;
reg  s00_axi_bready;

reg[C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
reg [2 : 0] s00_axi_arprot;
reg  s00_axi_arvalid;
wire  s00_axi_arready;
wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
wire [1 : 0] s00_axi_rresp;
wire  s00_axi_rvalid;
reg  s00_axi_rready;

wire  M_AXIS_0_tvalid;
wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_0_tdata;
wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb;
wire  M_AXIS_0_tlast;
reg  M_AXIS_0_tready;

wire [7:0] NTT_counter_0;
reg NTT_INTT_sel_0 = 1'b1;

design_1_wrapper dut
   (M_AXIS_0_tdata,
    M_AXIS_0_tlast,
    M_AXIS_0_tready,
    M_AXIS_0_tvalid,
    NTT_INTT_sel_0,
    NTT_counter_0,
    
    s00_axi_aclk,
    //m00_axis_tstrb,
    s00_axi_aresetn,
    
    s00_axi_araddr,
    s00_axi_arprot,
    s00_axi_arready,
    s00_axi_arvalid,
    
    s00_axi_awaddr,
    s00_axi_awprot,
    s00_axi_awready,
    s00_axi_awvalid,
    
    s00_axi_bready,
    s00_axi_bresp,
    s00_axi_bvalid,
     
    s00_axi_rdata,
    s00_axi_rready,
    s00_axi_rresp,
    s00_axi_rvalid,
    
    s00_axi_wdata,
    s00_axi_wready,
    s00_axi_wstrb,
    s00_axi_wvalid); 


initial begin
        s00_axi_aclk = 0;
        forever begin
            #10 s00_axi_aclk = ~s00_axi_aclk;
        end
end
initial begin
        s00_axi_aresetn = 0;
        s00_axi_wstrb = 15;
        #25 s00_axi_aresetn = 1;
end
//Write channel setup
initial begin
        s00_axi_awvalid = 0;
        #60 s00_axi_awvalid = 1;
        s00_axi_wvalid = 1;
        s00_axi_bready = 1;
        s00_axi_wdata = 1; // enable 
        s00_axi_awaddr = 0;
        #40 s00_axi_awvalid = 0;
        s00_axi_wvalid = 0;
        #40 s00_axi_bready = 0;
        
        #60 s00_axi_awvalid = 1;
        s00_axi_wvalid = 1;
        s00_axi_bready = 1;
        s00_axi_wdata = 256; // number of words
        s00_axi_awaddr = 4;
        #40 s00_axi_awvalid = 0;
        s00_axi_wvalid = 0;
        #40 s00_axi_bready = 0;
end

//Read channel setup
initial begin
        s00_axi_arvalid = 0;
        s00_axi_araddr = 0;
        #60 s00_axi_rready = 1;
        #340 s00_axi_arvalid = 1;
        #40 s00_axi_arvalid = 0;
        #60 s00_axi_araddr = 4;
        s00_axi_arvalid = 1;
        #40 s00_axi_arvalid = 0;
        #60 s00_axi_araddr = 0;
        s00_axi_arvalid = 1;
        #40 s00_axi_arvalid = 0;
end

// Enable, disable and re-enable output stream using tready
initial begin
        M_AXIS_0_tready = 0;
        #650 M_AXIS_0_tready = 1;
        #550 M_AXIS_0_tready = 0;
        #40 M_AXIS_0_tready = 1;
end
// Disable and then enable the output stream by writing to the slave register
initial begin
        #1500 s00_axi_awvalid = 1;
        s00_axi_wvalid = 1;
        s00_axi_bready = 1;
        s00_axi_wdata = 0;
        s00_axi_awaddr = 0;
        #40 s00_axi_awvalid = 0;
        s00_axi_wvalid = 0;
        #40 s00_axi_bready = 0;
        
        #100 s00_axi_awvalid = 1;
        s00_axi_wvalid = 1;
        s00_axi_bready = 1;
        s00_axi_wdata = 1;
        s00_axi_awaddr = 0;
        #40 s00_axi_awvalid = 0;
        s00_axi_wvalid = 0;
        #40 s00_axi_bready = 0;
end
endmodule