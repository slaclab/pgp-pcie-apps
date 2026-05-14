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

import setupLibPaths  # noqa: F401  (must be FIRST — wires sys.path via addLibraryPath)
import argparse
import sys

import rogue
import rogue.hardware.axi

import pyrogue as pr

import axipcie as pcie

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser(description='Headless QSFP/SFP I2C page sweep')

# Add arguments
parser.add_argument(
    "--dev",
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device (default: /dev/datadev_0)",
)

parser.add_argument(
    "--boardType",
    type     = str,
    required = False,
    default  = 'BittWareXupVv8Vu13p',
    help     = "PCIe card type (default: BittWareXupVv8Vu13p)",
)

parser.add_argument(
    "--transceiverClass",
    type     = str,
    required = False,
    default  = None,
    help     = "Comma-separated per-slot form-factor list (e.g. 'QSFP,QSFP,SFP,QSFP-DD'). Default None preserves pre-Phase-2 useSfp behavior.",
)

# Get the arguments
args = parser.parse_args()

# Split comma-separated form-factor string into a list; None passes through untouched.
xcvr_list = None
if args.transceiverClass is not None:
    xcvr_list = [tok.strip() for tok in args.transceiverClass.split(',')]

#################################################################


class MyRoot(pr.Root):
    def __init__(self, **kwargs):
        super().__init__(timeout=5.0, **kwargs)
        self.memMap = rogue.hardware.axi.AxiMemMap(args.dev)
        self.add(pcie.AxiPcieCore(
            memBase          = self.memMap,
            offset           = 0x00000000,
            boardType        = args.boardType,
            transceiverClass = xcvr_list,
        ))


#################################################################

def page_plan_for(slot_dev_class_name, slot_dev):
    """Return list of (page_label, [variable_paths_to_touch]) tuples per D-06.

    Hard-coded page sets (never walk __dict__) to avoid touching alarm-latch
    RemoteVariables that would falsely increment ErrorCount.
    """
    if slot_dev_class_name == 'Sfp':
        # SFF-8472: A0h (identity + vendor) + A2h (Diagnostics)
        return [
            ('A0h', ['VendorName', 'VendorPn', 'VendorSn', 'ManufactureDate']),
            ('A2h', ['Temperature', 'Vcc', 'TxBias', 'TxPower', 'RxPower']),
        ]
    if slot_dev_class_name == 'Qsfp':
        # SFF-8636: lower00 + upper00; upper01-03 only when Flat_mem == 0
        pages = [
            ('lower00', ['Identifier', 'Flat_mem', 'Data_Not_Ready', 'Temperature', 'Vcc']),
            ('upper00', ['UpperPage00h.VendorName',
                         'UpperPage00h.VendorPn',
                         'UpperPage00h.VendorSn',
                         'UpperPage00h.ManufactureDate']),
        ]
        try:
            if slot_dev.Flat_mem.value() == 0:
                pages.append(('upper03', ['UpperPage03h']))
        except Exception:
            pass
        return pages
    if slot_dev_class_name == 'QsfpDd':
        # CMIS: lower00 + upper00 (banked pages deferred to v2)
        return [
            ('lower00', ['Identifier', 'CmisRevision', 'Temperature', 'Vcc']),
            ('upper00', ['UpperPage00h.VendorName',
                         'UpperPage00h.VendorPn',
                         'UpperPage00h.VendorSn',
                         'UpperPage00h.ManufactureDate']),
        ]
    return []


def touch(node, dotted_path):
    """Walk dotted_path from node and call .get() on the leaf variable.

    _retryGet + RES-08 _pollWorker mask absorb retries and SLVERR underneath.
    This catch is belt-and-braces; the ErrorCount delta is the health signal.
    """
    obj = node
    for piece in dotted_path.split('.'):
        obj = getattr(obj, piece)
    try:
        obj.get()
    except Exception:
        pass


#################################################################

results = []   # rows: (slot, dev_class, page_label, err_delta, 'PASS'|'FAIL')
any_fail = False

with MyRoot() as root:
    for slot in range(4):
        slot_dev = root.AxiPcieCore.Qsfp[slot]
        dev_class = type(slot_dev).__name__

        # HW-03 mux serialization: enable exactly one slot at a time.
        slot_dev.enable.setDisp(True)
        try:
            for page_label, paths in page_plan_for(dev_class, slot_dev):
                pre = slot_dev.ErrorCount.value()
                for p in paths:
                    touch(slot_dev, p)
                post = slot_dev.ErrorCount.value()
                delta = post - pre
                pass_fail = (delta == 0)    # D-07 health signal
                if not pass_fail:
                    any_fail = True
                results.append((slot, dev_class, page_label, delta,
                                'PASS' if pass_fail else 'FAIL'))
        finally:
            slot_dev.enable.setDisp(False)

# stdout table (D-08) — no JSON sidecar in v1
print()
print(f"{'Slot':<6}{'Class':<10}{'Page':<10}{'ErrCnt Δ':<10}{'Result':<8}")
print('-' * 44)
for slot, cls, page, d, r in results:
    print(f"{slot:<6}{cls:<10}{page:<10}{d:<10}{r:<8}")
print()
sys.exit(1 if any_fail else 0)
