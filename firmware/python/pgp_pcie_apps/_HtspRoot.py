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

import axipcie             as pcie
import surf.axi            as axi
import surf.protocols.htsp as htsp

rogue.Version.minVersion('6.5.0')

class HtspRoot(pr.Root):

    # The HTSP targets always have two lanes
    NUM_LANE = 2

    def __init__(self,
            dev          = '/dev/datadev_0',
            numVc        = 1,    # Number of virtual channels per lane
            swPrbs       = True, # Enable the SW PRBS receivers and transmitters
            prbsWidth    = 512,  # SW PRBS generator width in bits
            boardType    = None, # PCIe card type, used to select the I2C mapping
            **kwargs):
        super().__init__(timeout=5.0, **kwargs)

        self._numVc  = numVc
        self._swPrbs = swPrbs

        self.zmqServer = pr.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(dev)

        # Create arrays to be filled
        self.dmaStream = [[None for _ in range(numVc)] for _ in range(self.NUM_LANE)]
        self.prbsRx    = [[None for _ in range(numVc)] for _ in range(self.NUM_LANE)]
        self.prbsTx    = [[None for _ in range(numVc)] for _ in range(self.NUM_LANE)]

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            memBase     = self.memMap,
            numDmaLanes = self.NUM_LANE,
            boardType   = boardType,
            expand      = False,
        ))

        # Add devices
        for lane in range(self.NUM_LANE):

            laneBase = 0x0080_0000 + lane*0x1_0000

            self.add(htsp.HtspAxiL(
                name    = f'Lane[{lane}]',
                offset  = laneBase,
                memBase = self.memMap,
                numVc   = numVc,
                writeEn = True,
                expand  = True,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = f'TxAxisMon[{lane}]',
                offset      = laneBase + 0x1000,
                numberLanes = numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = f'RxAxisMon[{lane}]',
                offset      = laneBase + 0x2000,
                numberLanes = numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            if not swPrbs:
                continue

            # Loop through the virtual channels
            for vc in range(numVc):

                self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev, (0x100*lane)+vc, 1)

                # Connect the SW PRBS Receiver module
                self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                    name         = f'SwPrbsRx[{lane}][{vc}]',
                    width        = prbsWidth,
                    checkPayload = True,
                    expand       = True,
                )
                self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                self.add(self.prbsRx[lane][vc])

                # Connect the SW PRBS Transmitter module
                self.prbsTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                    name   = f'SwPrbsTx[{lane}][{vc}]',
                    width  = prbsWidth,
                    expand = False,
                )
                self.prbsTx[lane][vc] >> self.dmaStream[lane][vc]
                self.add(self.prbsTx[lane][vc])

        if swPrbs:

            @self.command()
            def EnableAllSwTx():
                for tx in self.find(typ=pr.utilities.prbs.PrbsTx):
                    tx.txEnable.set(True)

            @self.command()
            def DisableAllSwTx():
                for tx in self.find(typ=pr.utilities.prbs.PrbsTx):
                    tx.txEnable.set(False)

    def start(self, **kwargs):
        super().start(**kwargs)

        # Check for Bifurcated Pcie
        if self.AxiPcieCore.AxiVersion.ImageName.getDisp() == 'XilinxVariumC1100Htsp100GbpsBifurcatedPcie':

            # The 2nd endpoint has no boot PROM, so it only owns lane=1.
            # Otherwise it's the 1st endpoint, which only owns lane=0.
            if self.AxiPcieCore.AxiVersion.BOOT_PROM_G.getDisp() == 'UNDEFINED':
                disableIndex = 0
            else:
                disableIndex = 1

            # Hide and disable the lane owned by the other endpoint
            self._disable(self.Lane[disableIndex])
            self._disable(self.TxAxisMon[disableIndex])
            self._disable(self.RxAxisMon[disableIndex])

            # DMA always connected to physical lane=0 in Bifurcated Pcie
            self._disable(self.AxiPcieCore.DmaIbAxisMon.Ch[1])
            self._disable(self.AxiPcieCore.DmaObAxisMon.Ch[1])

            if self._swPrbs:
                for vc in range(self._numVc):
                    self._disable(self.SwPrbsTx[1][vc])
                    self._disable(self.SwPrbsRx[1][vc])

    @staticmethod
    def _disable(node):
        node.hidden = True
        node.enable._value = False
