
`timescale 1ns / 1ps

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
    // Clock Wizard: 125 MHz input -> 100 MHz DMA clock
    // ------------------------------------------------------------
    wire clk_100;
    wire clk_locked;
    wire internal_rst_n;
    wire reset_async_n;

    reg [1:0] reset_sync;

    clk_wiz_0 u_clk_wiz (
        .clk_in1 (clk),
        .reset   (~rst_n),
        .clk_out1(clk_100),
        .locked  (clk_locked)
    );

    assign reset_async_n = rst_n & clk_locked;

    always @(posedge clk_100 or negedge reset_async_n) begin
        if (!reset_async_n)
            reset_sync <= 2'b00;
        else
            reset_sync <= {reset_sync[0], 1'b1};
    end

    assign internal_rst_n = reset_sync[1];

    // ------------------------------------------------------------
    // START CDC: 125 MHz -> 100 MHz
    // The source toggle changes on a rising edge of start.
    // The destination synchronizes the toggle and detects changes.
    // ------------------------------------------------------------
    reg start_previous;
    reg start_toggle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_previous <= 1'b0;
            start_toggle   <= 1'b0;
        end else begin
            start_previous <= start;
            if (start && !start_previous)
                start_toggle <= ~start_toggle;
        end
    end

    (* ASYNC_REG = "TRUE" *) reg start_meta_100;
    (* ASYNC_REG = "TRUE" *) reg start_sync_100;
    reg start_sync_100_d;

    wire start_dma = start_sync_100 ^ start_sync_100_d;

    always @(posedge clk_100 or negedge internal_rst_n) begin
        if (!internal_rst_n) begin
            start_meta_100   <= 1'b0;
            start_sync_100   <= 1'b0;
            start_sync_100_d <= 1'b0;
        end else begin
            start_meta_100   <= start_toggle;
            start_sync_100   <= start_meta_100;
            start_sync_100_d <= start_sync_100;
        end
    end

    // ------------------------------------------------------------
    // AXI4 signals
    // ------------------------------------------------------------
    wire [ID_WIDTH-1:0]     axi_awid;
    wire [ADDR_WIDTH-1:0]   axi_awaddr;
    wire [7:0]              axi_awlen;
    wire [2:0]              axi_awsize;
    wire [1:0]              axi_awburst;
    wire                    axi_awvalid, axi_awready;

    wire [DATA_WIDTH-1:0]   axi_wdata;
    wire [DATA_WIDTH/8-1:0] axi_wstrb;
    wire                    axi_wlast, axi_wvalid, axi_wready;

    wire [ID_WIDTH-1:0]     axi_bid;
    wire [1:0]              axi_bresp;
    wire                    axi_bvalid, axi_bready;

    wire [ID_WIDTH-1:0]     axi_arid;
    wire [ADDR_WIDTH-1:0]   axi_araddr;
    wire [7:0]              axi_arlen;
    wire [2:0]              axi_arsize;
    wire [1:0]              axi_arburst;
    wire                    axi_arvalid, axi_arready;

    wire [ID_WIDTH-1:0]     axi_rid;
    wire [DATA_WIDTH-1:0]   axi_rdata;
    wire [1:0]              axi_rresp;
    wire                    axi_rlast, axi_rvalid, axi_rready;

    // ------------------------------------------------------------
    // DMA core: entirely in the 100 MHz clock domain
    // ------------------------------------------------------------
    wire busy_100;
    wire done_100;
    wire error_100;

    axi4_dma_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) u_dma (
        .clk(clk_100),
        .rst_n(internal_rst_n),

        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .transfer_bytes(transfer_bytes),
        .start(start_dma),

        .busy(busy_100),
        .done(done_100),
        .error(error_100),

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
    // On-chip AXI RAM
    // ------------------------------------------------------------
    axi4_ram_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MEM_WORDS(MEM_WORDS)
    ) u_ram (
        .clk(clk_100),
        .rst_n(internal_rst_n),

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

    // ------------------------------------------------------------
    // STATUS CDC: 100 MHz -> 125 MHz
    // Two-stage synchronizers
    // ------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) reg busy_meta, busy_sync;
    (* ASYNC_REG = "TRUE" *) reg done_meta, done_sync;
    (* ASYNC_REG = "TRUE" *) reg error_meta, error_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_meta  <= 1'b0;
            busy_sync  <= 1'b0;
            done_meta  <= 1'b0;
            done_sync  <= 1'b0;
            error_meta <= 1'b0;
            error_sync <= 1'b0;
        end else begin
            busy_meta  <= busy_100;
            busy_sync  <= busy_meta;

            done_meta  <= done_100;
            done_sync  <= done_meta;

            error_meta <= error_100;
            error_sync <= error_meta;
        end
    end

    assign busy  = busy_sync;
    assign done  = done_sync;
    assign error = error_sync;

endmodule
