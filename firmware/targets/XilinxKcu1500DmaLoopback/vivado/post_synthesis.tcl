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

set_property C_DATA_DEPTH 8192 [get_debug_cores ${ilaName}]

SetDebugCoreClk ${ilaName} {U_Core/U_AxiPcieDma/axiClk}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadMaster[araddr][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadMaster[arcache][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadMaster[arlen][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadSlave[rdata][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadSlave[rresp][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tData][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tDest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tKeep][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[address][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[buffId][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[dest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[firstUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[lastUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[size][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescRet[buffId][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescRet[result][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadSlave[arready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadSlave[rlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axiReadSlave[rvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisCtrl[pause]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tLast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/axisMaster[tValid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescReq[valid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescRet[valid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/dmaRdDescRetAck}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaRead/sSlave[tReady]}

WriteDebugProbes ${ilaName}
