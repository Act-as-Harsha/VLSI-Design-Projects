AXI4 DMA Design and Simulation
<p align="center">
  <strong>AXI4 Master DMA | SystemVerilog RTL | Simulation and Verification</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HDL-SystemVerilog-blue?style=for-the-badge" alt="SystemVerilog">
  <img src="https://img.shields.io/badge/Protocol-AXI4-6A5ACD?style=for-the-badge" alt="AXI4">
  <img src="https://img.shields.io/badge/Tool-Xilinx%20Vivado-orange?style=for-the-badge" alt="Xilinx Vivado">
  <img src="https://img.shields.io/badge/Focus-DMA%20Design-2E8B57?style=for-the-badge" alt="DMA Design">
</p>

<p align="center">
  <a href="https://github.com/Act-as-Harsha/VLSI-Design-Projects">Main Repository</a> ·
  <a href="https://github.com/Act-as-Harsha">GitHub Profile</a>
</p>

Overview
This directory contains the design and simulation sources for an AXI4-based Direct Memory Access (DMA) project. The visible source files are organized around DMA control, AXI4 read and write engines, burst calculation, buffering, memory-model support, transaction tracking, and a top-level testbench.

The project is intended to support learning and development in SystemVerilog RTL design, AXI4 transaction control, burst transfers, and simulation-based verification using Xilinx Vivado.
Verification note: The file listing identifies the available source files, but does not by itself establish which test scenarios pass, which burst modes are supported, or whether FPGA implementation has completed. Confirm these details from the RTL, testbench output, waveforms, and Vivado reports.

Key Design Areas
- DMA control: Coordinates data-movement operations.
- AXI4 read path: Handles read-address requests and read-data reception.
- AXI4 write path: Handles write-address requests, write-data transfers, and write responses.
- Burst calculation: Provides burst-related calculation logic.
- Buffering: FIFO-based storage for data or transaction flow.
- Transaction tracking: Tracks outstanding transactions where implemented.
- Memory-model support: Provides a RAM/slave model for simulation.
- Verification: Uses a testbench to exercise the integrated design.
The exact interfaces, arbitration strategy, outstanding-transaction limits, and supported burst types should be confirmed by inspecting the source code.
Repository Contents
The following descriptions are based on the filenames visible in this directory.
File or folder	Purpose / expected role
AXI4_Master_DMA_V1_Design_Sources/	Separate design-source collection. Inspect the folder for its RTL hierarchy and project files.
AXI4_Master_DMA_V1_Simulation_Sources/	Separate simulation-source collection. Inspect the folder for testbench and simulation setup files.
axi4_burst_calc.sv	Burst-related calculation logic.
axi4_burst_calc.sv.backup	Backup copy of the burst calculator source; not necessarily part of the active build.
axi4_dma.xdc	Xilinx Design Constraints file, typically used for pin assignments, clock constraints, and other implementation constraints.
axi4_dma_fpga_top.sv	FPGA-oriented top-level wrapper, as suggested by its filename.
axi4_dma_top.sv	Top-level DMA design module, as suggested by its filename.
axi4_memory_model.sv	Memory model intended to support simulation.
axi4_ram_slave.sv	RAM/AXI slave model or interface logic, as suggested by its filename.
axi4_read_engine.sv	Read transaction engine.
axi4_write_engine.sv	Write transaction engine.
axis_fifo.sv	FIFO for AXI-Stream-style data or buffering. Confirm how it is connected in this design.
dma_controller.sv	DMA control logic.
outstanding_tracker.sv	Logic associated with tracking outstanding transactions.
tb_axi4_dma_top.sv	Testbench for the DMA top-level module.
README.md	Documentation for this directory.


AXI4 Concepts Used
Five AXI4 Channels
Channel	Direction from master	Function
AW — Write Address	Master → Slave	Sends write address and transaction attributes.
W — Write Data	Master → Slave	Sends write data; WLAST marks the final beat.
B — Write Response	Slave → Master	Returns the write response.
AR — Read Address	Master → Slave	Sends read address and transaction attributes.
R — Read Data	Slave → Master	Returns read data; RLAST marks the final beat.


