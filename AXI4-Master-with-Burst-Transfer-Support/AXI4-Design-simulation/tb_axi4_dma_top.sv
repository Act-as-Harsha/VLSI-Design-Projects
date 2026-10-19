`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/18/2026 09:56:42 PM
// Design Name: 
// Module Name: tb_axi4_dma_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_axi4_dma_top;

    localparam integer ADDR_WIDTH = 32;
    localparam integer DATA_WIDTH = 64;
    localparam integer ID_WIDTH   = 4;

    reg clk;
    reg rst_n;

    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dst_addr;
    reg [31:0]           transfer_bytes;
    reg                  start;

    wire busy;
    wire done;
    wire error;

    // -----------------------------
    // AXI Write Address
    // -----------------------------
    wire [ID_WIDTH-1:0]     M_AXI_AWID;
    wire [ADDR_WIDTH-1:0]   M_AXI_AWADDR;
    wire [7:0]              M_AXI_AWLEN;
    wire [2:0]              M_AXI_AWSIZE;
    wire [1:0]              M_AXI_AWBURST;
    wire                    M_AXI_AWVALID;
    wire                    M_AXI_AWREADY;

    // -----------------------------
    // AXI Write Data
    // -----------------------------
    wire [DATA_WIDTH-1:0]   M_AXI_WDATA;
    wire [DATA_WIDTH/8-1:0] M_AXI_WSTRB;
    wire                    M_AXI_WLAST;
    wire                    M_AXI_WVALID;
    wire                    M_AXI_WREADY;

    // -----------------------------
    // AXI Write Response
    // -----------------------------
    wire [ID_WIDTH-1:0]     M_AXI_BID;
    wire [1:0]              M_AXI_BRESP;
    wire                    M_AXI_BVALID;
    wire                    M_AXI_BREADY;

    // -----------------------------
    // AXI Read Address
    // -----------------------------
    wire [ID_WIDTH-1:0]     M_AXI_ARID;
    wire [ADDR_WIDTH-1:0]   M_AXI_ARADDR;
    wire [7:0]              M_AXI_ARLEN;
    wire [2:0]              M_AXI_ARSIZE;
    wire [1:0]              M_AXI_ARBURST;
    wire                    M_AXI_ARVALID;
    wire                    M_AXI_ARREADY;

    // -----------------------------
    // AXI Read Data
    // -----------------------------
    wire [ID_WIDTH-1:0]     M_AXI_RID;
    wire [DATA_WIDTH-1:0]   M_AXI_RDATA;
    wire [1:0]              M_AXI_RRESP;
    wire                    M_AXI_RLAST;
    wire                    M_AXI_RVALID;
    wire                    M_AXI_RREADY;

    axi4_dma_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(512),
        .MAX_BURST_LEN(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .transfer_bytes(transfer_bytes),
        .start(start),

        .busy(busy),
        .done(done),
        .error(error),

        .M_AXI_AWID(M_AXI_AWID),
        .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWLEN(M_AXI_AWLEN),
        .M_AXI_AWSIZE(M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),

        .M_AXI_WDATA(M_AXI_WDATA),
        .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_WVALID(M_AXI_WVALID),
        .M_AXI_WREADY(M_AXI_WREADY),

        .M_AXI_BID(M_AXI_BID),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(M_AXI_BREADY),

        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),

        .M_AXI_RID(M_AXI_RID),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY)
    );

    axi4_memory_model #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MEM_WORDS(16384)
    ) mem_model (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awid(M_AXI_AWID),
        .s_axi_awaddr(M_AXI_AWADDR),
        .s_axi_awlen(M_AXI_AWLEN),
        .s_axi_awsize(M_AXI_AWSIZE),
        .s_axi_awburst(M_AXI_AWBURST),
        .s_axi_awvalid(M_AXI_AWVALID),
        .s_axi_awready(M_AXI_AWREADY),

        .s_axi_wdata(M_AXI_WDATA),
        .s_axi_wstrb(M_AXI_WSTRB),
        .s_axi_wlast(M_AXI_WLAST),
        .s_axi_wvalid(M_AXI_WVALID),
        .s_axi_wready(M_AXI_WREADY),

        .s_axi_bid(M_AXI_BID),
        .s_axi_bresp(M_AXI_BRESP),
        .s_axi_bvalid(M_AXI_BVALID),
        .s_axi_bready(M_AXI_BREADY),

        .s_axi_arid(M_AXI_ARID),
        .s_axi_araddr(M_AXI_ARADDR),
        .s_axi_arlen(M_AXI_ARLEN),
        .s_axi_arsize(M_AXI_ARSIZE),
        .s_axi_arburst(M_AXI_ARBURST),
        .s_axi_arvalid(M_AXI_ARVALID),
        .s_axi_arready(M_AXI_ARREADY),

        .s_axi_rid(M_AXI_RID),
        .s_axi_rdata(M_AXI_RDATA),
        .s_axi_rresp(M_AXI_RRESP),
        .s_axi_rlast(M_AXI_RLAST),
        .s_axi_rvalid(M_AXI_RVALID),
        .s_axi_rready(M_AXI_RREADY)
    );

    // 100 MHz clock.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task start_dma;
        input [ADDR_WIDTH-1:0] src;
        input [ADDR_WIDTH-1:0] dst;
        input [31:0] bytes;
        begin
            @(posedge clk);
            src_addr       <= src;
            dst_addr       <= dst;
            transfer_bytes <= bytes;
            start          <= 1'b1;

            @(posedge clk);
            start          <= 1'b0;
        end
    endtask

    task wait_for_done;
        integer timeout;
        begin
            timeout = 0;

            while (!done && !error && timeout < 10000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 10000) begin
                $display("ERROR: DMA timeout.");
                $finish;
            end

            if (error) begin
                $display("ERROR: DMA reported error.");
                $finish;
            end

            $display("DMA completed successfully at time %0t ns.", $time);
        end
    endtask

    integer i;
    integer src_index;
    integer dst_index;

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        rst_n          = 1'b0;
        src_addr       = 32'd0;
        dst_addr       = 32'd0;
        transfer_bytes = 32'd0;
        start          = 1'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        // -------------------------------------------------
        // TEST 1: 256-byte transfer = 32 beats.
        // With MAX_BURST_LEN=16, this should use 2 bursts.
        // -------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 1: 256-byte DMA transfer");
        $display("==============================================");

        start_dma(32'h0000_1000, 32'h0000_2000, 32'd256);
        wait_for_done;

        // Verify 32 transferred 64-bit words.
        for (i = 0; i < 32; i = i + 1) begin
            src_index = (32'h0000_1000 >> 3) + i;
            dst_index = (32'h0000_2000 >> 3) + i;

            if (mem_model.mem[dst_index] !== mem_model.mem[src_index]) begin
                $display("ERROR TEST 1: word %0d mismatch. SRC=%h DST=%h",
                         i, mem_model.mem[src_index], mem_model.mem[dst_index]);
                $finish;
            end
        end

        $display("TEST 1 PASS: 256-byte transfer verified.");

        // -------------------------------------------------
        // TEST 2: 256-byte transfer beginning at 0x0FE0.
        // The source crosses the 4 KB boundary at 0x1000.
        // Expected burst split: 4 beats + 16 beats + 12 beats.
        // -------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 2: 4 KB boundary transfer");
        $display("==============================================");

        start_dma(32'h0000_0FE0, 32'h0000_1FE0, 32'd256);
        wait_for_done;

        for (i = 0; i < 32; i = i + 1) begin
            src_index = (32'h0000_0FE0 >> 3) + i;
            dst_index = (32'h0000_1FE0 >> 3) + i;

            if (mem_model.mem[dst_index] !== mem_model.mem[src_index]) begin
                $display("ERROR TEST 2: word %0d mismatch. SRC=%h DST=%h",
                         i, mem_model.mem[src_index], mem_model.mem[dst_index]);
                $finish;
            end
        end

        $display("TEST 2 PASS: 4 KB boundary transfer verified.");

        $display("");
        $display("==============================================");
        $display("ALL TESTS PASSED");
        $display("==============================================");

        #100;
        $finish;
    end

    // -----------------------------
    // Basic AXI protocol monitors
    // -----------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                if (M_AXI_ARBURST != 2'b01)
                    $display("WARNING: Read burst is not INCR.");

                if (M_AXI_ARLEN > 8'd255)
                    $display("ERROR: Invalid ARLEN.");
            end

            if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                if (M_AXI_AWBURST != 2'b01)
                    $display("WARNING: Write burst is not INCR.");

                if (M_AXI_AWLEN > 8'd255)
                    $display("ERROR: Invalid AWLEN.");
            end

            if (M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST) begin
                $display("Write burst completed at time %0t ns.", $time);
            end

            if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) begin
                $display("Read burst completed at time %0t ns.", $time);
            end
        end
    end

endmodule

