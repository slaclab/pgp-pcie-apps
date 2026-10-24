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
import surf.protocols.pgp as pgp

rogue.Version.minVersion('6.0.0')

class PgpRoot(pr.Root):
    def __init__(self,
            dev          = '/dev/datadev_0',
            numLane      = 1,     # Number of DMA lanes
            numVc        = 1,     # Number of virtual channels per lane
            version      = 4,     # PGP protocol version (2, 3 or 4)
            swRx         = True,  # Enable the SW PRBS receivers
            swTx         = True,  # Enable the SW PRBS transmitters
            prbsWidth    = 256,   # SW PRBS generator width in bits
            dmaFifoMon   = False, # Include the AxiStreamDmaV2Fifo monitors
            boardType    = None,  # PCIe card type, used to select the I2C mapping
            **kwargs):
        super().__init__(timeout=5.0, **kwargs)

        self.zmqServer = pr.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(dev)

        # Create arrays to be filled
        self.dmaStream = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsRx    = [[None for _ in range(numVc)] for _ in range(numLane)]
        self.prbsTx    = [[None for _ in range(numVc)] for _ in range(numLane)]

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            memBase     = self.memMap,
            numDmaLanes = numLane,
            boardType   = boardType,
            expand      = True,
        ))

        if dmaFifoMon:
            for lane in range(numLane):
                self.add(axi.AxiStreamDmaV2Fifo(
                    name    = f'AxiStreamDmaV2Fifo[{lane}]',
                    offset  = 0x0010_0000 + lane*0x100,
                    memBase = self.memMap,
                    expand  = False,
                ))

        for lane in range(numLane):

            # Add PGP Core
            laneBase = 0x0080_0000 + lane*0x1_0000
            if version == 4:
                self.add(pgp.Pgp4AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = laneBase,
                    memBase = self.memMap,
                    numVc   = numVc,
                    writeEn = True,
                    expand  = True,
                ))
            elif version == 3:
                self.add(pgp.Pgp3AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = laneBase,
                    memBase = self.memMap,
                    numVc   = numVc,
                    writeEn = True,
                    expand  = False,
                ))
            elif version == 2:
                self.add(pgp.Pgp2bAxi(
                    name    = f'Lane[{lane}]',
                    offset  = laneBase + 0x1000,
                    memBase = self.memMap,
                    expand  = False,
                ))
            else:
                raise ValueError(f'Invalid PGP version ({version})')

            self.add(axi.AxiStreamMonAxiL(
                name        = f'PgpTxAxisMon[{lane}]',
                offset      = laneBase + 0x3000,
                numberLanes = numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = f'PgpRxAxisMon[{lane}]',
                offset      = laneBase + 0x4000,
                numberLanes = numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            # Loop through the virtual channels
            for vc in range(numVc):

                if swRx or swTx:
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(dev, (0x100*lane)+vc, 1)

                if swRx:
                    # Connect the SW PRBS Receiver module
                    self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                        name         = f'SwPrbsRx[{lane}][{vc}]',
                        width        = prbsWidth,
                        checkPayload = True,
                        expand       = False,
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

        if swTx:

            @self.command()
            def EnableAllSwTx():
                for tx in self.find(typ=pr.utilities.prbs.PrbsTx):
                    tx.txEnable.set(True)

            @self.command()
            def DisableAllSwTx():
                for tx in self.find(typ=pr.utilities.prbs.PrbsTx):
                    tx.txEnable.set(False)
