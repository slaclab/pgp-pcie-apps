#!/usr/bin/env python3
##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'PGP PCIe APP DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

import sys
import rogue
import rogue.hardware.axi
import pyrogue as pr
import pyrogue.gui
import pyrogue.utilities.prbs
import argparse
import common as feb

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--dev", 
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device",
)  

parser.add_argument(
    "--pollEn", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable auto-polling",
) 

parser.add_argument(
    "--initRead", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable read all variables at start",
)  

# Get the arguments
args = parser.parse_args()

#################################################################

# Set the DMA loopback channel
vcPrbs = rogue.hardware.axi.AxiStreamDma(args.dev,0,1)

# Set base
base = pr.Root(name='pciServer',description='DPM Loopback Testing')

prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx')
pyrogue.streamConnect(vcPrbs,prbsRx)
base.add(prbsRx)  
    
prbTx = pyrogue.utilities.prbs.PrbsTx(name="PrbsTx")
pyrogue.streamConnect(prbTx, vcPrbs)
base.add(prbTx)  

# Add PCIe debug registers
base.add(feb.Pcie()) 

#################################################################

# Start the system
base.start(
    pollEn   = args.pollEn,
    initRead = args.initRead,
    timeout  = 1.0,
)

# Create GUI
appTop = pr.gui.application(sys.argv)
guiTop = pr.gui.GuiTop(group='rootMesh')
appTop.setStyle('Fusion')
guiTop.addTree(base)
guiTop.resize(600, 800)

print("Starting GUI...\n");

# Run GUI
appTop.exec_()    
    
# Close
base.stop()
exit()   
