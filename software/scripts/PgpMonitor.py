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
import setupLibPaths  # noqa: F401 (adds the python/ paths)

import argparse

import pyrogue
import pyrogue.pydm

import pgp_pcie_apps

#################################################################

# Convert str to bool
def argBool(s):
    return s.lower() in ['true', 't', 'yes', '1']

#################################################################

if __name__ == "__main__":

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
        choices  = [2, 3, 4],
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
        "--guiType",
        type     = str,
        required = False,
        default  = 'PyDM',
        help     = "Sets the GUI type (PyDM or None)",
    )

    # Get the arguments
    args = parser.parse_args()

    #################################################################

    # Monitor only: no SW PRBS, plus the DMA FIFO monitors
    with pgp_pcie_apps.PgpRoot(
        dev        = args.dev,
        numLane    = args.numLane,
        numVc      = args.numVc,
        version    = args.version,
        swRx       = False,
        swTx       = False,
        dmaFifoMon = True,
        boardType  = args.boardType,
        pollEn     = args.pollEn,
        initRead   = args.initRead,
    ) as root:

        ######################
        # Development PyDM GUI
        ######################
        if (args.guiType == 'PyDM'):
            pyrogue.pydm.runPyDM(serverList=root.zmqServer.address)

        #################
        # No GUI
        #################
        elif (args.guiType == 'None'):
            print("Running without GUI...")
            pyrogue.waitCntrlC()

        ####################
        # Undefined GUI type
        ####################
        else:
            raise ValueError("Invalid GUI type (%s)" % (args.guiType))

    #################################################################
