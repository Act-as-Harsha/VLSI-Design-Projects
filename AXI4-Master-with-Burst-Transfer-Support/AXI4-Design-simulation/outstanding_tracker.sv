`timescale 1ns / 1ps
module outstanding_tracker #(
    parameter integer ID_WIDTH = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,

    input  wire                 alloc_valid,
    input  wire [ID_WIDTH-1:0]  alloc_id,

    input  wire                 complete_valid,
    input  wire [ID_WIDTH-1:0]  complete_id,

    output wire                 alloc_ready,
    output wire                 active,
    output wire                 error_duplicate_alloc
);

    reg [ID_WIDTH-1:0] active_id;
    reg                active_reg;
    reg                duplicate_reg;

    assign alloc_ready           = !active_reg;
    assign active                = active_reg;
    assign error_duplicate_alloc = duplicate_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            active_id     <= {ID_WIDTH{1'b0}};
            active_reg    <= 1'b0;
            duplicate_reg <= 1'b0;
        end else begin
            duplicate_reg <= 1'b0;

            if (alloc_valid && alloc_ready) begin
                active_id  <= alloc_id;
                active_reg <= 1'b1;
            end else if (alloc_valid && !alloc_ready) begin
                duplicate_reg <= 1'b1;
            end

            if (complete_valid && active_reg &&
                (complete_id == active_id)) begin
                active_reg <= 1'b0;
            end
        end
    end

endmodule
