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

import setupLibPaths
import sys
import rogue
import argparse

import rogue.hardware.axi
import rogue.interfaces.stream

import pyrogue as pr
import pyrogue.pydm
import pyrogue.utilities.prbs

import axipcie             as pcie
import surf.axi            as axi
import surf.protocols.htsp as htsp
import surf.protocols.ssi  as ssi

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
    "--numVc",
    type     = int,
    required = False,
    default  = 1,
    help     = "# of VC (virtual channels)",
)

parser.add_argument(
    "--prbsWidth",
    type     = int,
    required = False,
    default  = 512,
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

parser.add_argument(
    "--boardType",
    type     = str,
    required = False,
    default  = None,
    help     = "define the type of PCIe card, used to select I2C mapping. Options: [none or XilinxVariumC1100, XilinxAlveoU200, etc]",
)

# Get the arguments
args = parser.parse_args()

#################################################################

class MyRoot(pr.Root):
    def __init__(   self,
            name        = "pciServer",
            description = "DMA Loopback Testing",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)

        # Create arrays to be filled
        self.dmaStream   = [[None for _ in range(args.numVc)] for _ in range(2)]
        self.prbsRx      = [[None for _ in range(args.numVc)] for _ in range(2)]
        self.prbsTx      = [[None for _ in range(args.numVc)] for _ in range(2)]

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = 2,
            boardType   = args.boardType,
            expand      = False,
        ))

        # Add devices
        for lane in range(2):

            self.add(htsp.HtspAxiL(
                name    = f'Lane[{lane}]',
                offset  = (0x00800000 + lane*0x1_0000),
                memBase = self.memMap,
                numVc   = args.numVc,
                writeEn = True,
                expand  = True,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'TxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x1000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'RxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x2000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            # Loop through the virtual channels
            for vc in range(args.numVc):

                self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)

                # Connect the SW PRBS Receiver module
                self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                    name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                    width        = args.prbsWidth,
                    checkPayload = True,
                    expand       = True,
                )
                self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                self.add(self.prbsRx[lane][vc])

                # Connect the SW PRBS Transmitter module
                self.prbsTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                    name    = ('SwPrbsTx[%d][%d]'%(lane,vc)),
                    width   = args.prbsWidth,
                    expand  = False,
                )
                self.prbsTx[lane][vc] >> self.dmaStream[lane][vc]
                self.add(self.prbsTx[lane][vc])

        @self.command()
        def EnableAllSwTx():
            if (self.perf is False):
                swTxDevices = root.find(typ=pr.utilities.prbs.PrbsTx)
                for tx in swTxDevices:
                    tx.txEnable.set(True)

        @self.command()
        def DisableAllSwTx():
            if (self.perf is False):
                swTxDevices = root.find(typ=pr.utilities.prbs.PrbsTx)
                for tx in swTxDevices:
                    tx.txEnable.set(False)

    def start(self, **kwargs):
        super().start(**kwargs)

        # Check for Bifurcated Pcie
        if self.AxiPcieCore.AxiVersion.ImageName.getDisp() == 'XilinxVariumC1100Htsp100GbpsBifurcatedPcie':

            # Check for 2nd endpoint
            if self.AxiPcieCore.AxiVersion.BOOT_PROM_G.getDisp() == 'UNDEFINED':
                # Disable and hide index = 0
                disableIndex = 0

            # Else it's the 1st endpoint
            else:
                # Disable and hide index = 1
                disableIndex = 1

        # Hide and disable
        self.Lane[disableIndex].hidden = True
        self.Lane[disableIndex].enable._value = False

        self.TxAxisMon[disableIndex].hidden = True
        self.TxAxisMon[disableIndex].enable._value = False

        self.RxAxisMon[disableIndex].hidden = True
        self.RxAxisMon[disableIndex].enable._value = False

        # DMA always connected to physical lane=0 in Bifurcated Pcie
        self.AxiPcieCore.DmaIbAxisMon.Ch[1].hidden = True
        self.AxiPcieCore.DmaIbAxisMon.Ch[1].enable._value = False

        self.AxiPcieCore.DmaObAxisMon.Ch[1].hidden = True
        self.AxiPcieCore.DmaObAxisMon.Ch[1].enable._value = False

        for vc in range(args.numVc):
            self.SwPrbsTx[1][vc].hidden = True
            self.SwPrbsTx[1][vc].enable._value = False

            self.SwPrbsRx[1][vc].hidden = True
            self.SwPrbsRx[1][vc].enable._value = False

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:
     pyrogue.pydm.runPyDM(serverList = root.zmqServer.address)

#################################################################
