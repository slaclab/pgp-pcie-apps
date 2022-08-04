##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
import time
from array import *
import sqlite3

import setupLibPaths
import sys
import argparse
import math

import pgp_pcie_apps.PrbsTester as test
import surf.protocols.ssi as ssi

import rogue
import rogue.hardware.axi
import rogue.interfaces.stream

import pyrogue as pr
import pyrogue.pydm
import pyrogue.utilities.prbs
import pyrogue.interfaces.simulation

##############################
# reads data from hardware 
# then saves the data to 
# SQLite3 database
##############################
def readData(
    root, 
    dbCon, 
    iter,  
    enableLanes, 
    vcPerLane, 
    currRate, 
    currLength
    ):
    
    # read data from devices
    hwData = readHardwareData(root)

    # print data to console
    for rows in hwData:
        print(rows)
    print("////////////////////////////////////////////////////////")

    # store data with SQL
    with dbCon:

        for data in hwData:
            dbCon.execute("INSERT INTO raw_data (iteration_num, set_num_lanes, set_num_vc, set_rate, set_packet_length, lane, channel, tx_frame_rate, tx_frame_rate_max, tx_frame_rate_min, tx_bandwidth, tx_bandwidth_max, tx_bandwidth_min, rx_frame_rate, rx_bandwidth) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                            (iter, enableLanes, vcPerLane, data[2], 2**currLength, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9]))

##############################
# read all the desired data
# from the hardware into a list
##############################
def readHardwareData(root):

    # initialize variables
    hwData = [[]]
    vcCount = 0
    totalBW = 0
    totalFR = 0

    # iterate through active lanes
    for ln in range(args.numLanes):

        # iterate through active channels
        for rg in range(args.numVc):
            if root.Hardware.Lane[ln].PrbsTx[rg].TxEn.get():

                # read data
                hwData[vcCount].append(ln)
                hwData[vcCount].append(rg)

                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].FrameRate.get())
                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].FrameRateMax.get())
                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].FrameRateMin.get())

                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].Bandwidth.get())
                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].BandwidthMax.get())
                hwData[vcCount].append(root.Hardware.Lane[ln].TxMon.Ch[rg].BandwidthMin.get())

                hwData[vcCount].append(root.SwPrbsRx[ln][rg].rxRate.get())
                hwData[vcCount].append(root.SwPrbsRx[ln][rg].rxBw.get()*8e-6)

                totalBW += root.Hardware.Lane[ln].TxMon.Ch[rg].Bandwidth.get()
                totalFR += root.Hardware.Lane[ln].TxMon.Ch[rg].FrameRate.get()

                # extend list and increment counter
                hwData.append([])
                vcCount += 1

    #store agregates
    hwData[vcCount].append(-1)
    hwData[vcCount].append(-1)

    hwData[vcCount].append(totalFR)
    hwData[vcCount].append(totalFR)
    hwData[vcCount].append(totalFR)

    hwData[vcCount].append(totalBW)
    hwData[vcCount].append(totalBW)
    hwData[vcCount].append(totalBW)

    hwData[vcCount].append(-1)
    hwData[vcCount].append(-1)

    return hwData

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
    "--fileName",
    "-o",
    type     = str,
    required = True,
    default  = 'junk',
    help     = "file name for output file",
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

parser.add_argument(
    "--maxLanes",
    type     = int,
    required = False,
    default  = 0,
    help     = "Max # of Active DMA Lanes for Collection",
)

parser.add_argument(
    "--maxSize",
    type     = int,
    required = False,
    default  = 0,
    help     = "Max Pcket Length for Collection",
)

parser.add_argument(
    "--noRx",
    type     = bool,
    required = False,
    default  = False,
    help     = "No Rx's present",
)

parser.add_argument(
    "--noTx",
    type     = bool,
    required = False,
    default  = False,
    help     = "No Tx's present",
)

# Get the arguments
args = parser.parse_args()

#################################################################

with test.PrbsRoot(
    dev = args.dev, 
    sim = args.sim, 
    numLanes = args.numLanes, 
    prbsWidth = args.prbsWidth, 
    numVc = args.numVc, 
    no_rx = args.noRx,
    no_tx = args.noTx,
    loopback = args.loopback) as root:
    
    # connect to database file
    dbCon = sqlite3.connect(args.fileName)

    # create statment to generate table
    stmt = """
    CREATE TABLE IF NOT EXISTS raw_data (
                id INTEGER PRIMARY KEY,
                iteration_num INTEGER,
                set_num_lanes INTEGER,
                set_num_vc INTEGER,
                set_rate INTEGER,
                set_packet_length INTEGER,
                lane INTEGER,
                channel INTEGER,
                tx_frame_rate FLOAT,
                tx_frame_rate_max FLOAT,
                tx_frame_rate_min FLOAT,
                tx_bandwidth FLOAT,
                tx_bandwidth_max FLOAT,
                tx_bandwidth_min FLOAT,
                rx_frame_rate FLOAT,
                rx_bandwidth FLOAT
                );
    """

    dbCon.executescript(stmt)
    
    swRxDevices = root.find(typ=pr.utilities.prbs.PrbsRx)
    for rx in swRxDevices:
        rx.checkPayload.set(False)

    iter = 0

    # set rate to maximum
    root.SetAllPeriods(0)

    # iterate through frame sizes
    for currLength in range(1,22):

        print(f"packet length: {2**currLength}")

        # adjust lengths
        root.SetAllPacketLengths(2**currLength)

        #   loop through lanes
        for enableLanes in range(1, args.numLanes+1):

            print(f"lanes enabled: {enableLanes}")

            #   loop through channels
            for enableChannels in range(0, args.numVc+1):


                print(f"channels enabled: {enableChannels}")

                # enable channels
                root.EnableChannels([enableLanes, enableChannels])

                # let data settle
                time.sleep(2.0)

                # reset data
                root.PurgeData()

                # allow time for data to be collected
                time.sleep(2.0)

                # read and save data
                readData(root = root, 
                dbCon = dbCon, 
                iter = iter, 
                enableLanes = enableLanes, 
                vcPerLane = 2**enableChannels, 
                currRate = 0, 
                currLength = currLength
                )

                iter += 1

    print("****************************************************")
    print("data collection completed!")
    print("****************************************************")
    pyrogue.pydm.runPyDM(root=root)


#################################################################
