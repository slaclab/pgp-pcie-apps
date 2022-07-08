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
import pgp_pcie_apps.PrbsTester as test

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
    "--numLanes",
    "-l",
    type     = int,
    required = False,
    default  = 1,
    help     = "# of DMA Lanes",
)

parser.add_argument(
    "--prbsWidth",
    "-w",
    type     = int,
    required = False,
    default  = 32,
    help     = "# of DMA Lanes",
)

parser.add_argument(
    "--numVc",
    "-c",
    type     = int,
    required = False,
    default  = 1,
    help     = "# of channels per lane",
)

parser.add_argument(
    "--loopback",
    action = 'store_true',
    default  = False,
    help     = "Loop incomming prbs streams from firmware TX back to firmware RX"
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

# Get the arguments
args = parser.parse_args()

#################################################################

class MyRoot(pr.Root):
    def __init__(   self,
            name        = "pciServer",
            description = "DMA Loopback Testing",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        # Create an arrays to be filled
        self.dmaStream = [[None for x in range(args.numVc)] for y in range(args.numLanes)]
        self.prbsRx    = [[None for x in range(args.numVc)] for y in range(args.numLanes)]
        self.prbRg     = [[None for x in range(args.numVc)] for y in range(args.numLanes)]

        # Create PCIE memory mapped interface
        if args.sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 8000)
        else:
            self.memMap = rogue.hardware.axi.AxiMemMap(args.dev,)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = args.numLanes,
            expand      = True,
        ))

        # Add PRBS hardware
        self.add(test.Hardware(
            numLanes = args.numLanes,
            VCs = args.numVc,
            name    =("Hardware"),
            memBase = self.memMap,
            offset =  0x00800000,
            expand = False,
        ))
#         for i in range(4):
#             self.add(axi.AxiMemTester(
#                 name    = f'AxiMemTester[{i}]',
#                 offset  = 0x0010_0000+i*0x1_0000,
#                 memBase = self.memMap,
#                 expand  = True,
#             ))

        # # Loop through the DMA channels
        # for lane in range(args.numLanes):

        #     self.add(test.PrbsLane(
        #         numvc = args.numVc,
        #         name    =(f"FwPrbsLane[{lane}]"),
        #         memBase = self.memMap,
        #         offset =  0x00800000 + (0x10000*lane),
        #         expand = False,
        #     ))


            # # Loop through the virtual channels
            # for vc in range(args.numVc):


            #     # Add the FW PRBS RateGen Module
            #     self.add(ssi.SsiPrbsRateGen(
            #         name    = ('FwPrbsRateGen[%d][%d]' % (lane,vc)),
            #         memBase = self.memMap,
            #         offset  = 0x00800000 + (0x10000*lane) + (0x1000*(2*vc+0)),
            #         expand  = False,
            #     ))


            #     # Add the FW PRBS RX Module
            #     self.add(ssi.SsiPrbsRx(
            #         name    = ('FwPrbsRx[%d][%d]' % (lane,vc)),
            #         memBase = self.memMap,
            #         offset  = 0x00800000 + (0x10000*lane) + (0x1000*(2*vc+1)),
            #         expand  = False,
            #     ))

        # Loop through the DMA channels
        for lane in range(args.numLanes):

            # Loop through the virtual channels
            for vc in range(args.numVc):

                # Set the DMA loopback channel
                if args.sim:
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost', 8002 + (512*lane) + (vc*2))
                else:
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)

                # self.dmaStream[lane][vc].setDriverDebug(0)

                if (args.loopback):
                    # Loopback the PRBS data
                    self.dmaStream[lane][vc] >> self.dmaStream[lane][vc]

                else:

                    # Connect the SW PRBS Receiver module
                    self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                        width        = args.prbsWidth,
                        checkPayload = False,
                        expand       = False,
                    )
                    self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                    self.add(self.prbsRx[lane][vc])


                    # Connect the SW PRBS Transmitter module
                    self.prbRg[lane][vc] = pr.utilities.prbs.PrbsTx(
                        name    = ('SwPrbsRateGen[%d][%d]'%(lane,vc)),
                        width   = args.prbsWidth,
                        expand  = False,
                    )
                    self.prbRg[lane][vc] >> self.dmaStream[lane][vc]
                    self.add(self.prbRg[lane][vc])

        @self.command()
        def SetAllRawPeriods(arg):
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.RawPeriod.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllRates(arg):
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.TxRate.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllPacketLengths(arg):
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.PacketLength.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def EnableN(arg):
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(arg>0)
                arg -= 1

        @self.command()
        def EnableAllFwRg():
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(True)
        

        @self.command()
        def DisableAllFwRg():
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(False)

        @self.command()
        def ResetRGBandwidthMin():
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.BandwidthMin.set(rg.Bandwidth.get())

        @self.command()
        def ResetRGFrameRateMin():
            fwRgDevices = root.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.FrameRateMin.set(rg.FrameRate.get())


#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:

    swRxDevices = root.find(typ=pr.utilities.prbs.PrbsRx)
    for rx in swRxDevices:
        rx.checkPayload.set(False)

    pyrogue.pydm.runPyDM(root=root)

#################################################################
