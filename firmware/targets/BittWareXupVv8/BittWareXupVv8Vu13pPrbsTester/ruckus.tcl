# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/BittWareXupVv8
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/BittWareXupVv8/ddr
loadRuckusTcl $::env(PROJ_DIR)/../../../common/PrbsTester

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

loadSource -sim_only -dir "$::DIR_PATH/tb"

set_property top {BittWareXupVv8PrbsTester} [get_filesets {sources_1}]
set_property top {BittWareXupVv8PrbsTesterTb} [get_filesets {sim_1}]

# Update impl_1 strategy
#set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
set_property strategy Performance_ExploreWithRemap [get_runs impl_1]
