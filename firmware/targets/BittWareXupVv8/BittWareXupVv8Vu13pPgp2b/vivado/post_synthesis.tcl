##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS Laserlocker Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
## User Debug Script

# Bypass the debug chipscope generation
# return

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaCore u_ila_core

##################
## Create the core
##################
CreateDebugCore ${ilaCore}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaCore}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaCore} {dmaClk}


#######################
## Set the debug Probes
#######################
ConfigProbe ${ilaCore} {dmaRst}


##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaCore}

