# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxVariumC1100

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Load the simulation testbed
loadSource -sim_only -dir "$::DIR_PATH/tb"
set_property top {XilinxVariumC1100DmaLoopbackTb} [get_filesets sim_1]
