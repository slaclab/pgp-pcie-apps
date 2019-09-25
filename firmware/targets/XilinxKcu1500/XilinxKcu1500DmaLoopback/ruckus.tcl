# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxKcu1500

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"
loadSource -sim_only -dir "$::DIR_PATH/tb"

set_property top {XilinxKcu1500DmaLoopbackTb} [get_filesets sim_1]
#set_property top {AxiPcieDmaIbFifoEofeTb} [get_filesets sim_1]
#set_property top {SsiResizeFifoEofeTb} [get_filesets sim_1]
