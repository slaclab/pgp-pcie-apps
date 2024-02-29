# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxAlveoU200
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxAlveoU200/ddr
loadRuckusTcl $::env(PROJ_DIR)/../../../common/PrbsTester

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"
loadSource -sim_only -dir "$::DIR_PATH/tb"

# Update impl_1 strategy
set_property strategy Performance_ExploreWithRemap [get_runs impl_1]
#set_property strategy Performance_WLBlockPlacementFanoutOpt [get_runs impl_1]
#set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Top level sim
set_property top {XilinxAlveoU200PrbsTesterTb} [get_filesets sim_1]
