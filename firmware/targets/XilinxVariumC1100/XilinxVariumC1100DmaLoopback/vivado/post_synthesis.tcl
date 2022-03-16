##############################################################################
## This file is part of 'Simple-10GbE-RUDP-KCU105-Example'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'Simple-10GbE-RUDP-KCU105-Example', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

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
set_property C_DATA_DEPTH 8192 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilReadMaster[araddr][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilWriteMaster[awaddr][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilWriteMaster[wdata][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[addr][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilReadSlave][rdata][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilReadSlave][rresp][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilWriteSlave][bresp][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[data][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[page][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][i2cAddr][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regAddr][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regAddrSize][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regDataSize][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regWrData][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[state][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[timer][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/regOut[regFailCode][*]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/regOut[regRdData][*]}

ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilRst}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilWriteMaster[awvalid]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilWriteMaster[bready]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/axilWriteMaster[wvalid]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilReadSlave][arready]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilReadSlave][rvalid]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilWriteSlave][awready]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilWriteSlave][bvalid]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axilWriteSlave][wready]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[axiRd]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[booting]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][busReq]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][endianness]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regAddrSkip]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regOp]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][regReq]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][repeatStart]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/r[regIn][tenbit]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/regOut[regAck]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/regOut[regFail]}
ConfigProbe ${ilaName} {U_Core/REAL_PCIE.U_SI5394/U_Core/rstL}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}
