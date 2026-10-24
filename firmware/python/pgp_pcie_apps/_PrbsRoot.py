##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import pyrogue as pr
import pyrogue.interfaces
import pyrogue.utilities.prbs

import rogue
import rogue.hardware.axi

import axipcie            as pcie
import surf.axi           as axi
import surf.protocols.ssi as ssi

import pgp_pcie_apps

rogue.Version.minVersion('6.5.0')

class PrbsRoot(pr.Root):
    def __init__(self,
            dev          = '/dev/datadev_0',
            numLane      = 1,     # Number of DMA lanes
            numVc        = 1,     # Number of virtual channels per lane
            prbsWidth    = 512,   # PRBS generator width in bits
            loopback     = False, # Loop the DMA streams back to the FW PRBS RX
            fwRx         = False, # Include the FW PRBS receivers
            fwTx         = True,  # Include the FW PRBS transmitters
            swRx         = True,  # Enable the SW PRBS receivers
            swTx         = False, # Enable the SW PRBS transmitters
            syncTrig     = False, # Include the SyncTrigger and gate the FW PRBS TX with it
            **kwargs):
        super().__init__(timeout=5.0, **kwargs)

        self._syncTrig = syncTrig

        self.zmqServer = pr.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        # Create arrays to be filled
        self.dmaStream = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsRx    = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsTx    = [[None for _ in range(numVc)] for _ in range(numLane)]

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(dev)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            memBase     = self.memMap,
            numDmaLanes = numLane,
            expand      = True,
        ))

        for lane in range(numLane):
            self.add(axi.AxiStreamDmaV2Fifo(
                name    = f'MigDmaBuffer[{lane}]',
                offset  = 0x0010_0000 + lane*0x100,
                memBase = self.memMap,
                expand  = False,
            ))

        self.add(axi.AxiStreamMonAxiL(
            name        = 'BuffIbMon',
            offset      = 0x0020_0000,
            numberLanes = numLane,
            memBase     = self.memMap,
        ))

        # Loop through the DMA channels
        for lane in range(numLane):

            # Loop through the virtual channels
            for vc in range(numVc):

                prbsBase = 0x0080_0000 + lane*0x1_0000 + vc*0x2000

                if fwTx or loopback:
                    # Add the FW PRBS TX Module
                    self.add(ssi.SsiPrbsTx(
                        name       = f'FwPrbsTx[{lane}][{vc}]',
                        offset     = prbsBase,
                        memBase    = self.memMap,
                        clock_freq = 250e6,
                        expand     = False,
                    ))

                if fwRx or loopback:
                    # Add the FW PRBS RX Module
                    self.add(ssi.SsiPrbsRx(
                        name        = f'FwPrbsRx[{lane}][{vc}]',
                        offset      = prbsBase + 0x1000,
                        memBase     = self.memMap,
                        rxClkPeriod = 4.0e-9,
                        expand      = False,
                    ))

        if syncTrig:
            self.add(pgp_pcie_apps.SyncTrigger(
                offset    = 0x0088_0000,
                memBase   = self.memMap,
                prbsWidth = prbsWidth,
                expand    = True,
            ))

        # Loop through the DMA channels
        for lane in range(numLane):

            # Loop through the virtual channels
            for vc in range(numVc):

                # Set the DMA loopback channel
                self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev, (0x100*lane)+vc, 1)

                if loopback:
                    # Loopback the PRBS data
                    self.dmaStream[lane][vc] >> self.dmaStream[lane][vc]
                    continue

                if swRx:
                    # Connect the SW PRBS Receiver module
                    self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = f'SwPrbsRx[{lane}][{vc}]',
                        width        = prbsWidth,
                        checkPayload = False,
                        expand       = True,
                    )
                    self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                    self.add(self.prbsRx[lane][vc])

                if swTx:
                    # Connect the SW PRBS Transmitter module
                    self.prbsTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                        name   = f'SwPrbsTx[{lane}][{vc}]',
                        width  = prbsWidth,
                        expand = False,
                    )
                    self.prbsTx[lane][vc] >> self.dmaStream[lane][vc]
                    self.add(self.prbsTx[lane][vc])

        @self.command()
        def EnableAllFwTx():
            for tx in self.find(typ=ssi.SsiPrbsTx):
                tx.TxEn.set(True)

        @self.command()
        def DisableAllFwTx():
            for tx in self.find(typ=ssi.SsiPrbsTx):
                tx.TxEn.set(False)

        @self.command()
        def EnableAllSwCheck():
            for rx in self.find(typ=pr.utilities.prbs.PrbsRx):
                rx.checkPayload.set(True)

        @self.command()
        def DisableAllSwCheck():
            for rx in self.find(typ=pr.utilities.prbs.PrbsRx):
                rx.checkPayload.set(False)

    def start(self, **kwargs):
        super().start(**kwargs)

        # FW PRBS TX free-runs unless the SyncTrigger is gating it
        for tx in self.find(typ=ssi.SsiPrbsTx):
            tx.AxiEn.set(not self._syncTrig)
