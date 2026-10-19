
`timescale 1ns / 1ps

module pynq_z2_dma_demo (
    input  wire       clk,
    input  wire       btn_reset,
    input  wire       btn_start,
    output wire [3:0] led
);

    localparam [31:0] SRC_ADDR       = 32'h0000_0000;
    localparam [31:0] DST_ADDR       = 32'h0000_1000;
    localparam [31:0] TRANSFER_BYTES = 32'd256;

    localparam [20:0] DEBOUNCE_LIMIT = 21'd1_249_999;

    // --------------------------------------------------
    // Button synchronization and debounce: 125 MHz
    // --------------------------------------------------
    reg start_meta, start_sync;
    reg start_debounced, start_previous;
    reg [20:0] debounce_count;

    wire start_event = start_debounced && !start_previous;

    always @(posedge clk or posedge btn_reset) begin
        if (btn_reset) begin
            start_meta      <= 1'b0;
            start_sync      <= 1'b0;
            start_debounced <= 1'b0;
            start_previous  <= 1'b0;
            debounce_count  <= 21'd0;
        end else begin
            start_meta <= btn_start;
            start_sync <= start_meta;
            start_previous <= start_debounced;

            if (start_sync == start_debounced) begin
                debounce_count <= 21'd0;
            end else if (debounce_count == DEBOUNCE_LIMIT) begin
                start_debounced <= start_sync;
                debounce_count  <= 21'd0;
            end else begin
                debounce_count <= debounce_count + 1'b1;
            end
        end
    end

    // --------------------------------------------------
    // Start request CDC: 125 MHz -> 100 MHz
    // A toggle avoids losing a short start pulse.
    // --------------------------------------------------
    reg start_toggle;

    always @(posedge clk or posedge btn_reset) begin
        if (btn_reset)
            start_toggle <= 1'b0;
        else if (start_event)
            start_toggle <= ~start_toggle;
    end

    // --------------------------------------------------
    // DMA status and clock-domain interface
    // --------------------------------------------------
    wire dma_busy;
    wire dma_done;
    wire dma_error;

    // This signal is driven by the actual 100 MHz clock
    // inside axi4_dma_fpga_top. It is not exposed at the
    // top-level interface, so do not synchronize start here.
    //
    // The top-level wrapper must perform the start CDC.
    // See the required wrapper change below.

    axi4_dma_fpga_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(64),
        .ID_WIDTH(4),
        .FIFO_DEPTH(512),
        .MAX_BURST_LEN(16),
        .MEM_WORDS(4096)
    ) u_demo_dma (
        .clk(clk),
        .rst_n(~btn_reset),
        .src_addr(SRC_ADDR),
        .dst_addr(DST_ADDR),
        .transfer_bytes(TRANSFER_BYTES),
        .start(start_event),
        .busy(dma_busy),
        .done(dma_done),
        .error(dma_error)
    );

    // --------------------------------------------------
    // Synchronize status back to 125 MHz
    // --------------------------------------------------
    (* ASYNC_REG = "TRUE" *) reg done_meta, done_sync;
    (* ASYNC_REG = "TRUE" *) reg error_meta, error_sync;
    (* ASYNC_REG = "TRUE" *) reg busy_meta, busy_sync;

    reg done_latched, error_latched;

    always @(posedge clk or posedge btn_reset) begin
        if (btn_reset) begin
            done_meta    <= 1'b0;
            done_sync    <= 1'b0;
            error_meta   <= 1'b0;
            error_sync   <= 1'b0;
            busy_meta    <= 1'b0;
            busy_sync    <= 1'b0;
            done_latched <= 1'b0;
            error_latched <= 1'b0;
        end else begin
            done_meta  <= dma_done;
            done_sync  <= done_meta;
            error_meta <= dma_error;
            error_sync <= error_meta;
            busy_meta  <= dma_busy;
            busy_sync  <= busy_meta;

            if (start_event) begin
                done_latched  <= 1'b0;
                error_latched <= 1'b0;
            end

            if (done_sync)
                done_latched <= 1'b1;

            if (error_sync)
                error_latched <= 1'b1;
        end
    end

    assign led[0] = busy_sync;
    assign led[1] = done_latched;
    assign led[2] = error_latched;
    assign led[3] = ~busy_sync & ~error_latched;

endmodule
