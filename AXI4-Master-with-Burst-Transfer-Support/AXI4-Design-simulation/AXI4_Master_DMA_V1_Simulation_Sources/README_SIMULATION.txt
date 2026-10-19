Simulation Sources for AXI4 Master DMA V1

Add these files under Vivado -> Simulation Sources:
1. axi4_memory_model.sv
2. tb_axi4_dma_top.sv

Simulation top:
tb_axi4_dma_top

Tests:
- 256-byte transfer (32 beats)
- 4 KB boundary transfer beginning at 0x0FE0
- Data integrity checking
- Basic INCR burst checks
- DMA timeout/error detection

Note:
This is a behavioral AXI memory model for RTL simulation. It is not a DDR/MIG model.
