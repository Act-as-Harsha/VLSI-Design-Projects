module dma_controller #(
    parameter integer ADDR_WIDTH    = 32,
    parameter integer DATA_WIDTH    = 64,
    parameter integer MAX_BURST_LEN = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     start,
    input  wire [ADDR_WIDTH-1:0]    src_addr_cfg,
    input  wire [ADDR_WIDTH-1:0]    dst_addr_cfg,
    input  wire [31:0]              transfer_bytes_cfg,

    output reg                      busy,
    output reg                      done,
    output reg                      error,

    output wire                     rd_cmd_valid,
    input  wire                     rd_cmd_ready,
    output wire [ADDR_WIDTH-1:0]    rd_cmd_addr,
    output wire [8:0]               rd_cmd_beats,
    output wire [3:0]               rd_cmd_id,

    output wire                     wr_cmd_valid,
    input  wire                     wr_cmd_ready,
    output wire [ADDR_WIDTH-1:0]    wr_cmd_addr,
    output wire [8:0]               wr_cmd_beats,
    output wire [3:0]               wr_cmd_id,

    input  wire [15:0]              fifo_count,
    input  wire [15:0]              fifo_free_count,

    input  wire                     rd_done,
    input  wire [3:0]               rd_done_id,
    input  wire                     rd_error,

    input  wire                     wr_done,
    input  wire [3:0]               wr_done_id,
    input  wire                     wr_error,

    input  wire                     rd_tracker_ready,
    input  wire                     wr_tracker_ready
);

    localparam integer BYTES_PER_BEAT = DATA_WIDTH / 8;
    localparam integer BYTE_LG2       = $clog2(BYTES_PER_BEAT);

    reg [ADDR_WIDTH-1:0] rd_addr_reg;
    reg [ADDR_WIDTH-1:0] wr_addr_reg;
    reg [31:0] rd_remaining_reg;
    reg [31:0] wr_remaining_reg;

    reg rd_inflight;
    reg wr_inflight;

    wire rd_burst_valid;
    wire [8:0] rd_burst_beats;
    wire [7:0] rd_burst_len_unused;

    wire wr_burst_valid;
    wire [8:0] wr_burst_beats;
    wire [7:0] wr_burst_len_unused;

    wire config_aligned;

    assign config_aligned =
        (src_addr_cfg[BYTE_LG2-1:0] == {BYTE_LG2{1'b0}}) &&
        (dst_addr_cfg[BYTE_LG2-1:0] == {BYTE_LG2{1'b0}}) &&
        (transfer_bytes_cfg[BYTE_LG2-1:0] == {BYTE_LG2{1'b0}});

    axi4_burst_calc #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) u_read_burst_calc (
        .addr(rd_addr_reg),
        .remaining_bytes(rd_remaining_reg),
        .capacity_beats(fifo_free_count),
        .burst_beats(rd_burst_beats),
        .burst_len(rd_burst_len_unused),
        .burst_valid(rd_burst_valid)
    );

    axi4_burst_calc #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) u_write_burst_calc (
        .addr(wr_addr_reg),
        .remaining_bytes(wr_remaining_reg),
        .capacity_beats(fifo_count),
        .burst_beats(wr_burst_beats),
        .burst_len(wr_burst_len_unused),
        .burst_valid(wr_burst_valid)
    );

    // V1 uses one outstanding transaction on each direction.
    assign rd_cmd_valid =
        busy &&
        !rd_inflight &&
        rd_tracker_ready &&
        rd_burst_valid;

    assign rd_cmd_addr  = rd_addr_reg;
    assign rd_cmd_beats = rd_burst_beats;
    assign rd_cmd_id    = 4'd0;

    assign wr_cmd_valid =
        busy &&
        !wr_inflight &&
        wr_tracker_ready &&
        wr_burst_valid;

    assign wr_cmd_addr  = wr_addr_reg;
    assign wr_cmd_beats = wr_burst_beats;
    assign wr_cmd_id    = 4'd0;

    always @(posedge clk) begin
        if (!rst_n) begin
            busy             <= 1'b0;
            done             <= 1'b0;
            error            <= 1'b0;

            rd_addr_reg      <= {ADDR_WIDTH{1'b0}};
            wr_addr_reg      <= {ADDR_WIDTH{1'b0}};
            rd_remaining_reg <= 32'd0;
            wr_remaining_reg <= 32'd0;

            rd_inflight      <= 1'b0;
            wr_inflight      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                if ((transfer_bytes_cfg != 0) && config_aligned) begin
                    busy             <= 1'b1;
                    error            <= 1'b0;

                    rd_addr_reg      <= src_addr_cfg;
                    wr_addr_reg      <= dst_addr_cfg;
                    rd_remaining_reg <= transfer_bytes_cfg;
                    wr_remaining_reg <= transfer_bytes_cfg;

                    rd_inflight      <= 1'b0;
                    wr_inflight      <= 1'b0;
                end else begin
                    error <= 1'b1;
                end
            end

            if (rd_cmd_valid && rd_cmd_ready) begin
                rd_inflight      <= 1'b1;
                rd_addr_reg      <= rd_addr_reg +
                                     (rd_burst_beats << BYTE_LG2);
                rd_remaining_reg <= rd_remaining_reg -
                                     (rd_burst_beats << BYTE_LG2);
            end

            if (wr_cmd_valid && wr_cmd_ready) begin
                wr_inflight      <= 1'b1;
                wr_addr_reg      <= wr_addr_reg +
                                     (wr_burst_beats << BYTE_LG2);
                wr_remaining_reg <= wr_remaining_reg -
                                     (wr_burst_beats << BYTE_LG2);
            end

            if (rd_done)
                rd_inflight <= 1'b0;

            if (wr_done)
                wr_inflight <= 1'b0;

            if (rd_error || wr_error) begin
                busy        <= 1'b0;
                error       <= 1'b1;
                rd_inflight <= 1'b0;
                wr_inflight <= 1'b0;
            end else if (busy &&
                         (rd_remaining_reg == 0) &&
                         (wr_remaining_reg == 0) &&
                         !rd_inflight &&
                         !wr_inflight &&
                         (fifo_count == 0)) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end

endmodule
