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
# Statistical eye scan of the PGP4 lanes, on the surf eye-scan runner
# (surf.xilinx.eyescan.runEyeScan): Status, Probe, Bathtub, Eye and Margin.
##############################################################################
import setupLibPaths  # noqa: F401 (adds the python/ paths)

import argparse
import sys

import surf.protocols.pgp  as pgp
import surf.xilinx.eyescan as es

import pgp_pcie_apps

#################################################################

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--dev",
        type     = str,
        required = False,
        default  = '/dev/datadev_0',
        help     = "path to device",
    )

    parser.add_argument(
        "--boardType",
        type     = str,
        required = False,
        default  = 'XilinxKcu1500',
        choices  = ['SlacPgpCardG4', 'XilinxKcu1500', 'XilinxVariumC1100'],
        help     = "define the type of PCIe card, used to select the GT DRP device. Options: [SlacPgpCardG4, XilinxKcu1500, XilinxVariumC1100]",
    )

    parser.add_argument(
        "--numLane",
        type     = int,
        required = False,
        default  = 8,
        help     = "# of DMA Lanes",
    )

    es.addEyeScanArguments(parser)
    parser.set_defaults(lanes='4-7', lineRate=6.25)
    args = parser.parse_args()

    # Checks the arguments and creates the run folder before the card is touched
    plan = es.prepareEyeScan(args, args.numLane)

    #################################################################

    # Idle PGP4 link, no SW PRBS traffic, no polling and no read at start
    with pgp_pcie_apps.PgpRoot(
        dev        = args.dev,
        numLane    = args.numLane,
        numVc      = 1,
        version    = 4,
        swRx       = False,
        swTx       = False,
        dmaFifoMon = False,
        boardType  = args.boardType,
        pollEn     = False,
        initRead   = False,
    ) as root:
        lanes = [es.EyeScanLane(lane, root.PgpGtDrp[lane], pgp.Pgp4EyeScanLink(root.Lane[lane]))
                 for lane in range(args.numLane)]
        return es.runEyeScan(
            args,
            plan,
            lanes,
            version   = root.AxiPcieCore.AxiVersion,
            extraMeta = {'traffic': f'{args.traffic} swRx=False swTx=False'},
        )

#################################################################

if __name__ == "__main__":
    sys.exit(main())
