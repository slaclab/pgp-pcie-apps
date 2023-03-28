# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/BittWareXupVv8
loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp2b/hardware/BittWareXupVv8

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/../BittWareXupVv8Vu13pPgp2b/hdl"
loadConstraints -dir "$::DIR_PATH/xdc"

set_property top {BittWareXupVv8Pgp2b} [get_filesets {sources_1}]
set_property top {PgpLaneTb} [get_filesets {sim_1}]

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
