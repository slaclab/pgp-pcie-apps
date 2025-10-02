##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source $::env(RUCKUS_PROC_TCL)

######################################################
# Bypass the debug chipscope generation via return cmd
# ELSE ... comment out the return to include chipscope
######################################################
return

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxRst}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxSlip}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxValid}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxActive}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxData[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/phyRxHeader[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/unscrambledData[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/unscrambledHeader[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/unscrambledValid}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/unscramblerValid}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp3RxGearboxAligner_1/locked}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_1

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxMaster[tData][*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxMaster[tUser][*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/protRxData[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/protRxHeader[*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/r_reg[count][*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/r_reg[notValidCnt][*]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/eof}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/linkError}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxIn[resetRx]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxMaster[tLast]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxMaster[tValid]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxOut[linkReady]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxOut[opCodeEn]}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/pgpRxRst}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/phyRxActive}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/phyRxActiveSync}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/phyRxActiveSyncFall}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/protRxPhyInit}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/protRxValid}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/remRxLinkReady}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/U_Pgp4RxProtocol_1/sof}
ConfigProbe ${ilaName} {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp4Core_1/GEN_RX.U_Pgp4Rx_1/ebValid}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}
