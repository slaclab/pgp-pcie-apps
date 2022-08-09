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
import pyrogue.utilities.fileio
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
                    no_tx=False,
                    no_rx=False,
                    writeToDisk = False,
            **kwargs):
        super().__init__(**kwargs)

        if writeToDisk:
            self.add(pyrogue.utilities.fileio.StreamWriter(name='DataWriter'))


        # Create an arrays to be filled
        self.dmaStream = [[None for x in range(numVc)] for y in range(numLanes)]
        self.prbsRx    = [[None for x in range(numVc)] for y in range(numLanes)]
        self.prbRg     = [[None for x in range(numVc)] for y in range(numLanes)]

        # Create PCIE memory mapped interface
        if sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 11000)
        else:
            self.memMap = rogue.hardware.axi.AxiMemMap(dev,)

        self.addInterface(self.memMap)

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
            no_rx = no_rx,
            no_tx = no_tx,
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
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost', 11002 + (512*lane) + (vc*2))
                else:
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+vc,1)

                    if writeToDisk:
                        self.dmaStream[lane][vc] >> self.DataWriter.getChannel1(0x100*lane+vc)

                self.addInterface(self.dmaStream[lane][vc])

                # self.dmaStream[lane][vc].setDriverDebug(0)

                if (loopback):
                    # Loopback the PRBS data
                    fifo = rogue.interfaces.stream.Fifo(100, 0, True)
                    self.addInterface(fifo)
                    self.dmaStream[lane][vc] >> fifo >> self.dmaStream[lane][vc]

                else:

                    # Connect the SW PRBS Receiver module
                    if no_tx is not True:
                        self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                            name         = ('SwPrbsRx[%d][%d]'%(lane,vc)),
                            width        = prbsWidth,
                            checkPayload = False,
                            expand       = False,
                        )
                        self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                        self.add(self.prbsRx[lane][vc])
                        self.addInterface(self.prbsRx[lane][vc])


                    # Connect the SW PRBS Transmitter module
                    if no_rx is not True:
                        self.prbRg[lane][vc] = pr.utilities.prbs.PrbsTx(
                            name    = ('SwPrbsTx[%d][%d]'%(lane,vc)),
                            width   = prbsWidth,
                            expand  = False,
                        )
                        self.prbRg[lane][vc] >> self.dmaStream[lane][vc]
                        self.add(self.prbRg[lane][vc])
                        self.addInterface(self.prbRg[lane][vc])

        self.add(pr.LinkVariable(
            name = 'AggBandwidth',
            dependencies = [rx.Bandwidth for lane in self.Hardware.Lane.values() for rx in lane.TxMon.Ch.values()],
            mode = 'RO',
            units = 'Mbps',
            linkedGet = lambda var, read: sum([x.get(read=read) for x in var.dependencies])))

        self.add(pr.LinkVariable(
            name = 'AggFrameRate',
            dependencies = [rx.FrameRate for lane in self.Hardware.Lane.values() for rx in lane.TxMon.Ch.values()],
            mode = 'RO',
            units = 'Hz',
            linkedGet = lambda var, read: sum([x.get(read=read) for x in var.dependencies])))

        @self.command()
        def SetAllPeriods(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsTx)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.TrigDly.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllRates(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsTx)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.TrigRate.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def SetAllPacketLengths(arg):
            fwRgDevices = self.find(typ=ssi.SsiPrbsTx)
            for rg in fwRgDevices:
                val = rg.TxEn.get()
                rg.TxEn.set(False)
                rg.PacketLength.set(arg)
                rg.TxEn.set(val)

        @self.command()
        def EnableChannels(arg):
            lanes = arg[0]
            for ln in range(numLanes):
                channels = arg[1]
                for vc in range(numVc):
                    self.Hardware.Lane[ln].PrbsTx[vc].TxEn.set(channels > 0 and lanes > 0)
                    channels -= 1
                lanes -= 1

        @self.command()
        def EnableAllChannels():
            fwRgDevices = self.find(typ=ssi.SsiPrbsTx)
            for rg in fwRgDevices:
                rg.TxEn.set(True)
        
        @self.command()
        def DisableAllChannels():
            fwRgDevices = self.find(typ=ssi.SsiPrbsTx)
            for rg in fwRgDevices:
                rg.TxEn.set(False)

        @self.command()
        def outputData():
            fwRgDevices = self.find(typ=ssi.SsiPrbsRateGen)

            for rg in range(len(fwRgDevices)):
                if(fwRgDevices[rg].TxEn):
                    print(f"Rategen[{rg}] BW:{fwRgDevices[rg].Bandwidth.get()}   FR:{fwRgDevices[rg].FrameRate.get()}")

        @self.command()
        def PurgeData():
            fwRgDevices = self.find(typ=axi.AxiStreamMonAxiL)
            for rg in fwRgDevices:
                rg.CntRst()
                
