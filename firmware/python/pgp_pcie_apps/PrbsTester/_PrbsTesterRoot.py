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

rogue.Logging.setFilter('pyrogue.Block', rogue.Logging.Debug)

#################################################################

class PrbsRoot(pr.Root):
    def __init__(   self,
                    dev,
                    sim,
                    numLanes,
                    prbsWidth,
                    numVc,
                    loopback,
            **kwargs):
        super().__init__(**kwargs)

        # Create an arrays to be filled
        self.dmaStream = [[None for x in range(numVc)] for y in range(numLanes)]
        self.prbsRx    = [[None for x in range(numVc)] for y in range(numLanes)]
        self.prbRg     = [[None for x in range(numVc)] for y in range(numLanes)]

        # Create PCIE memory mapped interface
        if sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 8000)
        else:
            self.memMap = rogue.hardware.axi.AxiMemMap(dev,)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = numLanes,
            expand      = True,
        ))

        # Add PRBS hardware
        self.add(test.Hardware(
            numLanes = numLanes,
            VCs = numVc,
            name    =("Hardware"),
            memBase = self.memMap,
            offset =  0x00800000,
            expand = False,
        ))

        # Loop through the DMA channels
        for lane in range(numLanes):

            # Loop through the virtual channels
            for vc in range(numVc):

                # Set the DMA loopback channel
                if sim:
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost', 8002 + (512*lane) + (vc*2))
                else:
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+vc,1)

                # self.dmaStream[lane][vc].setDriverDebug(0)

                if (loopback):
                    # Loopback the PRBS data
                    self.dmaStream[lane][vc] >> self.dmaStream[lane][vc]

                else:

                    # Connect the SW PRBS Receiver module
                    self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                        width        = prbsWidth,
                        checkPayload = False,
                        expand       = False,
                    )
                    self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                    self.add(self.prbsRx[lane][vc])


                    # Connect the SW PRBS Transmitter module
                    self.prbRg[lane][vc] = pr.utilities.prbs.PrbsTx(
                        name    = ('SwPrbsRateGen[%d][%d]'%(lane,vc)),
                        width   = prbsWidth,
                        expand  = False,
                    )
                    self.prbRg[lane][vc] >> self.dmaStream[lane][vc]
                    self.add(self.prbRg[lane][vc])

        @self.command()
        def SetAllRawPeriods(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.RawPeriod.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllRates(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.TxRate.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllPacketLengths(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.PacketLength.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def EnableN(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(arg>0)
                arg -= 1

        @self.command()
        def EnableAllFwRg():
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(True)
        

        @self.command()
        def DisableAllFwRg():
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)
            for rg in fwRgDevices:
                rg.TxEn.set(False)

        @self.command()
        def outputData():
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)

            for rg in range(fwRgDevices):
                if(fwRgDevices[rg].TxEn):
                    print(f"Rategen[{rg}] BW:{fwRgDevices[rg].Bandwidth.get()}   FR:{fwRgDevices[rg].FrameRate.get()}")