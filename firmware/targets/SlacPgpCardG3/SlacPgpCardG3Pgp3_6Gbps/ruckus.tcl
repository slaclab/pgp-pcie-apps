# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/SlacPgpCardG3
loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp3/hardware/SlacPgpCardG3

# Load local source Code and constraints
loadSource -dir "$::DIR_PATH/hdl"
