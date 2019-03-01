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
import rogue.interfaces.stream
import rogue.interfaces.memory
import pyrogue as pr
import pyrogue.gui
import pyrogue.utilities.prbs
import pyrogue.interfaces.simulation
import argparse
import axipcie as pcie
import surf.protocols.ssi as ssi

# rogue.Logging.setLevel(rogue.Logging.Warning)
# rogue.Logging.setLevel(rogue.Logging.Debug)

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--type", 
    type     = str,
    required = False,
    default  = 'pcie',
    help     = "define the type of interface",
) 

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
    default  = 1,
    help     = "# of VC (virtual channels)",
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
        
        #################################################################
        
        self.dmaStream = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbsRx    = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbTx     = [[None for x in range(args.numVc)] for y in range(args.numLane)]        
        
        # DataDev PCIe Card
        if ( args.type == 'pcie' ):

            # Create PCIE memory mapped interface
            self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)   
            
            # Create the DMA loopback channel
            for lane in range(args.numLane):
                for vc in range(args.numVc):
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)            
            
        # VCS simulation
        elif ( args.type == 'sim' ):            
        
            self.memMap = rogue.interfaces.memory.TcpClient('localhost',8000)
            
            # Create the DMA loopback channel
            for lane in range(args.numLane):
                for vc in range(args.numVc):
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*vc)           
            
        # Undefined device type
        else:
            raise ValueError("Invalid type (%s)" % (args.type) )
            
        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            memBase = self.memMap ,
            offset  = 0x00000000, 
            expand  = False, 
        ))            
        
        for lane in range(args.numLane):
            for vc in range(args.numVc):
                # Connect the SW PRBS Receiver module
                self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(name=('SwPrbsRx[%d][%d]'%(lane,vc)),expand=False)
                pyrogue.streamConnect(self.dmaStream[lane][vc],self.prbsRx[lane][vc])
                self.add(self.prbsRx[lane][vc])  
                # Connect the SW PRBS Transmitter module
                self.prbTx[lane][vc] = pr.utilities.prbs.PrbsTx(name=('SwPrbsTx[%d][%d]'%(lane,vc)),expand=False)
                pyrogue.streamConnect(self.prbTx[lane][vc], self.dmaStream[lane][vc])
                self.add(self.prbTx[lane][vc])          

# Set base
base = MyRoot(name='pciServer',description='DMA Loopback Testing')

# Start the system
base.start(
    pollEn   = args.pollEn,
    initRead = args.initRead,
    timeout  = 100.0,
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
