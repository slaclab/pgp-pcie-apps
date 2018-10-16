##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS Laserlocker Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# Bypass the debug chipscope generation
return

# Get variables and procedures
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Open the synthesis design
open_run synth_1

# DMA ILA Core
set ilaName u_ila_dma

CreateDebugCore ${ilaName}

set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

SetDebugCoreClk ${ilaName} {U_Core/U_AxiPcieDma/axiClk}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/resizeWriteMasters[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/resizeWriteSlaves[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/resizeReadMasters[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/resizeReadSlaves[1][*}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadMasters[1][*}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadSlaves[1][*}

WriteDebugProbes ${ilaName}
