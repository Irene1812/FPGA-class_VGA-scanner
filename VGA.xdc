
# ==========================================
# Clock (100 MHz)
# ==========================================
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS25 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# ==========================================
# Reset (High = Reset)
# ==========================================
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS25} [get_ports rst]

# ==========================================
# VGA Sync
# ==========================================
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS25} [get_ports hsync]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS25} [get_ports vsync]

# ==========================================
# Red
# ==========================================
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS25} [get_ports {red[3]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS25} [get_ports {red[2]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS25} [get_ports {red[1]}]
set_property -dict {PACKAGE_PIN AB4 IOSTANDARD LVCMOS25} [get_ports {red[0]}]

# ==========================================
# Green
# ==========================================
set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS25} [get_ports {green[3]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS25} [get_ports {green[2]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS25} [get_ports {green[1]}]
set_property -dict {PACKAGE_PIN AA7 IOSTANDARD LVCMOS25} [get_ports {green[0]}]

# ==========================================
# Blue
# ==========================================
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS25} [get_ports {blue[3]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS25} [get_ports {blue[2]}]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS25} [get_ports {blue[1]}]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD LVCMOS25} [get_ports {blue[0]}]
