# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for version between 2025.1 and 2026.2
if { [VersionRangeCheck 2025.1 2026.2] < 0 } {exit -1}

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxVariumC1100
loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp4/hardware/XilinxVariumC1100

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Update impl_1 strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Set top level simulation
set_property top {Pgp4FecTb} [get_filesets sim_1]
