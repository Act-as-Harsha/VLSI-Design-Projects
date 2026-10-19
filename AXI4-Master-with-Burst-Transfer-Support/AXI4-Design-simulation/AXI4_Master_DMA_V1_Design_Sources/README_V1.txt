AXI4 Master with Burst Transfer Support - V1
================================================

Vivado Design Sources
---------------------
1. axi4_dma_top.sv
2. dma_controller.sv
3. axi4_read_engine.sv
4. axi4_write_engine.sv
5. axi4_burst_calc.sv
6. axis_fifo.sv
7. outstanding_tracker.sv

Default parameters
------------------
ADDR_WIDTH    = 32
DATA_WIDTH    = 64
ID_WIDTH      = 4
FIFO_DEPTH    = 512
MAX_BURST_LEN = 16

V1 features
------------
- AXI4 Full Master read/write channels
- INCR bursts
- Configurable maximum burst length
- 4 KB boundary-aware burst calculation
- Memory-to-memory DMA data path
- Read/write FIFO buffering
- AXI VALID/READY backpressure
- Basic AXI response error detection
- One outstanding read and one outstanding write transaction

Important
---------
This is the clean V1 RTL baseline. Add the simulation testbench and AXI memory
model before connecting to a real DDR/MIG interface. Multiple outstanding IDs,
WRAP/FIXED bursts, scatter-gather descriptors, and advanced arbitration should
be added only after V1 simulation is passing.
