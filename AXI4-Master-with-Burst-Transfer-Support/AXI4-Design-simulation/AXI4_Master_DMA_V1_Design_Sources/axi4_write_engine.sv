module axi4_write_engine #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    cmd_valid,
    output wire                    cmd_ready,
    input  wire [ADDR_WIDTH-1:0]   cmd_addr,
    input  wire [8:0]              cmd_beats,
    input  wire [ID_WIDTH-1:0]     cmd_id,

    input  wire [DATA_WIDTH-1:0]   fifo_data,
    input  wire                    fifo_valid,
    output wire                    fifo_ready,

    output wire                    busy,
    output reg                     done,
    output reg                     error,
    output reg  [ID_WIDTH-1:0]     done_id,

    output wire [ID_WIDTH-1:0]     m_axi_awid,
    output wire [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [7:0]              m_axi_awlen,
    output wire [2:0]              m_axi_awsize,
    output wire [1:0]              m_axi_awburst,
    output wire                    m_axi_awvalid,
    input  wire                    m_axi_awready,

    output wire [DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                    m_axi_wlast,
    output wire                    m_axi_wvalid,
    input  wire                    m_axi_wready,

    input  wire [ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]              m_axi_bresp,
    input  wire                    m_axi_bvalid,
    output wire                    m_axi_bready
);

    localparam integer BYTE_LG2 = $clog2(DATA_WIDTH / 8);
    localparam [2:0] AXI_SIZE  = BYTE_LG2;

    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_AW   = 2'd1;
    localparam [1:0] S_W    = 2'd2;
    localparam [1:0] S_B    = 2'd3;

    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [8:0] beats_reg;
    reg [8:0] beat_count;
    reg [ID_WIDTH-1:0] id_reg;

    assign cmd_ready = (state == S_IDLE);
    assign busy      = (state != S_IDLE);

    assign m_axi_awid    = id_reg;
    assign m_axi_awaddr  = addr_reg;
    assign m_axi_awlen   = beats_reg - 1'b1;
    assign m_axi_awsize  = AXI_SIZE;
    assign m_axi_awburst = 2'b01;        // INCR
    assign m_axi_awvalid = (state == S_AW);

    assign m_axi_wdata  = fifo_data;
    assign m_axi_wstrb  = {DATA_WIDTH/8{1'b1}};
    assign m_axi_wvalid = (state == S_W) && fifo_valid;
    assign m_axi_wlast  = (state == S_W) &&
                          (beat_count == (beats_reg - 1'b1));

    // Pop one FIFO entry only when the AXI write data beat is accepted.
    assign fifo_ready   = (state == S_W) && m_axi_wready;
    assign m_axi_bready = (state == S_B);

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_reg   <= {ADDR_WIDTH{1'b0}};
            beats_reg  <= 9'd0;
            beat_count <= 9'd0;
            id_reg     <= {ID_WIDTH{1'b0}};
            done       <= 1'b0;
            done_id    <= {ID_WIDTH{1'b0}};
            error      <= 1'b0;
        end else begin
            done  <= 1'b0;
            error <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (cmd_valid && cmd_ready) begin
                        addr_reg   <= cmd_addr;
                        beats_reg  <= cmd_beats;
                        beat_count <= 9'd0;
                        id_reg     <= cmd_id;
                        state      <= S_AW;
                    end
                end

                S_AW: begin
                    if (m_axi_awvalid && m_axi_awready)
                        state <= S_W;
                end

                S_W: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        if (m_axi_wlast)
                            state <= S_B;
                        else
                            beat_count <= beat_count + 1'b1;
                    end
                end

                S_B: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        done    <= 1'b1;
                        done_id <= id_reg;
                        error   <= (m_axi_bresp != 2'b00);
                        state   <= S_IDLE;
                    end
                end

                default:
                    state <= S_IDLE;
            endcase
        end
    end

endmodule
