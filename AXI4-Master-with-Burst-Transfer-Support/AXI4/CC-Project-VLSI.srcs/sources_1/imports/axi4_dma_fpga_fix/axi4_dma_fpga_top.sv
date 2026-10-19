`timescale 1ns / 1ps

// FPGA integration wrapper for the AXI4 DMA core.
// The AXI4 bus remains internal to the FPGA.
// Only DMA configuration/status and clock/reset are exposed as FPGA pins.

module axi4_dma_fpga_top #(
    parameter integer ADDR_WIDTH    = 32,
    parameter integer DATA_WIDTH    = 64,
    parameter integer ID_WIDTH      = 4,
    parameter integer FIFO_DEPTH    = 512,
    parameter integer MAX_BURST_LEN = 16,
    parameter integer MEM_WORDS     = 4096
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire [ADDR_WIDTH-1:0]   src_addr,
    input  wire [ADDR_WIDTH-1:0]   dst_addr,
    input  wire [31:0]             transfer_bytes,
    input  wire                    start,

    output wire                    busy,
    output wire                    done,
    output wire                    error
);

    // ------------------------------------------------------------
    // Internal AXI4 wires between DMA master and memory slave.
    // These are NOT top-level FPGA pins.
    // ------------------------------------------------------------
    wire [ID_WIDTH-1:0]     axi_awid;
    wire [ADDR_WIDTH-1:0]   axi_awaddr;
    wire [7:0]              axi_awlen;
    wire [2:0]              axi_awsize;
    wire [1:0]              axi_awburst;
    wire                    axi_awvalid;
    wire                    axi_awready;

    wire [DATA_WIDTH-1:0]   axi_wdata;
    wire [DATA_WIDTH/8-1:0] axi_wstrb;
    wire                    axi_wlast;
    wire                    axi_wvalid;
    wire                    axi_wready;

    wire [ID_WIDTH-1:0]     axi_bid;
    wire [1:0]              axi_bresp;
    wire                    axi_bvalid;
    wire                    axi_bready;

    wire [ID_WIDTH-1:0]     axi_arid;
    wire [ADDR_WIDTH-1:0]   axi_araddr;
    wire [7:0]              axi_arlen;
    wire [2:0]              axi_arsize;
    wire [1:0]              axi_arburst;
    wire                    axi_arvalid;
    wire                    axi_arready;

    wire [ID_WIDTH-1:0]     axi_rid;
    wire [DATA_WIDTH-1:0]   axi_rdata;
    wire [1:0]              axi_rresp;
    wire                    axi_rlast;
    wire                    axi_rvalid;
    wire                    axi_rready;

    // ------------------------------------------------------------
    // Existing DMA core -- unchanged.
    // ------------------------------------------------------------
    axi4_dma_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) u_dma (
        .clk(clk),
        .rst_n(rst_n),

        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .transfer_bytes(transfer_bytes),
        .start(start),

        .busy(busy),
        .done(done),
        .error(error),

        .M_AXI_AWID(axi_awid),
        .M_AXI_AWADDR(axi_awaddr),
        .M_AXI_AWLEN(axi_awlen),
        .M_AXI_AWSIZE(axi_awsize),
        .M_AXI_AWBURST(axi_awburst),
        .M_AXI_AWVALID(axi_awvalid),
        .M_AXI_AWREADY(axi_awready),

        .M_AXI_WDATA(axi_wdata),
        .M_AXI_WSTRB(axi_wstrb),
        .M_AXI_WLAST(axi_wlast),
        .M_AXI_WVALID(axi_wvalid),
        .M_AXI_WREADY(axi_wready),

        .M_AXI_BID(axi_bid),
        .M_AXI_BRESP(axi_bresp),
        .M_AXI_BVALID(axi_bvalid),
        .M_AXI_BREADY(axi_bready),

        .M_AXI_ARID(axi_arid),
        .M_AXI_ARADDR(axi_araddr),
        .M_AXI_ARLEN(axi_arlen),
        .M_AXI_ARSIZE(axi_arsize),
        .M_AXI_ARBURST(axi_arburst),
        .M_AXI_ARVALID(axi_arvalid),
        .M_AXI_ARREADY(axi_arready),

        .M_AXI_RID(axi_rid),
        .M_AXI_RDATA(axi_rdata),
        .M_AXI_RRESP(axi_rresp),
        .M_AXI_RLAST(axi_rlast),
        .M_AXI_RVALID(axi_rvalid),
        .M_AXI_RREADY(axi_rready)
    );

    // ------------------------------------------------------------
    // Synthesizable on-chip AXI4 memory model.
    // This is an FPGA demonstration memory, not a DDR/MIG model.
    // ------------------------------------------------------------
    axi4_ram_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MEM_WORDS(MEM_WORDS)
    ) u_ram (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awid(axi_awid),
        .s_axi_awaddr(axi_awaddr),
        .s_axi_awlen(axi_awlen),
        .s_axi_awsize(axi_awsize),
        .s_axi_awburst(axi_awburst),
        .s_axi_awvalid(axi_awvalid),
        .s_axi_awready(axi_awready),

        .s_axi_wdata(axi_wdata),
        .s_axi_wstrb(axi_wstrb),
        .s_axi_wlast(axi_wlast),
        .s_axi_wvalid(axi_wvalid),
        .s_axi_wready(axi_wready),

        .s_axi_bid(axi_bid),
        .s_axi_bresp(axi_bresp),
        .s_axi_bvalid(axi_bvalid),
        .s_axi_bready(axi_bready),

        .s_axi_arid(axi_arid),
        .s_axi_araddr(axi_araddr),
        .s_axi_arlen(axi_arlen),
        .s_axi_arsize(axi_arsize),
        .s_axi_arburst(axi_arburst),
        .s_axi_arvalid(axi_arvalid),
        .s_axi_arready(axi_arready),

        .s_axi_rid(axi_rid),
        .s_axi_rdata(axi_rdata),
        .s_axi_rresp(axi_rresp),
        .s_axi_rlast(axi_rlast),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready)
    );

endmodule
