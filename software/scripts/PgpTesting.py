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
import pyrogue.utilities.prbs

import axipcie            as pcie
import surf.axi           as axi
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
    "--swRx",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--swTx",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--prbsWidth",
    type     = int,
    required = False,
    default  = 256,
    help     = "# of DMA Lanes",
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

        if (args.swRx or args.swTx):
            self.dmaStream   = [[None for x in range(args.numVc)] for y in range(args.numLane)]
            self.prbsRx      = [[None for x in range(args.numVc)] for y in range(args.numLane)]
            self.prbsTx      = [[None for x in range(args.numVc)] for y in range(args.numLane)]

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset  = 0x00000000,
            memBase = self.memMap,
            expand  = True,
        ))

        # Add PGP Core
        for lane in range(args.numLane):
            if (args.version3):
                self.add(pgp.Pgp3AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000),
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    expand  = True,
                ))
            else:
                self.add(pgp.Pgp2bAxi(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000 + 0x1000),
                    memBase = self.memMap,
                    expand  = True,
                ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpTxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x3000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = True,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpRxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x4000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = True,
            ))

            # Loop through the virtual channels
            for vc in range(args.numVc):

                if (args.swRx or args.swTx):
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)

                if (args.swRx):
                    # Connect the SW PRBS Receiver module
                    self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                        width        = args.prbsWidth,
                        checkPayload = False,
                        expand       = False,
                    )
                    pr.streamConnect(self.dmaStream[lane][vc],self.prbsRx[lane][vc])
                    self.add(self.prbsRx[lane][vc])

                if (args.swTx):
                    # Connect the SW PRBS Transmitter module
                    self.prbsTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                        name    = ('SwPrbsTx[%d][%d]'%(lane,vc)),
                        width   = args.prbsWidth,
                        expand  = False,
                    )
                    pr.streamConnect(self.prbsTx[lane][vc], self.dmaStream[lane][vc])
                    self.add(self.prbsTx[lane][vc])


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
guiTop = pr.gui.GuiTop()
appTop.setStyle('Fusion')
guiTop.addTree(base)
guiTop.resize(600, 800)

print("Starting GUI...\n");

# Run GUI
appTop.exec_()

# Close
base.stop()
exit()
