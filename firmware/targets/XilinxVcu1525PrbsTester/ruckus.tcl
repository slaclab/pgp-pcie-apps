# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common dynamic Source code
loadRuckusTcl $::env(MODULES)/surf
loadRuckusTcl $::env(MODULES)/axi-pcie-core/hardware/XilinxVcu1525/dynamic

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"
