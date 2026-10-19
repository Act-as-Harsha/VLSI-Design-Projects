
`timescale 1ns / 1ps

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
    output reg                   burst_valid
);

    // Optimized for this project: 64-bit data and 16-beat maximum.
    reg [4:0] remaining_candidate;
    reg [4:0] boundary_candidate;
    reg [4:0] capacity_candidate;
    reg [4:0] selected_beats;

    always @* begin
        // Maximum 16 beats; otherwise count complete 8-byte beats.
        if (remaining_bytes[31:7] != 0)
            remaining_candidate = 5'd16;
        else
            remaining_candidate = {1'b0, remaining_bytes[6:3]};

        // Do not cross a 4 KB boundary.
        if (addr[11:3] <= 9'd496)
            boundary_candidate = 5'd16;
        else
            // Valid in this branch: addr[11:3] is 497 through 511.
            boundary_candidate = 5'd0 - addr[7:3];

        // Limit the burst to the available FIFO capacity.
        if (capacity_beats >= 16)
            capacity_candidate = 5'd16;
        else
            capacity_candidate = capacity_beats[4:0];

        // Select the smallest candidate.
        selected_beats = remaining_candidate;

        if (boundary_candidate < selected_beats)
            selected_beats = boundary_candidate;

        if (capacity_candidate < selected_beats)
            selected_beats = capacity_candidate;

        burst_valid = (selected_beats != 0);
        burst_beats = {4'b0000, selected_beats};

        if (selected_beats != 0)
            burst_len = {3'b000, selected_beats} - 8'd1;
        else
            burst_len = 8'd0;
    end

endmodule
