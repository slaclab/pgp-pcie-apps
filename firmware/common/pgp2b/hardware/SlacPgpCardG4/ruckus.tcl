# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and Constraints
loadSource -dir "$::DIR_PATH/rtl"

# Load shared source code
loadSource -dir "$::DIR_PATH/../../shared/rtl"
