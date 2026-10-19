module axi4_burst_calc #(
    parameter integer ADDR_WIDTH    = 32,
    parameter integer DATA_WIDTH    = 64,
    parameter integer MAX_BURST_LEN = 16
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [31:0]           remaining_bytes,
    input  wire [15:0]           capacity_beats,

    output reg  [8:0]            burst_beats,
    output reg  [7:0]            burst_len,
    output reg                    burst_valid
);

    localparam integer BYTES_PER_BEAT = DATA_WIDTH / 8;
    localparam integer BYTE_LG2       = $clog2(BYTES_PER_BEAT);

    integer remaining_beats_i;
    integer boundary_bytes_i;
    integer boundary_beats_i;
    integer capacity_i;
    integer selected_i;

    always @* begin
        remaining_beats_i = remaining_bytes >> BYTE_LG2;

        // Bytes remaining before the next 4 KB boundary.
        boundary_bytes_i = 4096 - addr[11:0];

        // Convert available boundary space to beats.
        boundary_beats_i = boundary_bytes_i >> BYTE_LG2;

        capacity_i = capacity_beats;
        selected_i = remaining_beats_i;

        if (selected_i > MAX_BURST_LEN)
            selected_i = MAX_BURST_LEN;

        if (selected_i > boundary_beats_i)
            selected_i = boundary_beats_i;

        if (selected_i > capacity_i)
            selected_i = capacity_i;

        if (selected_i > 256)
            selected_i = 256;

        if (selected_i > 0) begin
            burst_valid = 1'b1;
            burst_beats = selected_i[8:0];
            burst_len   = selected_i - 1;
        end else begin
            burst_valid = 1'b0;
            burst_beats = 9'd0;
            burst_len   = 8'd0;
        end
    end

endmodule
