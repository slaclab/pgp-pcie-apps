# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common dynamic Source code
loadRuckusTcl $::env(MODULES)/surf
loadRuckusTcl $::env(MODULES)/axi-pcie-core/hardware/XilinxVcu1525/dynamic
loadRuckusTcl $::env(PROJ_DIR)/../../common/PrbsTester

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Set the top-level RTL
set_property top {Application} [current_fileset]
