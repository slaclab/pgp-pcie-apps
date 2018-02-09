# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource      -dir  "$::DIR_PATH/rtl"
loadConstraints -dir  "$::DIR_PATH/rtl"
loadIpCore      -path "$::DIR_PATH/rtl/Pgp2bGtp7Drp.xci"
