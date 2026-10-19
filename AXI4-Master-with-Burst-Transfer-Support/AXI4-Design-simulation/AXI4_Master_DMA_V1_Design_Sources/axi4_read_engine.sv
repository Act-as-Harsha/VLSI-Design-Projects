module axi4_read_engine #(
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

    output wire [DATA_WIDTH-1:0]   fifo_data,
    output wire                    fifo_valid,
    input  wire                    fifo_ready,

    output wire                    busy,
    output reg                     done,
    output reg                     error,
    output reg  [ID_WIDTH-1:0]     done_id,

    output wire [ID_WIDTH-1:0]     m_axi_arid,
    output wire [ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [7:0]              m_axi_arlen,
    output wire [2:0]              m_axi_arsize,
    output wire [1:0]              m_axi_arburst,
    output wire                    m_axi_arvalid,
    input  wire                    m_axi_arready,

    input  wire [ID_WIDTH-1:0]     m_axi_rid,
    input  wire [DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [1:0]              m_axi_rresp,
    input  wire                    m_axi_rlast,
    input  wire                    m_axi_rvalid,
    output wire                    m_axi_rready
);

    localparam integer BYTE_LG2 = $clog2(DATA_WIDTH / 8);
    localparam [2:0] AXI_SIZE  = BYTE_LG2;

    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_AR   = 2'd1;
    localparam [1:0] S_R    = 2'd2;

    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [8:0] beats_reg;
    reg [8:0] beat_count;
    reg [ID_WIDTH-1:0] id_reg;
    reg error_seen;

    assign cmd_ready = (state == S_IDLE);
    assign busy      = (state != S_IDLE);

    assign m_axi_arid    = id_reg;
    assign m_axi_araddr  = addr_reg;
    assign m_axi_arlen   = beats_reg - 1'b1;
    assign m_axi_arsize  = AXI_SIZE;
    assign m_axi_arburst = 2'b01;       // INCR
    assign m_axi_arvalid = (state == S_AR);

    // Backpressure the AXI read data channel when the FIFO is full.
    assign m_axi_rready = (state == S_R) && fifo_ready;

    assign fifo_data  = m_axi_rdata;
    assign fifo_valid = m_axi_rvalid && m_axi_rready;

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_reg   <= {ADDR_WIDTH{1'b0}};
            beats_reg  <= 9'd0;
            beat_count <= 9'd0;
            id_reg     <= {ID_WIDTH{1'b0}};
            error_seen <= 1'b0;
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
                        error_seen <= 1'b0;
                        state      <= S_AR;
                    end
                end

                S_AR: begin
                    if (m_axi_arvalid && m_axi_arready)
                        state <= S_R;
                end

                S_R: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        if (m_axi_rresp != 2'b00)
                            error_seen <= 1'b1;

                        if (m_axi_rlast ||
                            (beat_count == (beats_reg - 1'b1))) begin
                            done    <= 1'b1;
                            done_id <= id_reg;
                            error   <= error_seen ||
                                       (m_axi_rresp != 2'b00);
                            state   <= S_IDLE;
                        end else begin
                            beat_count <= beat_count + 1'b1;
                        end
                    end
                end

                default:
                    state <= S_IDLE;
            endcase
        end
    end

endmodule
