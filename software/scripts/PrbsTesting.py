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
import argparse

import rogue
import rogue.hardware.axi
import rogue.interfaces.stream

import pyrogue as pr
import pyrogue.pydm
import pyrogue.utilities.prbs
import pyrogue.interfaces.simulation

import axipcie            as pcie
import surf.axi           as axi
import surf.protocols.ssi as ssi

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
    "--prbsWidth",
    type     = int,
    required = False,
    default  = 64,
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
    "--loopback",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--fwRx",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--fwTx",
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable read all variables at start",
)

parser.add_argument(
    "--swRx",
    type     = argBool,
    required = False,
    default  = True,
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
    "--syncTrig",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable sync triggers",
)

# Get the arguments
args = parser.parse_args()

#################################################################

class SyncTrigger(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.prbsByte = args.prbsWidth>>3

        self.add(pr.RemoteVariable(
            name         = "PacketLength",
            description  = "",
            offset       =  0x0,
            bitSize      =  32,
            mode         = "RW",
            disp         = '{}',
            hidden       = True,
        ))

        self.add(pr.LinkVariable(
            name         = 'PacketSize',
            mode         = "RW",
            units         = "Bytes",
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = lambda: (self.PacketLength.value()+1)*self.prbsByte,
            linkedSet    = lambda value, write: self.PacketLength.set( int(value/self.prbsByte)-1 ),
            dependencies = [self.PacketLength],
        ))

        self.add(pr.RemoteVariable(
            name         = "TimerSize",
            description  = "",
            offset       =  0x4,
            bitSize      =  32,
            mode         = "RW",
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = "RunEnable",
            description  = "",
            offset       =  0x8,
            bitSize      =  1,
            mode         = "RW",
        ))

        self.add(pr.LinkVariable(
            name         = 'Rate',
            mode         = "RW",
            units         = "Hz",
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = lambda: int(156.25E+6/float(self.TimerSize.value())),
            linkedSet    = lambda value, write: self.TimerSize.set( int(156.25E+6/value) ),
            dependencies = [self.TimerSize],
        ))

class MyRoot(pr.Root):
    def __init__(   self,
            name        = "pciServer",
            description = "DMA Loopback Testing",
            **kwargs):
        super().__init__(timeout=5.0, **kwargs)

        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        self._syncTrig = args.syncTrig

        # Create an arrays to be filled
        self.dmaStream = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbsRx    = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbTx     = [[None for x in range(args.numVc)] for y in range(args.numLane)]

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(args.dev,)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = args.numLane,
            expand      = True,
        ))

        for i in range(args.numLane):
            self.add(axi.AxiStreamDmaV2Fifo(
                name    = f'MigDmaBuffer[{i}]',
                offset  = 0x0010_0000+i*0x100,
                memBase = self.memMap,
                expand  = False,
            ))

        # Loop through the DMA channels
        for lane in range(args.numLane):

            # Loop through the virtual channels
            for vc in range(args.numVc):

                if (args.fwTx):
                    # Add the FW PRBS TX Module
                    self.add(ssi.SsiPrbsTx(
                        name       = ('FwPrbsTx[%d][%d]' % (lane,vc)),
                        memBase    = self.memMap,
                        offset     = 0x00800000 + (0x10000*lane) + (0x1000*(2*vc+0)),
                        clock_freq = 250e6,
                        expand     = False,
                    ))

                if (args.fwRx):
                    # Add the FW PRBS RX Module
                    self.add(ssi.SsiPrbsRx(
                        name        = ('FwPrbsRx[%d][%d]' % (lane,vc)),
                        memBase     = self.memMap,
                        offset      = 0x00800000 + (0x10000*lane) + (0x1000*(2*vc+1)),
                        rxClkPeriod = 4.0e-9,
                        expand      = False,
                    ))

        if self._syncTrig:
            self.add(SyncTrigger(
                offset  = 0x00880000,
                memBase = self.memMap,
                expand  = True,
            ))

        # Loop through the DMA channels
        for lane in range(args.numLane):

            # Loop through the virtual channels
            for vc in range(args.numVc):

                # Set the DMA loopback channel
                self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)
                # self.dmaStream[lane][vc].setDriverDebug(0)

                if (args.loopback):
                    # Loopback the PRBS data
                    self.dmaStream[lane][vc] >> self.dmaStream[lane][vc]

                else:
                    if (args.swRx):
                        # Connect the SW PRBS Receiver module
                        self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                            name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                            width        = args.prbsWidth,
                            checkPayload = False,
                            expand       = True,
                        )
                        self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                        self.add(self.prbsRx[lane][vc])

                    if (args.swTx):
                        # Connect the SW PRBS Transmitter module
                        self.prbTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                            name    = ('SwPrbsTx[%d][%d]'%(lane,vc)),
                            width   = args.prbsWidth,
                            expand  = False,
                        )
                        self.prbTx[lane][vc] >> self.dmaStream[lane][vc]
                        self.add(self.prbTx[lane][vc])

        @self.command()
        def EnableAllFwTx():
            fwTxDevices = root.find(typ=ssi.SsiPrbsTx)
            for tx in fwTxDevices:
                tx.TxEn.set(True)

        @self.command()
        def DisableAllFwTx():
            fwTxDevices = root.find(typ=ssi.SsiPrbsTx)
            for tx in fwTxDevices:
                tx.TxEn.set(False)

        @self.command()
        def EnableAllSwCheck():
            swDev = root.find(typ=pr.utilities.prbs.PrbsRx)
            for rx in swDev:
                rx.checkPayload.set(True)

        @self.command()
        def DisableAllSwCheck():
            swDev = root.find(typ=pr.utilities.prbs.PrbsRx)
            for rx in swDev:
                rx.checkPayload.set(False)

    def start(self, **kwargs):
        super().start(**kwargs)
        fwTxDevices = self.find(typ=ssi.SsiPrbsTx)
        for tx in fwTxDevices:
            tx.AxiEn.set(not self._syncTrig)

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:

    swRxDevices = root.find(typ=pr.utilities.prbs.PrbsRx)
    for rx in swRxDevices:
        rx.checkPayload.set(False)

    pyrogue.pydm.runPyDM(serverList = root.zmqServer.address)

#################################################################
