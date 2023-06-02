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
import rogue.protocols.xilinx

import pyrogue as pr
import pyrogue.pydm
import pyrogue.utilities.prbs

import axipcie            as pcie
import surf.axi           as axi
import surf.xilinx        as xilinx
import surf.protocols.pgp as pgp

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()


# Add arguments
parser.add_argument(
    "--dev",
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device",
)

parser.add_argument(
    "--sim",
    action = 'store_true',
    default = False)

parser.add_argument(
    "--dmaLanes",
    type     = int,
    required = False,
    default  = 1,
    help     = "# of DMA Lanes",
)

parser.add_argument(
    "--pgpLanes",
    type     = int,
    required = False,
    default  = 1,
    help     = "# of PGP Lanes",
)

parser.add_argument(
    "--numVc",
    type     = int,
    required = False,
    default  = 4,
    help     = "# of VC (virtual channels)",
)

parser.add_argument(
    "--pgpVersion",
    type     = int,
    required = False,
    default  = 4,
    help     = "PGP Protocol Version",
)

parser.add_argument(
    "--swRx",
    action = 'store_true',
    default  = False,
    help     = "Add PRBS Rx to tree"
)

parser.add_argument(
    "--swTx",
    action ='store_true',
    default  = False,
    help     = "Add PRBS Tx to tree"
)

parser.add_argument(
    "--prbsWidth",
    type     = int,
    required = False,
    default  = 256,
    help     = "Word with for PRBS software modules"
)

parser.add_argument(
    "--pollEn",
    action = 'store_true',
    default  = False,
    help     = "Enable auto-polling",
)

parser.add_argument(
    "--initRead",
    action = 'store_true',
    default  = False,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--boardType",
    type     = str,
    required = False,
    default  = None,
    help     = "define the type of PCIe card, used to select I2C mapping. Options: [none or SlacPgpCardG4, Kcu1500, etc]",
)

parser.add_argument(
    '--xvc',
    action = 'store_true',
    default = False)

# Get the arguments
args = parser.parse_args()

#################################################################

class MyRoot(pr.Root):
    def __init__(self,
                 name        = "pciServer",
                 description = "DMA Loopback Testing",
                 **kwargs):
    
        super().__init__(name=name, description=description, **kwargs)

        # Create PCIE memory mapped interface
        if args.sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 11000)
        else:
            self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)

        if (args.swRx or args.swTx):
            self.dmaStream   = [[None for x in range(args.numVc)] for y in range(args.pgpLanes)]
            self.prbsRx      = [[None for x in range(args.numVc)] for y in range(args.pgpLanes)]
            self.prbsTx      = [[None for x in range(args.numVc)] for y in range(args.pgpLanes)]

        # Hack in the XVC
        if (args.xvc):
            self.xvcServer = rogue.protocols.xilinx.Xvc(2542)
            self.addProtocol(self.xvcServer)

            # XVC stream hard coded at DMA Lane 1
            self.xvcStream = rogue.hardware.axi.AxiStreamDma(args.dev, 0x100, 1)

            # Connect stream to server
            self.xvcServer == self.xvcStream

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset     = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = args.dmaLanes,
            boardType   = args.boardType,
            expand      = True,
        ))

        # Add PGP Core
        for pgpLane in range(args.pgpLanes):
            if (args.pgpVersion == 4):
                self.add(pgp.Pgp4AxiL(
                    name    = f'Lane[{pgpLane}]',
                    offset  = (0x00800000 + pgpLane*0x00010000),
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    expand  = True,
                ))
            elif (args.pgpVersion == 3):
                self.add(pgp.Pgp3AxiL(
                    name    = f'Lane[{pgpLane}]',
                    offset  = (0x00800000 + pgpLane*0x00010000),
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    expand  = False,
                ))
            else:
                self.add(pgp.Pgp2bAxi(
                    name    = f'Lane[{pgpLane}]',
                    offset  = (0x00800000 + pgpLane*0x00010000 + 0x1000),
                    memBase = self.memMap,
                    expand  = False,
                ))

            self.add(xilinx.Gtye4Channel(
                name = f'GtyDrp[{pgpLane}]',
                offset = (0x00800000 + pgpLane*0x00010000 + 0x000),
                memBase = self.memMap,
                expand = False))
                

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpTxAxisMon[{pgpLane}]'),
                offset      = (0x00800000 + pgpLane*0x00010000 + 0x3000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpRxAxisMon[{pgpLane}]'),
                offset      = (0x00800000 + pgpLane*0x00010000 + 0x4000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            pgpLanesPerDmaLane = args.pgpLanes // args.dmaLanes

            # Loop through the virtual channels
            for vc in range(args.numVc):

                dmaDest = ((pgpLane // pgpLanesPerDmaLane) * 0x100) + ((pgpLane % pgpLanesPerDmaLane) * 0b100) + vc

                if (args.swRx or args.swTx):
                    if args.sim:
                        port = 11002 + (512*pgpLane) + (vc*2)
                        print(f'Tcp data stream on port {port}')
                        self.dmaStream[pgpLane][vc] = rogue.interfaces.stream.TcpClient('localhost', port)
                    else:
                        self.dmaStream[pgpLane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev, dmaDest, 1)

                if (args.swRx):

                    # Connect the SW PRBS Receiver module
                    self.prbsRx[pgpLane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = f'SwPrbsRx[{pgpLane}][{vc}]',
                        width        = args.prbsWidth,
                        checkPayload = True,
                        expand       = False,
                    )
                    self.dmaStream[pgpLane][vc] >> self.prbsRx[pgpLane][vc]
                    self.add(self.prbsRx[pgpLane][vc])

                if (args.swTx):

                    # Connect the SW PRBS Transmitter module
                    self.prbsTx[pgpLane][vc] = pr.utilities.prbs.PrbsTx(
                        name    = f'SwPrbsTx[{pgpLane}][{vc}]',
                        width   = args.prbsWidth,
                        expand  = False,
                    )
                    self.prbsTx[pgpLane][vc] >> self.dmaStream[pgpLane][vc]
                    self.add(self.prbsTx[pgpLane][vc])

        @self.command()
        def EnableAllSwTx():
            swTxDevices = root.find(typ=pr.utilities.prbs.PrbsTx)
            for tx in swTxDevices:
                tx.txEnable.set(True)

        @self.command()
        def DisableAllSwTx():
            swTxDevices = root.find(typ=pr.utilities.prbs.PrbsTx)
            for tx in swTxDevices:
                tx.txEnable.set(False)

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:
     pyrogue.pydm.runPyDM(root=root)

#################################################################
