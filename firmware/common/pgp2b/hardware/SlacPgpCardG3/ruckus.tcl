# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource      -dir  "$::DIR_PATH/rtl"
loadConstraints -dir  "$::DIR_PATH/xdc"
loadIpCore      -path "$::DIR_PATH/ip/Pgp2bGtp7Drp.xci"

# Load shared source code
loadSource -dir "$::DIR_PATH/../../shared/rtl"
