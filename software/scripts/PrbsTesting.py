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

with test.PrbsRoot(
        dev = args.dev,
        sim = args.sim,
        numLanes = args.numLanes,
        prbsWidth = args.prbsWidth,
        numVc = args.numVc,
        loopback = args.loopback,
        pollEn=args.pollEn) as root:

    swRxDevices = root.find(typ=pr.utilities.prbs.PrbsRx)
    for rx in swRxDevices:
        rx.checkPayload.set(False)

    pyrogue.pydm.runPyDM(root=root)


#################################################################
