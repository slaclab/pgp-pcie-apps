##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS Laserlocker Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

# # Bypass the debug chipscope generation
# return

# Get variables and procedures
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Open the synthesis design
open_run synth_1

# ILA Core
set ilaName u_ila_bar0

CreateDebugCore ${ilaName}

set_property C_DATA_DEPTH 4096 [get_debug_cores ${ilaName}]

SetDebugCoreClk ${ilaName} {U_Hardware/U_QSFP0/htspClk}

ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxOut[linkReady]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxMasters[0][tKeep][*]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxMasters[0][tUser][1]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspReset}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxCtrl[0][idle]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxCtrl[0][overflow]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxCtrl[0][pause]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxMasters[0][tLast]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspRxMasters[0][tValid]}

ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxOut[linkReady]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxMasters[0][tKeep][*]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxMasters[0][tUser][1]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxMasters[0][tLast]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxMasters[0][tValid]}
ConfigProbe ${ilaName} {U_Hardware/U_QSFP0/htspTxSlaves[0][tReady]}

WriteDebugProbes ${ilaName}
