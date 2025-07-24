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
import time 

import pickle

import rogue.hardware.axi
import rogue.interfaces.stream

import pyrogue as pr
import pyrogue.pydm
import pyrogue.utilities.prbs

import axipcie            as pcie
import surf.xilinx        as xilinx
import surf.axi           as axi
import surf.protocols.pgp as pgp

import pgpapps            as pgpapps

import matplotlib.pyplot as plt
import numpy as np

import os
from datetime import datetime

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
    "--calibTx",
    type     = argBool,
    required = False,
    default  = False,
    help     = "Search for best tx configuration",
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
        super().__init__(timeout=20.0, name=name, description=description, **kwargs)

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

            #self.add(xilinx.Gtye4Channel(
            #    memBase = self.memMap,
            #    name   = 'DRP[{}]'.format(lane),
            #    offset = (0x00800000+0x10000*lane + 0x1000),
            #))



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

    def start(self, **kwargs):
        super().start(**kwargs)
        #print( f'Number of RX buffers = {self.dmaStream[0][0].getRxBuffCount()}' )

        
        for lane in range(args.numLane):
            for vc in range(args.numVc):
                # Connect the SW PRBS Transmitter module
                self.prbTx[lane][vc].txEnable.setDisp(True)
            
            self.Lane[lane].Ctrl.Loopback.set(0x00)#

            
            
            
        
       

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:
    root.AxiPcieCore.Qsfp[0].enable.set(True)
    root.AxiPcieCore.Qsfp[1].enable.set(True)

    #Check image
    imageName = root.AxiPcieCore.AxiVersion.ImageName.get()
    if imageName != 'XilinxVariumC1100Pgp4_15Gbps':
        print('Error: wrong FPGA version ({})'.format(imageName))

    #Disable QSFP CDR (Tx and Rx)
    root.AxiPcieCore.Qsfp[0].TxCdrEnable[0].set(False)
    root.AxiPcieCore.Qsfp[0].TxCdrEnable[1].set(False)
    root.AxiPcieCore.Qsfp[0].TxCdrEnable[2].set(False)
    root.AxiPcieCore.Qsfp[0].TxCdrEnable[3].set(False)
    root.AxiPcieCore.Qsfp[0].RxCdrEnable[0].set(False)
    root.AxiPcieCore.Qsfp[0].RxCdrEnable[1].set(False)
    root.AxiPcieCore.Qsfp[0].RxCdrEnable[2].set(False)
    root.AxiPcieCore.Qsfp[0].RxCdrEnable[3].set(False)

    root.AxiPcieCore.Qsfp[1].TxCdrEnable[0].set(False)
    root.AxiPcieCore.Qsfp[1].TxCdrEnable[1].set(False)
    root.AxiPcieCore.Qsfp[1].TxCdrEnable[2].set(False)
    root.AxiPcieCore.Qsfp[1].TxCdrEnable[3].set(False)
    root.AxiPcieCore.Qsfp[1].RxCdrEnable[0].set(False)
    root.AxiPcieCore.Qsfp[1].RxCdrEnable[1].set(False)
    root.AxiPcieCore.Qsfp[1].RxCdrEnable[2].set(False)
    root.AxiPcieCore.Qsfp[1].RxCdrEnable[3].set(False)

    #Create folder for measurements
    folder_name = datetime.now().strftime("%Y%m%d_%H%M%S_measurements")
    os.makedirs(folder_name)

    #Configuration
    linkConfig = [
        {'qsfpId': 0, 'qsfpLink': 0, 'lane': 0, 'fname': '{}/link-0.png'.format(folder_name)},
        {'qsfpId': 0, 'qsfpLink': 1, 'lane': 1, 'fname': '{}/link-1.png'.format(folder_name)},
        {'qsfpId': 0, 'qsfpLink': 2, 'lane': 2, 'fname': '{}/link-2.png'.format(folder_name)},
        {'qsfpId': 0, 'qsfpLink': 3, 'lane': 3, 'fname': '{}/link-3.png'.format(folder_name)},
        {'qsfpId': 1, 'qsfpLink': 0, 'lane': 4, 'fname': '{}/link-4.png'.format(folder_name)},
        {'qsfpId': 1, 'qsfpLink': 1, 'lane': 5, 'fname': '{}/link-5.png'.format(folder_name)},
        {'qsfpId': 1, 'qsfpLink': 2, 'lane': 6, 'fname': '{}/link-6.png'.format(folder_name)},
        {'qsfpId': 1, 'qsfpLink': 3, 'lane': 7, 'fname': '{}/link-7.png'.format(folder_name)},

    ]

    #Measurements
    links = []

    for lane in range(args.numLane):
        print('[Progress] Measurement for link {}'.format(lane))

        if args.calibTx:
            root.Lane[lane].Ctrl.TxDiffCtrl.set(0x10)
            root.Lane[lane].Ctrl.TxPreCursor.set(0)
            root.Lane[lane].Ctrl.TxPostCursor.set(0)

            time.sleep(2)

        #Reset link
        while True:
            root.Lane[lane].Ctrl.ResetRxPma.set(0x01)
            root.Lane[lane].Ctrl.ResetRx.set(0x01)
            root.Lane[lane].Ctrl.ResetTx.set(0x01)
            root.Lane[lane].Ctrl.ResetEye.set(0x01)
            root.Lane[lane].Ctrl.ResetEye.set(0x00)

            # Step 1: Set ES_HORZ_OFFSET[11] and USE_PCS_CLK_PHASE_SEL in accordance with Table 1 and Table 2
            root.Eye[lane].ES_HORZ_OFFSET_CFG.set(0x01)
        
            # Step 2: Be ready for the scan:
            root.Eye[lane].ES_CONTROL.set(0x00)
            root.Eye[lane].ES_EYE_SCAN_EN.set(0x01)
            root.Eye[lane].ES_ERRDET_EN.set(0x01)
            root.Eye[lane].ES_PRESCALE.set(0x00)
        
            # Step 3: Reset the GT. The reset is not necessary if ES_EYE_SCAN_EN = 1b1 is set in HDL.
            while root.Lane[lane].RxStatus.LinkReady.get() == True:
                pass

            root.Lane[lane].Ctrl.ResetRxPma.set(0x00)
        
            while root.Lane[lane].Ctrl.ResetRxPmaDone.get() == False:
                pass
            
            root.Lane[lane].Ctrl.ResetRx.set(0x00)
            root.Lane[lane].Ctrl.ResetTx.set(0x00)

            wdt = 0
            while root.Lane[lane].RxStatus.LinkReady.get() == False and wdt < 50:
                wdt += 1
                time.sleep(0.1)

            locked = root.Lane[lane].RxStatus.LinkReady.get()
            if locked:
                try:
                    ber = root.Eye[lane].bathtubPlot(fname = linkConfig[lane]['fname'])
                    if ber > 1e-2:
                        print('[Warning] Measurement error for link {} - reset link (BER: {:02e})'.format(lane, ber))
                        continue
                except:
                    ber = 0
            else:
                ber = 0

        
            
            TxDiffCtrl= root.Lane[lane].Ctrl.TxDiffCtrl.get()
            TxPreCursor = root.Lane[lane].Ctrl.TxPreCursor.get()
            TxPostCursor = root.Lane[lane].Ctrl.TxPostCursor.get()

            links.append(
                {
                    'id': lane,
                    'qsfpPn': root.AxiPcieCore.Qsfp[linkConfig[lane]['qsfpId']].VendorPn.get() if args.calibTx == False else 'unknown',
                    'qsfpManu': root.AxiPcieCore.Qsfp[linkConfig[lane]['qsfpId']].VendorName.get() if args.calibTx == False else 'unknown',
                    'qsfpRxPwr': root.AxiPcieCore.Qsfp[linkConfig[lane]['qsfpId']].RxPower[linkConfig[lane]['qsfpLink']].get() if args.calibTx == False else 0,
                    'txDiffCtrl': TxDiffCtrl,
                    'txPreCurs': TxPreCursor,
                    'txPostCurs': TxPostCursor,
                    'locked': locked,
                    'ber': ber
                }
            )

            print('[Done] Link {} (TxDiffCtrl: {}, TxPreCursor: {}, TxPostCursor: {}) {} (ber: {:02e})'.format(lane, TxDiffCtrl, TxPreCursor, TxPostCursor, 'locked' if locked else 'unlocked', ber))

            if args.calibTx:
                if TxPostCursor < 31:
                    TxPostCursor += 1

                    root.Lane[lane].Ctrl.TxDiffCtrl.set(TxDiffCtrl)
                    root.Lane[lane].Ctrl.TxPreCursor.set(TxPreCursor)
                    root.Lane[lane].Ctrl.TxPostCursor.set(TxPostCursor)

                    time.sleep(2)

                    continue

                elif TxPreCursor < 31:
                    TxPreCursor += 1
                    TxPostCursor = 0

                    root.Lane[lane].Ctrl.TxDiffCtrl.set(TxDiffCtrl)
                    root.Lane[lane].Ctrl.TxPreCursor.set(TxPreCursor)
                    root.Lane[lane].Ctrl.TxPostCursor.set(TxPostCursor)

                    time.sleep(2)

                    continue

                elif TxDiffCtrl < 0x19:
                    TxDiffCtrl += 1
                    TxPreCursor = 0
                    TxPostCursor = 0

                    root.Lane[lane].Ctrl.TxDiffCtrl.set(TxDiffCtrl)
                    root.Lane[lane].Ctrl.TxPreCursor.set(TxPreCursor)
                    root.Lane[lane].Ctrl.TxPostCursor.set(TxPostCursor)

                    time.sleep(2)

                    continue

            break

    #Save results
    with open("{}/data.pkl".format(folder_name), "wb") as f:
        pickle.dump(links, f)

    #Print results
    print('\n\nMeasurements:\n')

    print("{:<5} {:<20} {:<20} {:<12} {:<8} {:<20} {:<20} {:<20} {:<}".format("id", "qsfpPn", "qsfpManu", "qsfpRxPwr", "locked", "txDiffCtrl", 'txPreCurs', 'txPostCurs', "ber"))
    for link in links:
        print("{:<5} {:<20} {:<20} {:<12.2e} {:<8} {:<20} {:<20} {:<20} {:<.2e}".format(
            link['id'],
            link['qsfpPn'],
            link['qsfpManu'],
            link['qsfpRxPwr'],
            str(link['locked']),
            TxDiffCtrl, TxPreCursor, TxPostCursor,
            link['ber']
        ))

    #Display BER vs. RxPower
    plt.clf()
    plt.close()
    plt.figure()

    if args.calibTx:
        x = [link['txDiffCtrl'] for link in links]
        plt.xlabel("Tx diff. control")
        plt.title("BER vs Tx diff. control")

    else:
        x = [link['qsfpRxPwr'] for link in links]
        plt.xlabel("QSFP Rx Power (dBm)")
        plt.title("BER vs QSFP Rx Power")

    y = [link['ber'] for link in links]

    plt.scatter(x, y)
    plt.yscale('log') 
    plt.ylabel("BER")
    plt.grid(True, which="both", ls="--")
    plt.tight_layout()
    plt.show()



    #pyrogue.pydm.runPyDM(serverList = root.zmqServer.address)

    '''
     locked = []
     for TxDiffCtrl in range(0x10, 0x18): #(0,31):
         for TxPreCursor in range(0,31):
             for TxPostCursor in range(0,31):
                 root.Lane[0].Ctrl.TxDiffCtrl.set(TxDiffCtrl)
                 root.Lane[0].Ctrl.TxPreCursor.set(TxPreCursor)
                 root.Lane[0].Ctrl.TxPostCursor.set(TxPostCursor)
                 root.DRP[0].A_TXDIFFCTRL.set(TxDiffCtrl)

                 time.sleep(0.1)
                 root.AxiPcieCore.Qsfp[0].SoftReset()
                 time.sleep(0.2)
                 lol = root.AxiPcieCore.Qsfp[0].LatchedTxCdrLol.get()

                 print('[{}] Diff ({:02x}) Pre({:02x}) Post({:02x}) - {:02x}'.format(
                     'LOCKED' if lol != 0x0f else 'UNLOCKED',
                     TxDiffCtrl, TxPreCursor, TxPostCursor, lol))

                 if lol != 0x0f:
                     locked.append({
                         'Diff': TxDiffCtrl,
                         'Pre': TxPreCursor,
                         'Post': TxPostCursor,
                         'Lol': lol
                     })
     
    print(locked)
    '''

    #pyrogue.pydm.runPyDM(serverList = root.zmqServer.address)
    #root.Eye[0].bathtubPlot() #eyePlot(target = 1e-8) #bathtubPlot()

    '''
     plt.ion()
     fig, ax = plt.subplots()

     pwrArr = []
     berArr = []
     while True:
         for i in range(0,4):
             bers = root.Eye[i].bathtub()
             extrapolated = root.Eye[i].extrapolate(bers)
             pwr = root.AxiPcieCore.Qsfp[0].RxPower[i].get()
             #root.Eye[1].eyePlot(target=1e-8)
             pwrArr.append(pwr)
             berArr.append(extrapolated[54])
             print('[lane {}] Power ({}dbm) : {:.2e}'.format(i, pwr, extrapolated[54]))

             ax.clear()
             ax.scatter(pwrArr, berArr)

             plt.pause(0.5)

     plt.ioff() 
     plt.show()
    '''


#################################################################
