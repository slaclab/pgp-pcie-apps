# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and Constraints
loadSource -dir "$::DIR_PATH/rtl"

# Get the family type
set family [getFpgaFamily]

# if { ${family} eq {artix7} } {
   # loadSource -dir "$::DIR_PATH/rtl/gtp7"
# }

if { ${family} eq {kintex7} } {
   loadSource -dir "$::DIR_PATH/rtl/gtx7"
}

if { ${family} eq {zynq} } {
   if { [ regexp "XC7Z(015|012).*" [string toupper "$::env(PRJ_PART)"] ] } {
      loadSource -dir "$::DIR_PATH/rtl/gtp7"
   } else {
      loadSource -dir "$::DIR_PATH/rtl/gtx7"
   }
}

if { ${family} eq {virtex7} } {
   loadSource -dir "$::DIR_PATH/rtl/gth7"
}

if { ${family} eq {kintexu} } {
   loadSource -dir "$::DIR_PATH/rtl/gthUs"
}

if { ${family} eq {kintexuplus} ||
     ${family} eq {zynquplus} ||
     ${family} eq {zynquplusRFSOC} ||
     ${family} eq {qzynquplusRFSOC} } {
   loadSource -dir "$::DIR_PATH/rtl/gthUs+"
   loadSource -dir "$::DIR_PATH/rtl/gtyUs+"
}

if { ${family} eq {virtexuplus} ||
     ${family} eq {virtexuplusHBM} } {
   loadSource -dir "$::DIR_PATH/rtl/gtyUs+"
}
