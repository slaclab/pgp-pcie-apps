# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/BittWareXupVv8
loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp2b/hardware/BittWareXupVv8
loadRuckusTcl $::env(PROJ_DIR)/../../../common/dma/shared/

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/../BittWareXupVv8Vu13pPgp2b/hdl"
loadConstraints -dir "$::DIR_PATH/xdc"
loadSource -sim_only -dir "$::DIR_PATH/../BittWareXupVv8Vu13pPgp2b/sim"

set_property top {BittWareXupVv8Pgp2b} [get_filesets {sources_1}]
set_property top {BittWareXupVv8Pgp2bTb} [get_filesets {sim_1}]

set_property target_language VHDL [current_project]

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
