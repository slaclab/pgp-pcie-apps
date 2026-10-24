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
import rogue.interfaces.memory
import rogue.interfaces.stream

import axipcie as pcie

rogue.Version.minVersion('6.0.0')

class LoopbackRoot(pr.Root):
    def __init__(self,
            dev          = '/dev/datadev_0',
            sim          = False, # Connect to the VCS simulation instead of the PCIe card
            numLane      = 1,     # Number of DMA lanes
            numVc        = 1,     # Number of virtual channels per lane
            prbsWidth    = 64,    # SW PRBS generator width in bits
            boardType    = None,  # PCIe card type, used to select the I2C mapping
            **kwargs):
        super().__init__(timeout=5.0, **kwargs)

        self.sim = sim

        self.zmqServer = pr.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        #################################################################

        # Create arrays to be filled
        self.dmaStream = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsRx    = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsTx    = [[None for _ in range(numVc)] for _ in range(numLane)]

        # VCS simulation
        if sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 8000)

            # Create the DMA loopback channel
            for lane in range(numLane):
                for vc in range(numVc):
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost', 8002+(512*lane)+2*vc)

        # DataDev PCIe Card
        else:
            self.memMap = rogue.hardware.axi.AxiMemMap(dev)

            # Create the DMA loopback channel
            for lane in range(numLane):
                for vc in range(numVc):
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev, (0x100*lane)+vc, 1)

        #################################################################

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            memBase     = self.memMap,
            numDmaLanes = numLane,
            boardType   = boardType,
        ))

        self.add(pcie.TerminateQsfp(
            name      = 'GtRefClockMon',
            offset    = 0x0080_0000,
            memBase   = self.memMap,
            numRefClk = 2,
        ))

        for lane in range(numLane):
            for vc in range(numVc):

                # Connect the SW PRBS Receiver module
                self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                    name   = f'SwPrbsRx[{lane}][{vc}]',
                    width  = prbsWidth,
                    expand = True,
                )
                self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                self.add(self.prbsRx[lane][vc])

                # Connect the SW PRBS Transmitter module
                self.prbsTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                    name   = f'SwPrbsTx[{lane}][{vc}]',
                    width  = prbsWidth,
                )
                self.prbsTx[lane][vc] >> self.dmaStream[lane][vc]
                self.add(self.prbsTx[lane][vc])

    def start(self, **kwargs):
        super().start(**kwargs)

        # Only the DMA driver reports its RX buffer count
        if not self.sim:
            print(f'Number of RX buffers = {self.dmaStream[0][0].getRxBuffCount()}')

        # Start the SW PRBS transmitters
        for tx in self.find(typ=pr.utilities.prbs.PrbsTx):
            tx.txEnable.set(True)
