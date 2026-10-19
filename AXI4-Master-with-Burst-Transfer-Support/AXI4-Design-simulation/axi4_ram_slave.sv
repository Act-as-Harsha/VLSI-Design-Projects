`timescale 1ns / 1ps

// Simple synthesizable AXI4 INCR memory slave.
// Intended for FPGA integration of the DMA project.
// For a real DDR design, replace this block with AXI Interconnect + MIG/DDR controller.
//
// DATA_WIDTH=64 -> 8 bytes/beat.
// MEM_WORDS=4096 -> 32 KiB of 64-bit storage.
// Address mapping uses address bits [14:3].

module axi4_ram_slave #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter integer MEM_WORDS  = 4096
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,

    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,

    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,

    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready
);

    localparam integer BYTES_PER_BEAT = DATA_WIDTH / 8;
    localparam integer BYTE_BITS      = $clog2(BYTES_PER_BEAT);
    localparam integer ADDR_INDEX_BITS = $clog2(MEM_WORDS);

    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    // Write channel state.
    reg                  wr_aw_active;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [8:0]            wr_beats_left;
    reg [ID_WIDTH-1:0]   wr_id;

    // Read channel state.
    reg                  rd_active;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [8:0]            rd_beats_left;
    reg [ID_WIDTH-1:0]   rd_id;

    integer i;
    integer b;
    integer wr_index;
    integer rd_index;

    // Only one write burst and one read burst are tracked at a time.
    assign s_axi_awready = !wr_aw_active && !s_axi_bvalid;
    assign s_axi_wready  = wr_aw_active && !s_axi_bvalid;

    assign s_axi_arready = !rd_active && !s_axi_rvalid;

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_aw_active <= 1'b0;
            wr_addr      <= {ADDR_WIDTH{1'b0}};
            wr_beats_left <= 9'd0;
            wr_id        <= {ID_WIDTH{1'b0}};

            rd_active    <= 1'b0;
            rd_addr      <= {ADDR_WIDTH{1'b0}};
            rd_beats_left <= 9'd0;
            rd_id        <= {ID_WIDTH{1'b0}};

            s_axi_bid    <= {ID_WIDTH{1'b0}};
            s_axi_bresp  <= 2'b00;
            s_axi_bvalid <= 1'b0;

            s_axi_rid    <= {ID_WIDTH{1'b0}};
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
            s_axi_rlast  <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end else begin

            // -------------------------
            // Write address handshake
            // -------------------------
            if (s_axi_awvalid && s_axi_awready) begin
                wr_aw_active  <= 1'b1;
                wr_addr       <= s_axi_awaddr;
                wr_beats_left <= {1'b0, s_axi_awlen} + 9'd1;
                wr_id         <= s_axi_awid;
            end

            // -------------------------
            // Write data handshake
            // -------------------------
            if (s_axi_wvalid && s_axi_wready) begin
                wr_index = (wr_addr >> BYTE_BITS);

                // MEM_WORDS is expected to be a power of two.
                wr_index = wr_index & (MEM_WORDS - 1);

                for (b = 0; b < BYTES_PER_BEAT; b = b + 1) begin
                    if (s_axi_wstrb[b])
                        mem[wr_index][8*b +: 8] <= s_axi_wdata[8*b +: 8];
                end

                wr_addr <= wr_addr + BYTES_PER_BEAT;

                if (wr_beats_left == 9'd1) begin
                    wr_beats_left <= 9'd0;
                    wr_aw_active  <= 1'b0;

                    s_axi_bid    <= wr_id;
                    s_axi_bresp  <= 2'b00; // OKAY
                    s_axi_bvalid <= 1'b1;
                end else begin
                    wr_beats_left <= wr_beats_left - 9'd1;
                end
            end

            // -------------------------
            // Write response handshake
            // -------------------------
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // -------------------------
            // Read address handshake
            // -------------------------
            if (s_axi_arvalid && s_axi_arready) begin
                rd_active     <= 1'b1;
                rd_addr       <= s_axi_araddr;
                rd_beats_left <= {1'b0, s_axi_arlen} + 9'd1;
                rd_id         <= s_axi_arid;
            end

            // -------------------------
            // Create read data
            // -------------------------
            if (rd_active && !s_axi_rvalid) begin
                rd_index = (rd_addr >> BYTE_BITS);
                rd_index = rd_index & (MEM_WORDS - 1);

                s_axi_rid    <= rd_id;
                s_axi_rdata  <= mem[rd_index];
                s_axi_rresp  <= 2'b00; // OKAY
                s_axi_rlast  <= (rd_beats_left == 9'd1);
                s_axi_rvalid <= 1'b1;
            end

            // -------------------------
            // Read data handshake
            // -------------------------
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;

                if (rd_beats_left == 9'd1) begin
                    rd_beats_left <= 9'd0;
                    rd_active     <= 1'b0;
                    s_axi_rlast   <= 1'b0;
                end else begin
                    rd_beats_left <= rd_beats_left - 9'd1;
                    rd_addr       <= rd_addr + BYTES_PER_BEAT;
                end
            end
        end
    end

    // Deterministic initialization for a useful FPGA demo.
    // Synthesis may infer distributed/BRAM initialization depending on device/tool settings.
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = {32'h1000_0000, i[31:0]};
    end

endmodule
