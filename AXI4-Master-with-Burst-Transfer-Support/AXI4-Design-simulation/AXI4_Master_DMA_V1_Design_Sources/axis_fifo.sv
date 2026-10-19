module axis_fifo #(
    parameter integer DATA_WIDTH = 64,
    parameter integer DEPTH      = 512
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire                   s_valid,
    output wire                   s_ready,

    output wire [DATA_WIDTH-1:0]  m_data,
    output wire                   m_valid,
    input  wire                   m_ready,

    output wire [15:0]            count,
    output wire [15:0]            free_count
);

    localparam integer PTR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0]  wr_ptr;
    reg [PTR_WIDTH-1:0]  rd_ptr;
    reg [PTR_WIDTH:0]    count_reg;

    wire do_write = s_valid && s_ready;
    wire do_read  = m_valid && m_ready;

    wire [PTR_WIDTH:0] free_count_ext = DEPTH - count_reg;

    assign s_ready = (count_reg < DEPTH);
    assign m_valid = (count_reg != 0);
    assign m_data  = mem[rd_ptr];

    assign count      = count_reg[15:0];
    assign free_count = free_count_ext[15:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr    <= {PTR_WIDTH{1'b0}};
            rd_ptr    <= {PTR_WIDTH{1'b0}};
            count_reg <= {(PTR_WIDTH+1){1'b0}};
        end else begin
            if (do_write) begin
                mem[wr_ptr] <= s_data;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= {PTR_WIDTH{1'b0}};
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (do_read) begin
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= {PTR_WIDTH{1'b0}};
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({do_write, do_read})
                2'b10: count_reg <= count_reg + 1'b1;
                2'b01: count_reg <= count_reg - 1'b1;
                default: count_reg <= count_reg;
            endcase
        end
    end

endmodule
