
# ============================================================
# PYNQ-Z2 AXI4 DMA Demo - Pin Constraints
# FPGA: xc7z020clg400-1
# External clock: 125 MHz
# ============================================================

# 125 MHz PL clock input - H16
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {clk}]
create_clock -name CLK125 -period 8.000 -waveform {0.000 4.000} [get_ports {clk}]

# Push buttons
# BTN0: Reset - D19
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btn_reset}]

# BTN1: Start DMA - D20
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {btn_start}]

# Status LEDs
# LED0: DMA busy - R14
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]

# LED1: DMA done - P14
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

# LED2: DMA error - N16
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]

# LED3: DMA idle/ready - M14
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
# Targeted CDC exceptions: first synchronizer stage only
set_false_path -to [get_pins -hier -filter {NAME =~ */start_meta_100_reg/D}]
set_false_path -to [get_pins -hier -filter {NAME =~ */done_meta_reg/D}]
set_false_path -to [get_pins -hier -filter {NAME =~ */busy_meta_reg/D}]
set_false_path -to [get_pins -hier -filter {NAME =~ */error_meta_reg/D}]
