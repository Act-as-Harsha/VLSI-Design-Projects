<div align="center">

# AXI4 DMA — FPGA Design & Timing Analysis

**SystemVerilog RTL · Xilinx Vivado · Timing Analysis · DRC · Resource Utilization**

[![AXI4](https://img.shields.io/badge/Protocol-AXI4-2563EB?style=flat-square)](https://github.com/Act-as-Harsha/VLSI-Design-Projects)
[![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-0F766E?style=flat-square)](https://github.com/Act-as-Harsha/VLSI-Design-Projects)
[![Vivado](https://img.shields.io/badge/Tool-Xilinx%20Vivado-EA580C?style=flat-square)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Reports](https://img.shields.io/badge/Reports-Timing%20%7C%20DRC%20%7C%20Utilization-6D28D9?style=flat-square)](https://github.com/Act-as-Harsha/VLSI-Design-Projects)

[**Project Repository**](https://github.com/Act-as-Harsha/VLSI-Design-Projects) · [**GitHub Profile**](https://github.com/Act-as-Harsha)

</div>

---

## Overview

This directory contains the **Xilinx Vivado project and its implementation reports** for the AXI4 DMA design. The project files and generated artifacts support review of the RTL-to-FPGA workflow, including timing analysis, design rule checks (DRC), routing status, and FPGA resource utilization.

The reports are intended to help inspect implementation quality and identify potential issues. **A report's presence does not prove that the design passed**; use the actual report values and Vivado run status to confirm results.

## Project at a Glance

| Component | Included content |
|---|---|
| Vivado project | `CC-Project-VLSI.xpr` |
| Source files | `CC-Project-VLSI.srcs/` |
| Generated IP products | `CC-Project-VLSI.gen/`, `CC-Project-VLSI.ip_user_files/` |
| Run outputs | `CC-Project-VLSI.runs/` |
| Simulation artifacts | `CC-Project-VLSI.sim/` |
| Timing reports | Setup, hold, worst-path, critical-path, and timing-summary reports |
| Implementation reports | DRC, route status, I/O, clock, and utilization reports |
| Diagnostics | Vivado logs, journal, and diagnostic files |

## Implementation Reports

### Timing Analysis

| Report file | What it contains |
|---|---|
| `final_timing_summary.rpt` | Timing summary from the run that generated this report |
| `timing_summary.rpt` | Timing summary associated with its run |
| `final_critical_paths.rpt` | Details of reported critical timing paths |
| `worst_setup_paths.rpt` | Worst setup paths reported by the tool |
| `setup_paths.rpt` | Setup paths and their slack values |
| `hold_paths.rpt` | Hold paths and hold-slack values |

**Timing metrics to review**

- **WNS — Worst Negative Slack:** The worst setup slack. A negative value indicates a setup timing violation.
- **TNS — Total Negative Slack:** The total negative setup slack across violating endpoints.
- **WHS — Worst Hold Slack:** The worst hold timing margin.
- **THS — Total Hold Slack:** The total hold slack across endpoints.

Review these values alongside the clock definitions, timing constraints, and unconstrained paths. Timing conclusions are meaningful only for the intended FPGA target and constraints.

### DRC, Routing, and Resource Utilization

| Report file | What it helps verify |
|---|---|
| `final_drc.rpt` | DRC messages from the corresponding final report stage |
| `drc_report.rpt` | DRC messages from its associated run |
| `final_route_status.rpt` | Reported routing status and route-related issues |
| `final_utilization.rpt` | FPGA resource usage, such as LUTs, registers, BRAM, and DSPs when applicable |
| `clock_utilization.rpt` | Clock-related resource usage |
| `io_report.rpt` | I/O and port-related information, depending on report settings |

Review DRC findings by severity. Check whether any issue affects implementation, timing, I/O connectivity, or board compatibility. Record utilization values directly from the report rather than estimating them.

## Repository Structure

The following tree summarizes the files visible in the repository. Vivado-generated folders may contain additional files.

```text
CC-Project-VLSI/
├── CC-Project-VLSI.xpr
├── CC-Project-VLSI.srcs/
├── CC-Project-VLSI.gen/
│   └── sources_1/
│       └── ip/
│           └── clk_wiz_0/
├── CC-Project-VLSI.ip_user_files/
├── CC-Project-VLSI.cache/
├── CC-Project-VLSI.runs/
├── CC-Project-VLSI.sim/
│   └── sim_1/
│       └── behav/
│           └── xsim/
├── CC-Project-VLSI.hw/
├── final_timing_summary.rpt
├── final_critical_paths.rpt
├── final_utilization.rpt
├── final_drc.rpt
├── final_route_status.rpt
├── timing_summary.rpt
├── setup_paths.rpt
├── worst_setup_paths.rpt
├── hold_paths.rpt
├── clock_utilization.rpt
├── io_report.rpt
├── drc_report.rpt
├── vivado.log
├── vivado.jou
└── README.md
```

## Open and Review the Project

1. Open `CC-Project-VLSI.xpr` in a compatible version of Xilinx Vivado.
2. Resolve any missing source files or IP output products reported by Vivado.
3. Confirm the target FPGA part, clock definitions, and timing constraints.
4. Review the synthesis and implementation runs in `CC-Project-VLSI.runs/`.
5. Open the final timing, DRC, route-status, and utilization reports.
6. If you rerun implementation, regenerate the reports and record the Vivado version, target device, and run used.

### Recommended review order

1. `final_route_status.rpt`
2. `final_timing_summary.rpt`
3. `final_drc.rpt`
4. `final_utilization.rpt`
5. `final_critical_paths.rpt`
6. `io_report.rpt` and `clock_utilization.rpt`

Ensure that the reports being compared belong to the same intended implementation run.

## Implementation Checklist

Update this checklist only after verifying the actual Vivado status or report contents.

- [ ] Project opens and required sources/IP are available.
- [ ] RTL elaboration and behavioral simulation complete.
- [ ] Synthesis completes.
- [ ] Placement and routing complete.
- [ ] Setup timing is checked against the intended constraints.
- [ ] Hold timing is checked against the intended constraints.
- [ ] DRC findings are resolved or documented.
- [ ] Resource utilization is reviewed.
- [ ] I/O assignments and clock constraints are verified.
- [ ] Final reports correspond to the intended implementation run.

## Logs and Diagnostics

| File | Purpose |
|---|---|
| `vivado.log` | Vivado messages, warnings, and errors |
| `vivado.jou` | Recorded Vivado commands and actions |
| `dfx_runtime.txt` | Runtime-related information; exact meaning depends on the workflow |
| `vivado_pid26360.str` | Tool-generated diagnostic or stream output |
| `hs_err_pid26360.log` | Java runtime crash details, if a fatal error occurred |
| `hs_err_pid26360.dmp` | Crash dump that may help diagnose a tool failure |

Crash files are generally useful for troubleshooting a Vivado or Java crash. Before publishing logs, check for local paths, usernames, machine-specific details, or other environment information.

## Repository Maintenance

Vivado can generate caches, run products, simulator outputs, and other reproducible artifacts. For a maintainable repository:

- Keep the project file, required RTL, constraints, IP configuration, and simulation sources.
- Retain selected final reports when they provide useful implementation evidence.
- Consider excluding temporary outputs, redundant caches, and large crash dumps when they are not needed.
- Use a `.gitignore` appropriate for the project.
- Confirm that the project can be reopened and regenerated before removing generated files.

Do not delete generated files blindly; some projects depend on checked-in IP or generated products.

## Author

**Harsha Abhi**  
Electronics and Communication Engineering

- GitHub: [@Act-as-Harsha](https://github.com/Act-as-Harsha)
- Repository: [VLSI-Design-Projects](https://github.com/Act-as-Harsha/VLSI-Design-Projects)

---

<div align="center">

**AXI4 · RTL Design · FPGA Implementation · Static Timing Analysis**

</div>
