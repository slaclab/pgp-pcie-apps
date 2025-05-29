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

import axipcie            as pcie
import surf.axi           as axi
import surf.protocols.pgp as pgp

import pgpapps            as pgpapps

#rogue.Logging.setLevel(rogue.Logging.Debug)

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--type",
    type     = str,
    required = False,
    default  = 'pcie',
    help     = "define the type of interface",
)

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
    default  = 8,
    help     = "# of DMA Lanes",
)

parser.add_argument(
    "--numVc",
    type     = int,
    required = False,
    default  = 4,
    help     = "# of VC (virtual channels)",
)

parser.add_argument(
    "--version",
    type     = int,
    required = False,
    default  = 4,
    help     = "PGP Protocol Version",
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
    help     = "define the type of PCIe card, used to select I2C mapping. Options: [none or SlacPgpCardG4, Kcu1500, etc]",
)

parser.add_argument(
    "--prbsWidth",
    type     = int,
    required = False,
    default  = 64,
    help     = "# of DMA Lanes",
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

        self.dmaStream = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbsRx    = [[None for x in range(args.numVc)] for y in range(args.numLane)]
        self.prbTx     = [[None for x in range(args.numVc)] for y in range(args.numLane)]

        # DataDev PCIe Card
        if ( args.type == 'pcie' ):

            # Create PCIE memory mapped interface
            self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)

            # Create the DMA loopback channel
            for lane in range(args.numLane):
                for vc in range(args.numVc):
                    self.dmaStream[lane][vc] = rogue.hardware.axi.AxiStreamDma(args.dev,(0x100*lane)+vc,1)

        # VCS simulation
        elif ( args.type == 'sim' ):

            self.memMap = rogue.interfaces.memory.TcpClient('localhost',8000)

            # Create the DMA loopback channel
            for lane in range(args.numLane):
                for vc in range(args.numVc):
                    self.dmaStream[lane][vc] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*vc)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            memBase      = self.memMap,
            offset       = 0x00000000,
            numDmaLanes  = args.numLane,
            boardType    = args.boardType,
            # expand       = True,
        ))

        #self.add(pcie.TerminateQsfp(
        #    name         = 'GtRefClockMon',
        #    memBase      = self.memMap,
        #    offset       = 0x00800000,
        #    numRefClk    = 2,
        #    # expand       = True,
        #))

        for lane in range(args.numLane):
        #if True: # Enable for lane 0 only (test purpose)
            #lane = 0
            
            self.add(pgp.Pgp4AxiL(
                name    = 'Lane[{}]'.format(lane),
                offset  = (0x00800000+0x10000*lane),
                memBase = self.memMap,
                numVc   = args.numVc,
                writeEn = True,
                expand  = True,
            ))
            self.add(pgpapps.EyeGty(
                memBase = self.memMap,
                name   = 'Eye[{}]'.format(lane),
                offset = (0x00800000+0x10000*lane + 0x1000),
            ))
            
            for vc in range(args.numVc):
            #if True: # Enable for vc 0 only (test purpose)
                #vc = 0

                # Connect the SW PRBS Receiver module
                self.prbsRx[lane][vc] = pr.utilities.prbs.PrbsRx(
                    name   = f'SwPrbsRx[{lane}][{vc}]',
                    width  = args.prbsWidth,
                    expand = True,
                )
                self.dmaStream[lane][vc] >> self.prbsRx[lane][vc]
                self.add(self.prbsRx[lane][vc])

                # Connect the SW PRBS Transmitter module
                self.prbTx[lane][vc] = pr.utilities.prbs.PrbsTx(
                    name   = f'SwPrbsTx[{lane}][{vc}]',
                    width  = args.prbsWidth,
                    # expand = True,
                )
                self.prbTx[lane][vc] >> self.dmaStream[lane][vc]
                self.add(self.prbTx[lane][vc])
             
        # self.add(pyrogue.hardware.axi.AxiStreamDmaMon(
            # axiStreamDma = self.dmaStream[0][0],
            # expand       = True,
        # ))
            
        '''
        # Add PGP Core
        for lane in range(args.numLane):
            self.add(pgpapps.EyeGty(
                memBase = self.memMap,
                name   = "Eye[{}]".format(lane),
                offset = (0x08000000 + lane*0x00100000 + 0x1000),
            ))
            
            self.add(pgp.Pgp4AxiL(
                name    = f'Lane[{lane}]',
                offset  = (0x08000000 + lane*0x00100000),
                memBase = self.memMap,
                numVc   = args.numVc,
                writeEn = True,
                expand  = True,
            ))
        '''

    def start(self, **kwargs):
        super().start(**kwargs)
        print( f'Number of RX buffers = {self.dmaStream[0][0].getRxBuffCount()}' )

        for lane in range(args.numLane):
            for vc in range(args.numVc):
                # Connect the SW PRBS Transmitter module
                self.prbTx[lane][vc].txEnable.setDisp(True)
                #self.prbTx[0][0].txEnable.setDisp(True)
            
            self.Lane[lane].Ctrl.Loopback.set(0x00)
            self.Lane[lane].Ctrl.ResetRxPma.set(0x01)
            self.Lane[lane].Ctrl.ResetRx.set(0x01)
            self.Lane[lane].Ctrl.ResetRxPma.set(0x00)
            self.Lane[lane].Ctrl.ResetRx.set(0x00)
        
            self.Lane[lane].Ctrl.ResetEye.set(0x01)
            self.Lane[lane].Ctrl.ResetEye.set(0x00)
        
            # Step 1: Set ES_HORZ_OFFSET[11] and USE_PCS_CLK_PHASE_SEL in accordance with Table 1 and Table 2
            self.Eye[lane].ES_HORZ_OFFSET_CFG.set(0x01)
        
            # Step 2: Be ready for the scan:
            self.Eye[lane].ES_CONTROL.set(0x00)
            self.Eye[lane].ES_EYE_SCAN_EN.set(0x01)
            self.Eye[lane].ES_ERRDET_EN.set(0x01)
            self.Eye[lane].ES_PRESCALE.set(0x00)
        
            # Step 3: Reset the GT. The reset is not necessary if ES_EYE_SCAN_EN = 1b1 is set in HDL.
            self.Lane[lane].Ctrl.ResetRxPma.set(0x01)
            self.Lane[lane].Ctrl.ResetRx.set(0x01)
            self.Lane[lane].Ctrl.ResetRxPma.set(0x00)
        
            while self.Lane[lane].Ctrl.ResetRxPmaDone.get() == False:
                print('Wait for PMA rst done')
            
            self.Lane[lane].Ctrl.ResetRx.set(0x00)
            
       

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:
     pyrogue.pydm.runPyDM(serverList = root.zmqServer.address)
     #root.Eye[0].eyePlot(target=1e-8)
     root.Eye[0].bathtubPlot()

#################################################################
