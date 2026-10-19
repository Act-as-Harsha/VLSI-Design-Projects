`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/18/2026 09:56:42 PM
// Design Name: 
// Module Name: axi4_memory_model
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


module axi4_memory_model #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter integer MEM_WORDS  = 16384
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // AXI Write Address
    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awvalid,
    output reg                     s_axi_awready,

    // AXI Write Data
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    // AXI Write Response
    output reg [ID_WIDTH-1:0]      s_axi_bid,
    output reg [1:0]               s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // AXI Read Address
    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arvalid,
    output reg                     s_axi_arready,

    // AXI Read Data
    output reg [ID_WIDTH-1:0]      s_axi_rid,
    output reg [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg [1:0]               s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready
);

    localparam integer BYTE_COUNT = DATA_WIDTH / 8;
    localparam integer BYTE_LG2   = $clog2(BYTE_COUNT);

    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    reg                  wr_active;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [8:0]            wr_beats_left;
    reg [ID_WIDTH-1:0]   wr_id;

    reg                  rd_active;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [8:0]            rd_beats_left;
    reg [ID_WIDTH-1:0]   rd_id;

    integer i;
    integer mem_index;
    integer byte_index;

    // This model accepts one address transaction at a time.
    // Backpressure is intentionally simple for the first simulation.
    always @* begin
        s_axi_awready = !wr_active && !s_axi_bvalid;
        s_axi_wready  = wr_active;
        s_axi_arready = !rd_active && !s_axi_rvalid;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_active     <= 1'b0;
            wr_addr       <= {ADDR_WIDTH{1'b0}};
            wr_beats_left <= 9'd0;
            wr_id         <= {ID_WIDTH{1'b0}};

            rd_active     <= 1'b0;
            rd_addr       <= {ADDR_WIDTH{1'b0}};
            rd_beats_left <= 9'd0;
            rd_id         <= {ID_WIDTH{1'b0}};

            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00;
            s_axi_bvalid  <= 1'b0;

            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            s_axi_rvalid  <= 1'b0;
        end else begin

            // -----------------------------
            // WRITE ADDRESS CHANNEL
            // -----------------------------
            if (s_axi_awvalid && s_axi_awready) begin
                wr_active     <= 1'b1;
                wr_addr       <= s_axi_awaddr;
                wr_beats_left <= s_axi_awlen + 1'b1;
                wr_id         <= s_axi_awid;
            end

            // -----------------------------
            // WRITE DATA CHANNEL
            // -----------------------------
            if (s_axi_wvalid && s_axi_wready) begin
                mem_index = s_axi_awaddr >> BYTE_LG2;

                // Use current write address, not the original AW address.
                mem_index = wr_addr >> BYTE_LG2;

                if ((mem_index >= 0) && (mem_index < MEM_WORDS)) begin
                    for (byte_index = 0; byte_index < BYTE_COUNT; byte_index = byte_index + 1) begin
                        if (s_axi_wstrb[byte_index])
                            mem[mem_index][8*byte_index +: 8] <=
                                s_axi_wdata[8*byte_index +: 8];
                    end
                end

                wr_addr <= wr_addr + BYTE_COUNT;

                if (wr_beats_left == 1) begin
                    wr_beats_left <= 9'd0;
                    wr_active     <= 1'b0;

                    s_axi_bid    <= wr_id;
                    s_axi_bresp  <= 2'b00; // OKAY
                    s_axi_bvalid <= 1'b1;
                end else begin
                    wr_beats_left <= wr_beats_left - 1'b1;
                end
            end

            // -----------------------------
            // WRITE RESPONSE
            // -----------------------------
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // -----------------------------
            // READ ADDRESS CHANNEL
            // -----------------------------
            if (s_axi_arvalid && s_axi_arready) begin
                rd_active     <= 1'b1;
                rd_addr       <= s_axi_araddr;
                rd_beats_left <= s_axi_arlen + 1'b1;
                rd_id         <= s_axi_arid;
            end

            // -----------------------------
            // READ DATA CHANNEL
            // -----------------------------
            if (rd_active && !s_axi_rvalid) begin
                mem_index = rd_addr >> BYTE_LG2;

                s_axi_rid    <= rd_id;
                s_axi_rresp  <= 2'b00; // OKAY
                s_axi_rlast  <= (rd_beats_left == 1);

                if ((mem_index >= 0) && (mem_index < MEM_WORDS))
                    s_axi_rdata <= mem[mem_index];
                else
                    s_axi_rdata <= {DATA_WIDTH{1'b0}};

                s_axi_rvalid <= 1'b1;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;

                if (rd_beats_left == 1) begin
                    rd_beats_left <= 9'd0;
                    rd_active     <= 1'b0;
                    s_axi_rlast   <= 1'b0;
                end else begin
                    rd_beats_left <= rd_beats_left - 1'b1;
                    rd_addr       <= rd_addr + BYTE_COUNT;
                end
            end
        end
    end

    // Initialize memory with a deterministic pattern.
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 64'h1000_0000_0000_0000 + i;
    end

endmodule

