module axi4_dma_top #(
    parameter integer ADDR_WIDTH    = 32,
    parameter integer DATA_WIDTH    = 64,
    parameter integer ID_WIDTH      = 4,
    parameter integer FIFO_DEPTH    = 512,
    parameter integer MAX_BURST_LEN = 16
)(
    input  wire clk,
    input  wire rst_n,

    // DMA configuration
    input  wire [ADDR_WIDTH-1:0] src_addr,
    input  wire [ADDR_WIDTH-1:0] dst_addr,
    input  wire [31:0]           transfer_bytes,
    input  wire                  start,

    output wire                  busy,
    output wire                  done,
    output wire                  error,

    // AXI4 Write Address Channel
    output wire [ID_WIDTH-1:0]     M_AXI_AWID,
    output wire [ADDR_WIDTH-1:0]   M_AXI_AWADDR,
    output wire [7:0]              M_AXI_AWLEN,
    output wire [2:0]              M_AXI_AWSIZE,
    output wire [1:0]              M_AXI_AWBURST,
    output wire                    M_AXI_AWVALID,
    input  wire                    M_AXI_AWREADY,

    // AXI4 Write Data Channel
    output wire [DATA_WIDTH-1:0]   M_AXI_WDATA,
    output wire [DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output wire                    M_AXI_WLAST,
    output wire                    M_AXI_WVALID,
    input  wire                    M_AXI_WREADY,

    // AXI4 Write Response Channel
    input  wire [ID_WIDTH-1:0]     M_AXI_BID,
    input  wire [1:0]              M_AXI_BRESP,
    input  wire                    M_AXI_BVALID,
    output wire                    M_AXI_BREADY,

    // AXI4 Read Address Channel
    output wire [ID_WIDTH-1:0]     M_AXI_ARID,
    output wire [ADDR_WIDTH-1:0]   M_AXI_ARADDR,
    output wire [7:0]              M_AXI_ARLEN,
    output wire [2:0]              M_AXI_ARSIZE,
    output wire [1:0]              M_AXI_ARBURST,
    output wire                    M_AXI_ARVALID,
    input  wire                    M_AXI_ARREADY,

    // AXI4 Read Data Channel
    input  wire [ID_WIDTH-1:0]     M_AXI_RID,
    input  wire [DATA_WIDTH-1:0]   M_AXI_RDATA,
    input  wire [1:0]              M_AXI_RRESP,
    input  wire                    M_AXI_RLAST,
    input  wire                    M_AXI_RVALID,
    output wire                    M_AXI_RREADY
);

    wire rd_cmd_valid;
    wire rd_cmd_ready;
    wire [ADDR_WIDTH-1:0] rd_cmd_addr;
    wire [8:0] rd_cmd_beats;
    wire [ID_WIDTH-1:0] rd_cmd_id;

    wire wr_cmd_valid;
    wire wr_cmd_ready;
    wire [ADDR_WIDTH-1:0] wr_cmd_addr;
    wire [8:0] wr_cmd_beats;
    wire [ID_WIDTH-1:0] wr_cmd_id;

    wire [DATA_WIDTH-1:0] fifo_s_data;
    wire fifo_s_valid;
    wire fifo_s_ready;

    wire [DATA_WIDTH-1:0] fifo_m_data;
    wire fifo_m_valid;
    wire fifo_m_ready;

    wire [15:0] fifo_count;
    wire [15:0] fifo_free_count;

    wire rd_busy;
    wire rd_done;
    wire rd_error;
    wire [ID_WIDTH-1:0] rd_done_id;

    wire wr_busy;
    wire wr_done;
    wire wr_error;
    wire [ID_WIDTH-1:0] wr_done_id;

    wire rd_tracker_ready;
    wire wr_tracker_ready;

    // One tracker for reads and one tracker for writes.
    // This V1 architecture permits one outstanding transaction
    // in each direction.
    outstanding_tracker #(
        .ID_WIDTH(ID_WIDTH)
    ) u_read_tracker (
        .clk(clk),
        .rst_n(rst_n),
        .alloc_valid(rd_cmd_valid && rd_cmd_ready),
        .alloc_id(rd_cmd_id),
        .complete_valid(rd_done),
        .complete_id(rd_done_id),
        .alloc_ready(rd_tracker_ready),
        .active(),
        .error_duplicate_alloc()
    );

    outstanding_tracker #(
        .ID_WIDTH(ID_WIDTH)
    ) u_write_tracker (
        .clk(clk),
        .rst_n(rst_n),
        .alloc_valid(wr_cmd_valid && wr_cmd_ready),
        .alloc_id(wr_cmd_id),
        .complete_valid(wr_done),
        .complete_id(wr_done_id),
        .alloc_ready(wr_tracker_ready),
        .active(),
        .error_duplicate_alloc()
    );

    dma_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) u_dma_controller (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .src_addr_cfg(src_addr),
        .dst_addr_cfg(dst_addr),
        .transfer_bytes_cfg(transfer_bytes),

        .busy(busy),
        .done(done),
        .error(error),

        .rd_cmd_valid(rd_cmd_valid),
        .rd_cmd_ready(rd_cmd_ready),
        .rd_cmd_addr(rd_cmd_addr),
        .rd_cmd_beats(rd_cmd_beats),
        .rd_cmd_id(rd_cmd_id),

        .wr_cmd_valid(wr_cmd_valid),
        .wr_cmd_ready(wr_cmd_ready),
        .wr_cmd_addr(wr_cmd_addr),
        .wr_cmd_beats(wr_cmd_beats),
        .wr_cmd_id(wr_cmd_id),

        .fifo_count(fifo_count),
        .fifo_free_count(fifo_free_count),

        .rd_done(rd_done),
        .rd_done_id(rd_done_id),
        .rd_error(rd_error),

        .wr_done(wr_done),
        .wr_done_id(wr_done_id),
        .wr_error(wr_error),

        .rd_tracker_ready(rd_tracker_ready),
        .wr_tracker_ready(wr_tracker_ready)
    );

    axis_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) u_data_fifo (
        .clk(clk),
        .rst_n(rst_n),

        .s_data(fifo_s_data),
        .s_valid(fifo_s_valid),
        .s_ready(fifo_s_ready),

        .m_data(fifo_m_data),
        .m_valid(fifo_m_valid),
        .m_ready(fifo_m_ready),

        .count(fifo_count),
        .free_count(fifo_free_count)
    );

    axi4_read_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_read_engine (
        .clk(clk),
        .rst_n(rst_n),

        .cmd_valid(rd_cmd_valid),
        .cmd_ready(rd_cmd_ready),
        .cmd_addr(rd_cmd_addr),
        .cmd_beats(rd_cmd_beats),
        .cmd_id(rd_cmd_id),

        .fifo_data(fifo_s_data),
        .fifo_valid(fifo_s_valid),
        .fifo_ready(fifo_s_ready),

        .busy(rd_busy),
        .done(rd_done),
        .error(rd_error),
        .done_id(rd_done_id),

        .m_axi_arid(M_AXI_ARID),
        .m_axi_araddr(M_AXI_ARADDR),
        .m_axi_arlen(M_AXI_ARLEN),
        .m_axi_arsize(M_AXI_ARSIZE),
        .m_axi_arburst(M_AXI_ARBURST),
        .m_axi_arvalid(M_AXI_ARVALID),
        .m_axi_arready(M_AXI_ARREADY),

        .m_axi_rid(M_AXI_RID),
        .m_axi_rdata(M_AXI_RDATA),
        .m_axi_rresp(M_AXI_RRESP),
        .m_axi_rlast(M_AXI_RLAST),
        .m_axi_rvalid(M_AXI_RVALID),
        .m_axi_rready(M_AXI_RREADY)
    );

    axi4_write_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_write_engine (
        .clk(clk),
        .rst_n(rst_n),

        .cmd_valid(wr_cmd_valid),
        .cmd_ready(wr_cmd_ready),
        .cmd_addr(wr_cmd_addr),
        .cmd_beats(wr_cmd_beats),
        .cmd_id(wr_cmd_id),

        .fifo_data(fifo_m_data),
        .fifo_valid(fifo_m_valid),
        .fifo_ready(fifo_m_ready),

        .busy(wr_busy),
        .done(wr_done),
        .error(wr_error),
        .done_id(wr_done_id),

        .m_axi_awid(M_AXI_AWID),
        .m_axi_awaddr(M_AXI_AWADDR),
        .m_axi_awlen(M_AXI_AWLEN),
        .m_axi_awsize(M_AXI_AWSIZE),
        .m_axi_awburst(M_AXI_AWBURST),
        .m_axi_awvalid(M_AXI_AWVALID),
        .m_axi_awready(M_AXI_AWREADY),

        .m_axi_wdata(M_AXI_WDATA),
        .m_axi_wstrb(M_AXI_WSTRB),
        .m_axi_wlast(M_AXI_WLAST),
        .m_axi_wvalid(M_AXI_WVALID),
        .m_axi_wready(M_AXI_WREADY),

        .m_axi_bid(M_AXI_BID),
        .m_axi_bresp(M_AXI_BRESP),
        .m_axi_bvalid(M_AXI_BVALID),
        .m_axi_bready(M_AXI_BREADY)
    );

endmodule
