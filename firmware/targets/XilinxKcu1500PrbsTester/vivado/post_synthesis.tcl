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

# DMA ILA Core
set ilaName u_ila_dma

CreateDebugCore ${ilaName}

set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

SetDebugCoreClk ${ilaName} {U_Core/U_AxiPcieDma/axiClk}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/intAxisMaster[tLast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/intAxisMaster[tValid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/intAxisSlave[tReady]}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[axiLen][valid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[state][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/pause}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadSlave[rid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadSlave[rresp][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteMaster[awid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteSlave[bid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteSlave[bresp][*]}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadSlave[arready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadSlave[rlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiReadSlave[rvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteMaster[awvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteMaster[bready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteMaster[wlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteMaster[wvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteSlave[awready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteSlave[bvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/mAxiWriteSlave[wready]}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[0][awvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[0][wlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[0][wvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[0][awready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[0][bvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[0][wready]}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadMasters[1][arvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadMasters[1][rready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadSlaves[1][arready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadSlaves[1][rlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiReadSlaves[1][rvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[1][awvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[1][bready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[1][wlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteMasters[1][wvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[1][awready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_XBAR/sAxiWriteSlaves[1][wready]}

WriteDebugProbes ${ilaName}
