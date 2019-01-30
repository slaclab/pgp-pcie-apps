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
import argparse

import rogue.hardware.axi
import rogue.interfaces.stream

import pyrogue as pr
import pyrogue.gui

import axipcie as pcie
import surf.protocols.pgp as pgp

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
    "--numLane", 
    type     = int,
    required = False,
    default  = 1,
    help     = "# of DMA Lanes",
) 

parser.add_argument(
    "--numVc", 
    type     = int,
    required = False,
    default  = 4,
    help     = "# of VC (virtual channels)",
) 

parser.add_argument(
    "--version3", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "true = PGPv3, false = PGP2b",
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

class MyRoot(pr.Root):
    def __init__(   self,       
            name        = "MyRoot",
            description = "my root container",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)   

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset  = 0x00000000, 
            memBase = self.memMap,
            expand  = False, 
        ))

        # Add PGP Core 
        for i in range(1):
            if (args.version3):
                self.add(pgp.Pgp3AxiL(            
                    name    = ('Lane[%i]' % i), 
                    offset  = (0x00800000 + i*0x00010000), 
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    # expand  = False,
                )) 
            else:
                self.add(pgp.Pgp2bAxi(            
                    name    = ('Lane[%i]' % i), 
                    offset  = (0x00800000 + i*0x00010000), 
                    memBase = self.memMap,
                    expand  = False,
                )) 
                
        
#################################################################

# Set base
base = MyRoot(name='pciServer',description='DMA Loopback Testing')

# Start the system
base.start(
    pollEn   = args.pollEn,
    initRead = args.initRead,
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
