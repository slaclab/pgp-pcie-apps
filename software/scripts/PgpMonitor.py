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

#rogue.Logging.setLevel(rogue.Logging.Debug)

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

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
    default  = 4,
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

# Get the arguments
args = parser.parse_args()

#################################################################

class MyRoot(pr.Root):
    def __init__(   self,
            name        = "pciServer",
            description = "DMA Loopback Testing",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset     = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = args.numLane,
            boardType   = args.boardType,
            expand      = True,
        ))

        # Add PGP Core
        for lane in range(args.numLane):
            if (args.version == 4):
                self.add(pgp.Pgp4AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000),
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    expand  = True,
                ))
            elif (args.version == 3):
                self.add(pgp.Pgp3AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000),
                    memBase = self.memMap,
                    numVc   = args.numVc,
                    writeEn = True,
                    expand  = False,
                ))
            else:
                self.add(pgp.Pgp2bAxi(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000 + 0x1000),
                    memBase = self.memMap,
                    expand  = False,
                ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpTxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x3000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpRxAxisMon[{lane}]'),
                offset      = (0x00800000 + lane*0x00010000 + 0x4000),
                numberLanes = args.numVc,
                memBase     = self.memMap,
                expand      = False,
            ))
        for lane in range(args.numLane):
            self.add(axi.AxiStreamDmaV2Fifo(
                name        = (f'AxiStreamDmaV2Fifo[{lane}]'),
                offset      = (0x0010_0000 + lane*0x100),
                memBase     = self.memMap,
                expand      = False,
            ))

#################################################################

with MyRoot(pollEn=args.pollEn, initRead=args.initRead) as root:
     pyrogue.pydm.runPyDM(root=root)

#################################################################