VALID–READY Handshake
A channel transfer occurs at a rising clock edge when both VALID and READY are high:
transfer = VALID && READY;
Each channel handshakes independently. A receiver may apply backpressure by deasserting READY; the sender must follow AXI protocol requirements while waiting for the transfer to be accepted.
Burst Length
AXI4 AxLEN signals encode the number of data beats minus one.
\[
\text{Number of beats} = \text{AxLEN} + 1
\]
For example, ARLEN = 7 describes an eight-beat read burst. The actual burst lengths and burst types supported by this implementation must be confirmed in the RTL.
Simulation Workflow in Xilinx Vivado
1. Clone or download the repository.
2. Open the relevant Vivado project if one is provided, or create a project and add the required design sources.
3. Add the simulation sources and set tb_axi4_dma_top.sv as the simulation top if it is the intended testbench.
4. Confirm that all instantiated modules are included and that the source language settings are correct.
5. Compile and elaborate the design.
6. Run behavioral simulation.
7. Inspect waveforms and simulation logs.
8. Review the checks below and record the results actually observed.
Signals and Behaviors to Inspect
- Reset assertion and release.
- Read-address and write-address VALID–READY handshakes.
- Read-data and write-data transfers.
- Write response handling.
- Burst beat counts and final-beat signals (RLAST and WLAST).
- FIFO behavior, including full/empty handling where applicable.
- Outstanding-transaction tracking, if enabled.
- Backpressure and delayed responses.
- Completion or status signaling from the DMA controller, if implemented.
Signal names and availability depend on the actual RTL.
Verification Checklist
Update this checklist only after checking the simulation output or implementation reports.
- [ ] All required RTL files compile successfully.
- [ ] Testbench elaborates and starts successfully.
- [ ] Reset behavior is verified.
- [ ] Read-address handshake is verified.
- [ ] Read-data transfer and final-beat behavior are verified.
- [ ] Write-address handshake is verified.
- [ ] Write-data transfer and final-beat behavior are verified.
- [ ] Write responses are handled correctly.
- [ ] Burst length and beat count are checked.
- [ ] Backpressure scenarios are tested.
- [ ] FIFO boundary conditions are tested, where applicable.
- [ ] Outstanding transactions are tested, where applicable.
- [ ] Read/write data integrity is checked.
- [ ] Synthesis completes successfully.
- [ ] FPGA implementation and timing checks complete, if applicable.
FPGA Implementation Notes
The visible axi4_dma.xdc and axi4_dma_fpga_top.sv filenames suggest that FPGA implementation resources are included.

Before programming an FPGA:
- Confirm the target FPGA device and board.
- Check that the XDC pin assignments match the actual board.
- Define the correct clock and timing constraints.
- Run synthesis and implementation.
- Review timing, utilization, and design-rule reports.
- Confirm that all required external interfaces are connected correctly.
Do not report timing closure, resource utilization, or successful hardware testing unless supported by the relevant Vivado reports or board-test results.
Troubleshooting
Issue	Checks to perform
Missing module during elaboration	Confirm that every instantiated .sv file is added to the project.
Simulation does not finish	Inspect the testbench clock, reset, wait conditions, and completion logic.
No AXI transfer occurs	Check the relevant VALID and READY signals and reset state.
Burst count mismatch	Inspect AxLEN, beat counters, and final-beat signaling.
Read/write data mismatch	Check address progression, data generation, byte enables, and memory-model behavior.
FPGA timing or constraint errors	Review the target device, clock definitions, pin assignments, and XDC warnings.


Further Improvements
- Document the exact data/address widths and supported burst configurations.
- Add expected results and pass/fail checks to the testbench documentation.
- Include waveform captures for representative read and write bursts.
- Add assertions for protocol handshakes and burst completion.
- Publish synthesis utilization and timing summaries from actual Vivado reports.
- Document the board setup and hardware-validation procedure, if applicable.
Author
Harsha Abhi
Electronics and Communication Engineering
- GitHub: https://github.com/Act-as-Harsha
- Main repository: https://github.com/Act-as-Harsha/VLSI-Design-Projects
<p align="center">
  <strong>AXI4 Protocol · SystemVerilog RTL · DMA Architecture · Functional Verification</strong>
</p>
