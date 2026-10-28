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
import dataclasses
import datetime
import json
import math
import os
import re
import signal
import socket
import subprocess
import sys

import click
import numpy as np

import rogue.interfaces.memory as rim

import pgp_pcie_apps
from surf.xilinx.eyescan import (
    BathtubResult,
    EyeResult,
    EyeScanAborted,
    EyeScanError,
    EyeScanNotActive,
    EyeScanTimeout,
    EyeScanUnlocked,
    MarginResult,
    ResetPolicy,
    SaveOutcome,
    ScanControl,
    ScanStatus,
    formatBer,
    getFamily,
    metaJson,
)

#################################################################

# Top of the pgp-pcie-apps tree (this file lives in <top_level>/software/scripts/)
TOP_LEVEL = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', '..'))

# GT DRP words shared with the sampler, read as evidence before and after a run
GT_WORDS = (0x3C, 0x4F, 0x93, 0x97)

# Bits of GT word 0x3C that a run leaves set (ES_ERRDET_EN and ES_EYE_SCAN_EN)
ENABLE_BITS = 0x0300

# Status values that end a lane without failing the run
GOOD_STATUS = ('OK', 'CLOSED')

# Allowed characters of the file name tag
TAG_PATTERN = re.compile(r'[A-Za-z0-9_.-]{0,40}')

# Scan control of the lane being run and the stop request of the run, so Ctrl-C can end the run at any moment
ACTIVE = {'control': None, 'stop': False}

# Columns of the cross-lane table: result key and header
TABLE_COLUMNS = (
    ('lane',   'Lane'),
    ('mode',   'Mode'),
    ('status', 'Status'),
    ('horz',   'Horz UI'),
    ('vert',   'Vert codes'),
    ('area',   'Open area'),
    ('offset', 'Offset UI/codes'),
    ('lr',     'LR asym'),
    ('tb',     'TB asym'),
    ('ber',    'BER at centre'),
    ('file',   'File'),
)
TABLE_KEYS = tuple(key for key, _ in TABLE_COLUMNS)

#################################################################

# Convert str to bool, refusing every value except true, t, yes, 1, false, f, no and 0
def argBool(s):
    text = s.lower()
    if text in ('true', 't', 'yes', '1'):
        return True
    if text in ('false', 'f', 'no', '0'):
        return False
    raise argparse.ArgumentTypeError(f'expected true or false, got {s!r}')

# Convert a lane list such as 4-7, 4,6 or 5 into a sorted list of lane numbers
def parseLanes(text, numLane):
    lanes = set()
    for item in text.split(','):
        item = item.strip()
        if not item.isdigit():
            lo, sep, hi = item.partition('-')
            if not (sep and lo.strip().isdigit() and hi.strip().isdigit()):
                raise ValueError(f'Invalid lane list ({text})')
            first, last = int(lo), int(hi)
            if first > last:
                raise ValueError(f'Invalid lane list ({text})')
        else:
            first = last = int(item)
        lanes.update(range(first, last + 1))
    if not lanes or max(lanes) >= numLane:
        raise ValueError(f'Invalid lane list ({text})')
    return sorted(lanes)

# Build the argument parser
def buildParser():
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

    parser.add_argument(
        "--lanes",
        type     = str,
        required = False,
        default  = '4-7',
        help     = "lanes to scan, for example 4-7, 4,6 or 5",
    )

    parser.add_argument(
        "--mode",
        type     = str,
        required = False,
        default  = 'Status',
        choices  = ['Status', 'Probe', 'Bathtub', 'Eye', 'Margin'],
        help     = "Status: read the eye-scan state of each lane (read only). Probe: activate the sampler and report whether it came alive. Bathtub: two-sided horizontal bathtub. Eye: 2D statistical eye. Margin: 2D eye plus the horizontal and vertical bathtubs through its centre, with the margin summary",
    )

    parser.add_argument(
        "--softCold",
        type     = argBool,
        required = False,
        default  = False,
        help     = "return the sampler to the cold state (enables 0 and an RX reset) before the run",
    )

    parser.add_argument(
        "--resetPolicy",
        type     = str,
        required = False,
        default  = 'Auto',
        choices  = ['Auto', 'Always', 'Never'],
        help     = "when the run resets the RX: Auto and Always reset on every activation (no hook refuses the run), Never only sets the enables",
    )

    parser.add_argument(
        "--noResetHook",
        type     = argBool,
        required = False,
        default  = False,
        help     = "drop the RX reset hook before the run (negative check for a missing hook)",
    )

    parser.add_argument(
        "--repeat",
        type     = int,
        required = False,
        default  = 1,
        help     = "Probe mode: number of repetitions per lane (>= 1)",
    )

    parser.add_argument(
        "--berFloor",
        type     = float,
        required = False,
        default  = None,
        help     = "BER floor every point must prove, in (0, 1); defaults to 1e-9 for Bathtub and to the 1e-6 eye floor for Eye and Margin",
    )

    parser.add_argument(
        "--bathtubFloor",
        type     = float,
        required = False,
        default  = 1e-9,
        help     = "Margin mode: BER floor of the horizontal and vertical bathtubs through the eye centre, in (0, 1)",
    )

    parser.add_argument(
        "--targetBer",
        type     = float,
        required = False,
        default  = 1e-12,
        help     = "BER the opening is extrapolated to, in (0, 1)",
    )

    parser.add_argument(
        "--confidence",
        type     = float,
        required = False,
        default  = 0.95,
        help     = "confidence of the zero-error bound, in (0, 1)",
    )

    parser.add_argument(
        "--step",
        type     = int,
        required = False,
        default  = 1,
        help     = "Bathtub mode: spacing of the swept horizontal counts (>= 1, 1 measures every count)",
    )

    parser.add_argument(
        "--horzStep",
        type     = int,
        required = False,
        default  = 2,
        help     = "Eye and Margin modes: spacing of the horizontal counts of the eye (>= 1)",
    )

    parser.add_argument(
        "--vertStep",
        type     = int,
        required = False,
        default  = 4,
        help     = "Eye and Margin modes: spacing of the vertical codes of the eye (>= 1)",
    )

    parser.add_argument(
        "--horzRange",
        type     = int,
        required = False,
        default  = 0,
        help     = "Eye and Margin modes: largest horizontal offset of the eye in counts (0 = the full range of the lane)",
    )

    parser.add_argument(
        "--vertRange",
        type     = int,
        required = False,
        default  = 0,
        help     = "Eye and Margin modes: largest vertical offset of the eye in codes (0 = the full range of the family)",
    )

    parser.add_argument(
        "--prescale",
        type     = int,
        required = False,
        default  = None,
        help     = "fixed ES_PRESCALE (0 to 31) for every point instead of the adaptive ladder",
    )

    parser.add_argument(
        "--equalizer",
        type     = str,
        required = False,
        default  = 'dfe',
        choices  = ['dfe', 'lpm'],
        help     = "equalizer mode of the lane: dfe sums both UT_SIGN accumulations, lpm uses UT_SIGN 0",
    )

    parser.add_argument(
        "--lineRate",
        type     = float,
        required = False,
        default  = 6.25,
        help     = "line rate in Gb/s of the image for the time estimate and metadata; 0 = not defined, the scan then measures it with a warning",
    )

    parser.add_argument(
        "--outDir",
        type     = str,
        required = False,
        default  = '.',
        help     = "directory that receives the run folder eyescan_<yyyymmdd_hhmmss>[_<tag>] with the per-lane files",
    )

    parser.add_argument(
        "--tag",
        type     = str,
        required = False,
        default  = '',
        help     = "label appended to the run folder name ([A-Za-z0-9_.-], up to 40 characters)",
    )

    parser.add_argument(
        "--traffic",
        type     = str,
        required = False,
        default  = 'idle',
        help     = "traffic state of the link, recorded as metadata only",
    )

    parser.add_argument(
        "--loopback",
        type     = int,
        required = False,
        default  = None,
        help     = "write this GT loopback mode (0 to 7) to Ctrl.Loopback before the scan of each lane and restore the previous value afterwards; without it Loopback is never written; applies to Bathtub, Eye and Margin and is refused in Status and Probe",
    )

    parser.add_argument(
        "--noPng",
        type     = argBool,
        required = False,
        default  = False,
        help     = "do not render the PNG plots (Bathtub, Eye and Margin)",
    )

    return parser

# Set the BER floor default of the mode: 1e-9 for Bathtub, the 1e-6 eye floor for Eye and Margin
def resolveFloors(args):
    if args.berFloor is None:
        args.berFloor = 1e-6 if args.mode in ('Eye', 'Margin') else 1e-9

# Refuse an argument value the run cannot use before touching the hardware
def checkArgs(args):
    resolveFloors(args)
    if args.repeat < 1:
        raise ValueError(f'Invalid repeat ({args.repeat})')
    for name in ('berFloor', 'bathtubFloor', 'targetBer', 'confidence'):
        value = getattr(args, name)
        if not 0.0 < value < 1.0:
            raise ValueError(f'Invalid {name} ({value})')
    # 32 counts per RXOUT_DIV unit times the largest RXOUT_DIV (16)
    if not 1 <= args.step <= 512:
        raise ValueError(f'Invalid step ({args.step})')
    for name in ('horzStep', 'vertStep'):
        if getattr(args, name) < 1:
            raise ValueError(f'Invalid {name} ({getattr(args, name)})')
    for name in ('horzRange', 'vertRange'):
        if getattr(args, name) < 0:
            raise ValueError(f'Invalid {name} ({getattr(args, name)})')
    if args.loopback is not None and not 0 <= args.loopback <= 7:
        raise ValueError(f'Invalid loopback ({args.loopback})')
    if args.loopback is not None and args.mode in ('Status', 'Probe'):
        raise ValueError('Invalid combination (loopback applies to Bathtub, Eye and Margin)')
    if args.prescale is not None and not 0 <= args.prescale <= 31:
        raise ValueError(f'Invalid prescale ({args.prescale})')
    if args.lineRate < 0.0:
        raise ValueError(f'Invalid lineRate ({args.lineRate})')
    if TAG_PATTERN.fullmatch(args.tag) is None:
        raise ValueError(f'Invalid tag ({args.tag})')
    if args.softCold and args.noResetHook:
        raise ValueError('Invalid combination (softCold needs the RX reset hook, noResetHook removes it)')

# Create the output directory and prove it is a writable directory before the card is touched
def prepareOutDir(path):
    try:
        os.makedirs(path, exist_ok = True)
    except OSError as exc:
        raise ValueError(f'Invalid outDir ({path})') from exc
    if not os.path.isdir(path) or not os.access(path, os.W_OK | os.X_OK):
        raise ValueError(f'Invalid outDir ({path})')

# Create the run folder {outDir}/eyescan_{stamp}[_{tag}] exclusively, before the card is touched
def prepareRunFolder(args, now):
    name   = f'eyescan_{now.strftime("%Y%m%d_%H%M%S")}' + (f'_{args.tag}' if args.tag else '')
    folder = os.path.join(args.outDir, name)
    try:
        os.makedirs(folder, exist_ok = False)
    except OSError as exc:
        raise ValueError(f'Invalid run folder ({folder})') from exc
    return folder

# Refuse a Bathtub, Eye or Margin run a lane cannot take, with reads only, before any lane is written
def checkLanes(pairs, args):
    if args.mode not in ('Bathtub', 'Eye', 'Margin'):
        return
    for lane, gt in pairs:
        if 'EyeScan' not in gt.nodes:
            raise ValueError(f'Invalid lane {lane}: no EyeScan device')
        half = gt.EyeScan.readState().horzHalfRange
        if args.mode == 'Bathtub':
            if half is None or half < args.step:
                raise ValueError(f'Invalid step ({args.step}) for lane {lane}: half range is {half} counts')
            continue
        vertMax   = getFamily(gt.EyeScan.Family.value()).vsCodeMax
        horzRange = args.horzRange or half
        vertRange = args.vertRange or vertMax
        if half is None:
            raise ValueError(f'Invalid lane {lane}: the half range is not known')
        if horzRange > half:
            raise ValueError(f'Invalid horzRange ({args.horzRange}) for lane {lane}: half range is {half} counts')
        if vertRange > vertMax:
            raise ValueError(f'Invalid vertRange ({args.vertRange}) for lane {lane}: largest code is {vertMax}')
        if args.horzStep > horzRange:
            raise ValueError(f'Invalid horzStep ({args.horzStep}) for lane {lane}: range is {horzRange} counts')
        if args.vertStep > vertRange:
            raise ValueError(f'Invalid vertStep ({args.vertStep}) for lane {lane}: range is {vertRange} codes')

# Lane status text of an eye-scan error
def statusOf(exc):
    if isinstance(exc, EyeScanAborted):
        return ScanStatus.ABORTED.value
    if isinstance(exc, EyeScanTimeout):
        return ScanStatus.TIMEOUT.value
    if isinstance(exc, EyeScanNotActive):
        return ScanStatus.NOT_ENABLED.value
    if isinstance(exc, EyeScanUnlocked):
        return ScanStatus.UNLOCKED.value
    return ScanStatus.ERROR.value

#################################################################

# Read-only memory master for the raw evidence words
class RawWordReader(rim.Master):

    def __init__(self, slave):
        super().__init__()
        self._setSlave(slave)

    # Read one 32-bit word, never a write
    def read32(self, address):
        data = bytearray(4)
        tid  = self._reqTransaction(address, data, 4, 0, rim.Read)
        self._waitTransaction(tid)
        error = self._getError()
        if error:
            raise RuntimeError(f'Read of 0x{address:08X} failed ({error})')
        return int.from_bytes(data, 'little')

# Raw GT words 0x3C, 0x4F, 0x93, 0x97 (low 16 bits) and the Pgp4AxiL control word, as hex strings
def readRawWords(reader, gt, laneDev):
    words = {f'0x{word:02X}': f'0x{reader.read32(gt.address + (word << 2)) & 0xFFFF:04X}' for word in GT_WORDS}
    words['Ctrl'] = f'0x{reader.read32(laneDev.Ctrl.address + 0x00C):08X}'
    return words

# PGP link status and counters of one lane
def linkCounters(laneDev):
    rx = laneDev.RxStatus
    return {
        'LinkReady'    : int(rx.LinkReady.get()),
        'PhyRxInitCnt' : int(rx.PhyRxInitCnt.get()),
        'LinkDownCnt'  : int(rx.LinkDownCnt.get()),
    }

# Firmware image information of the card
def cardInfo(root):
    version = root.AxiPcieCore.AxiVersion
    for var in (version.BuildStamp, version.GitHash, version.FpgaVersion, version.UpTimeCnt):
        var.get()
    return {
        'buildStamp'  : version.BuildStamp.valueDisp(),
        'gitHash'     : version.GitHash.valueDisp(),
        'fpgaVersion' : version.FpgaVersion.valueDisp(),
        'upTimeCnt'   : int(version.UpTimeCnt.value()),
    }

# Version of the surf checkout in use, or unknown
def surfVersion():
    surfDir = os.path.join(TOP_LEVEL, 'firmware', 'submodules', 'surf')
    try:
        out = subprocess.run(
            ['git', '-C', surfDir, 'describe', '--tags', '--always', '--dirty'],
            capture_output = True,
            text           = True,
            timeout        = 10,
            check          = True,
        )
    except (OSError, subprocess.SubprocessError):
        return 'unknown'
    return out.stdout.strip() or 'unknown'

#################################################################

# Print the card information
def printCard(root):
    version = root.AxiPcieCore.AxiVersion
    for var in (version.BuildStamp, version.GitHash, version.UpTimeCnt):
        var.get()
    print(f'Card: {version.BuildStamp.valueDisp()}')
    print(f'GitHash={version.GitHash.valueDisp()} UpTimeCnt={version.UpTimeCnt.valueDisp()}')

# Read-only eye-scan state line of one lane
def runStatusLane(gt, laneDev, lane):
    eyeScan = gt.EyeScan
    state   = eyeScan.readState()
    rxStat  = laneDev.RxStatus
    width   = f'REFUSED({state.widthError})' if state.widthError is not None else str(state.bitsPerSample)
    rxDiv   = 'None' if state.rxOutDiv is None else str(state.rxOutDiv)
    rangeUi = 'None' if state.horzHalfRange is None else f'+-{state.horzHalfRange}'
    return (
        f'Lane[{lane}] '
        f'EyeScanEn={state.eyeScanEn} '
        f'ErrDetEn={state.errDetEn} '
        f'EsControl=0x{state.control:02X} '
        f'Status=0x{state.controlStatus:X}({state.controlStatusName}) '
        f'Samples={state.sampleCount} '
        f'Errors={state.errorCount} '
        f'W={width} '
        f'RxOutDiv={rxDiv} '
        f'Range={rangeUi} '
        f'PhyRxActive={rxStat.PhyRxActive.get()} '
        f'LinkReady={rxStat.LinkReady.get()} '
        f'Hook={eyeScan.RxResetHook.get()} '
        f'LineRate={eyeScan.LineRateGbps.value():g}'
    )

# Progress bar with the ETA for the Status and Probe modes, in the style of the surf scan bars
def makeBar(length, label):
    return click.progressbar(
        length       = length,
        label        = click.style(label, fg='green'),
        width        = 0,
        show_eta     = True,
        show_percent = True,
    )

# Format an optional time in seconds
def fmtTime(value):
    return 'n/a' if value is None else f'{value:.3f}s'

# Plain dict of a result dataclass
def asRecord(result):
    return None if result is None else json.loads(json.dumps(dataclasses.asdict(result), default=str))

# Record the state of a lane before a run
def beginLane(gt, laneDev, reader, meta):
    state = gt.EyeScan.readState()
    meta['W']              = state.bitsPerSample
    meta['RXOUT_DIV']      = state.rxOutDiv
    meta['softCold']       = []
    meta['rawBefore']      = readRawWords(reader, gt, laneDev)
    meta['countersBefore'] = linkCounters(laneDev)
    if not meta['countersBefore']['LinkReady']:
        print(f'Lane[{meta["lane"]}] WARNING: LinkReady is False, scanning anyway')

# Record the state of a lane after a run
def endLane(gt, laneDev, reader, meta):
    meta['rawAfter']      = readRawWords(reader, gt, laneDev)
    meta['countersAfter'] = linkCounters(laneDev)

# Run the optional soft re-cold and keep its record
def runSoftCold(gt, args, meta, control):
    if not args.softCold:
        return None
    try:
        record = asRecord(gt.EyeScan.softCold(control = control))
    except EyeScanError as exc:
        record = {'status': statusOf(exc), 'message': str(exc), 'stopped': None}
    meta['softCold'].append(record)
    return record

# Probe one lane args.repeat times and print one row per repetition
def runProbeLane(gt, laneDev, reader, args, meta):
    lane    = meta['lane']
    control = ScanControl()
    ACTIVE['control'] = control
    try:
        beginLane(gt, laneDev, reader, meta)
        rows  = []
        lines = []
        try:
            with makeBar(args.repeat, f'PgpGtDrp[{lane}] Probe:') as bar:
                for rep in range(1, args.repeat + 1):
                    before = readRawWords(reader, gt, laneDev)
                    soft   = runSoftCold(gt, args, meta, control)
                    if soft is not None and 'status' in soft:
                        after = readRawWords(reader, gt, laneDev)
                        rows.append({
                            'lane'       : lane,
                            'rep'        : rep,
                            'softCold'   : 'failed',
                            'policy'     : args.resetPolicy,
                            'status'     : soft['status'],
                            'eyeScanEn'  : 0,
                            'errDetEn'   : 0,
                            'statusBefore': 0,
                            'statusAfter': 0,
                            'samples'    : 0,
                            'reset'      : False,
                            'sawFall'    : False,
                            'tFall'      : None,
                            'tReady'     : None,
                            'elapsed'    : 0.0,
                            'message'    : soft['message'],
                            'rawBefore'  : before,
                            'rawAfter'   : after,
                        })
                        lines.append(f'Lane[{lane}] rep={rep} soft re-cold failed: status={soft["status"]} msg={soft["message"]}')
                        break
                    result = gt.EyeScan.probe(resetPolicy = ResetPolicy(args.resetPolicy), control = control)
                    after  = readRawWords(reader, gt, laneDev)
                    if soft is None:
                        softText = 'off'
                    else:
                        softText = 'stopped' if soft['stopped'] else 'still_active'
                    row = {
                        'lane'       : lane,
                        'rep'        : rep,
                        'softCold'   : softText,
                        'policy'     : result.policy.value,
                        'status'     : result.status.value,
                        'eyeScanEn'  : result.eyeScanEnReadback,
                        'errDetEn'   : result.errDetEnReadback,
                        'statusBefore': result.statusBefore,
                        'statusAfter': result.statusAfter,
                        'samples'    : result.sampleCount,
                        'reset'      : result.resetCalled,
                        'sawFall'    : result.sawFall,
                        'tFall'      : result.tFall,
                        'tReady'     : result.tReady,
                        'elapsed'    : result.elapsed,
                        'message'    : result.message,
                        'rawBefore'  : before,
                        'rawAfter'   : after,
                    }
                    rows.append(row)
                    lines.append(
                        f'Lane[{lane}] rep={rep} softCold={softText} policy={row["policy"]} status={row["status"]} '
                        f'enables={result.eyeScanEnReadback}/{result.errDetEnReadback} '
                        f'statusBefore=0x{result.statusBefore:X} statusAfter=0x{result.statusAfter:X} '
                        f'samples={result.sampleCount} reset={"yes" if result.resetCalled else "no"} '
                        f'sawFall={result.sawFall} tFall={fmtTime(result.tFall)} tReady={fmtTime(result.tReady)} '
                        f'elapsed={result.elapsed:.3f}s msg={result.message}'
                    )
                    bar.update(1)
                    if control.aborted or ACTIVE['stop']:
                        break
        finally:
            # The rows print once the bar is closed, so they never mix with its redraw
            for line in lines:
                print(line)
        endLane(gt, laneDev, reader, meta)
        meta['activation'] = rows
        return rows
    finally:
        ACTIVE['control'] = None

# Run the engine call of the mode on one lane
def measureLane(gt, args, control):
    common = dict(
        confidence    = args.confidence,
        equalizer     = args.equalizer,
        resetPolicy   = ResetPolicy(args.resetPolicy),
        fixedPrescale = args.prescale,
        control       = control,
        progressBar   = True,
    )
    grid = dict(
        horzStep  = args.horzStep,
        vertStep  = args.vertStep,
        horzRange = args.horzRange or None,
        vertRange = args.vertRange or None,
    )
    if args.mode == 'Bathtub':
        return gt.EyeScan.runBathtub(floor = args.berFloor, step = args.step, targetBer = args.targetBer, **common)
    if args.mode == 'Eye':
        return gt.EyeScan.runEye(floor = args.berFloor, **grid, **common)
    return gt.EyeScan.runMargin(floor = args.berFloor, bathtubFloor = args.bathtubFloor, targetBer = args.targetBer, **grid, **common)

# Scan one lane in Bathtub, Eye or Margin mode, save the result in finally and print its summary; returns (outcome, saved)
def runScanLane(gt, laneDev, reader, args, meta, folder):
    lane     = meta['lane']
    control  = ScanControl()
    previous = None
    outcome  = None
    saved    = None
    ACTIVE['control'] = control
    try:
        beginLane(gt, laneDev, reader, meta)
        soft = runSoftCold(gt, args, meta, control)
        if soft is not None and 'status' in soft:
            print(f'Lane[{lane}] soft re-cold failed: status={soft["status"]} msg={soft["message"]}')
            outcome = {'status': soft['status'], 'message': soft['message']}
        else:
            # Loopback is only written on request and the previous value is written back in finally
            if args.loopback is not None:
                previous = int(laneDev.Ctrl.Loopback.get())
                meta['loopback'] = {'requested': args.loopback, 'previous': previous}
                laneDev.Ctrl.Loopback.set(args.loopback)
            outcome = measureLane(gt, args, control)
    finally:
        try:
            if previous is not None:
                laneDev.Ctrl.Loopback.set(previous)
        finally:
            try:
                endLane(gt, laneDev, reader, meta)
            finally:
                # The result is saved before anything is printed and while a Ctrl-C only requests a stop
                try:
                    if isinstance(outcome, (BathtubResult, EyeResult, MarginResult)):
                        saved = gt.EyeScan.save(
                            outcome,
                            outDir      = folder,
                            png         = (not args.noPng) and outcome.status is not ScanStatus.ABORTED,
                            extraMeta   = meta,
                            surfVersion = meta['surfVersion'],
                        )
                finally:
                    ACTIVE['control'] = None
    printSaved(lane, saved)
    if isinstance(outcome, BathtubResult):
        printBathtubSummary(lane, outcome)
    elif isinstance(outcome, EyeResult):
        printEyeSummary(lane, outcome)
    elif isinstance(outcome, MarginResult):
        printMarginSummary(lane, outcome)
    if not isinstance(outcome, dict):
        printRawWords(lane, meta)
        for text in outcome.meta.get('warnings', []):
            print(f'Lane[{lane}] WARNING: {text}')
    return outcome, saved

# Print the files a lane saved and the failures of the save
def printSaved(lane, saved):
    if saved is None:
        return
    for path in (saved.npzPath, saved.csvPath, *saved.pngPaths):
        if path:
            print(f'Lane[{lane}] saved {path}')
    for text in saved.errors:
        print(f'Lane[{lane}] ERROR save failed: {text}')
    for text in saved.pngErrors:
        print(f'Lane[{lane}] WARNING {text}')

# Text of a BER: a zero-error point is a bound, never zero
def fmtBer(ber, bound):
    if not math.isnan(ber):
        return f'{ber:.3e}'
    if not math.isnan(bound):
        return f'< {bound:.2g}'
    return 'n/a'

# Text of one tail fit
def fmtFit(lane, fit):
    if fit.sigma is None:
        return f'Lane[{lane}] {fit.side} fit: ok={fit.ok} points={fit.nPoints} decades={fit.decades:.2f} reason={fit.reason}'
    return (
        f'Lane[{lane}] {fit.side} fit: ok={fit.ok} sigma={fit.sigma:.4f} UI mu={fit.mu:.4f} UI '
        f'r2={fit.r2:.3f} points={fit.nPoints} decades={fit.decades:.2f}' + (f' reason={fit.reason}' if fit.reason else '')
    )

# Print the bathtub text summary of one lane
def printBathtubSummary(lane, result):
    meta       = result.meta
    confidence = meta['confidence']
    points     = int(result.horzCounts.size)
    print(
        f'Lane[{lane}] bathtub status={result.status.value} W={meta["bitsPerSample"]} RxOutDiv={meta["rxOutDiv"]} '
        f'points={points} linkDrops={result.linkDrops} elapsed={meta["elapsed"]:.1f}s msg={result.message}'
    )

    if result.openingAtFloorUI is None:
        print(f'Lane[{lane}] opening at floor {meta["floor"]:g}: none (no position meets the floor) (measured)')
    else:
        print(f'Lane[{lane}] opening at floor {meta["floor"]:g}: {result.openingAtFloorUI:.4f} UI (measured)')

    if result.extrapolated:
        print(f'Lane[{lane}] opening at {result.targetBer:g}: {result.openingAtTargetUI:.4f} UI (extrapolated)')
    else:
        reasons = '; '.join(f'{fit.side}: {fit.reason}' for fit in (result.leftFit, result.rightFit) if not fit.ok and fit.reason)
        print(f'Lane[{lane}] opening at {result.targetBer:g}: insufficient_data ({reasons})')
    print(fmtFit(lane, result.leftFit))
    print(fmtFit(lane, result.rightFit))

    if points:
        centre = int(np.argmin(np.abs(result.horzCounts)))
        print(
            f'Lane[{lane}] centre count {int(result.horzCounts[centre])}: BER '
            f'{fmtBer(result.ber[centre], result.berUpper[centre])}'
            + (f' at {confidence * 100:g}%' if result.isBound[centre] else '')
        )
    else:
        print(f'Lane[{lane}] centre: no points measured')

    cmp = result.utComparison
    if cmp is None:
        print(f'Lane[{lane}] UT_SIGN comparison: not available')
    else:
        print(
            f'Lane[{lane}] UT_SIGN comparison at count {cmp["horz"]} prescale {cmp["prescale"]}: '
            f'UT0 errors={cmp["errors0"]} bits={cmp["bits0"]} BER={cmp["ber0"]:.3e}, '
            f'UT1 errors={cmp["errors1"]} bits={cmp["bits1"]} BER={cmp["ber1"]:.3e}'
        )

    print(f'Lane[{lane}] count   errUT0   errUT1           bits pre BER')
    for i in range(points):
        print(
            f'Lane[{lane}] {int(result.horzCounts[i]):5d} {int(result.errors[0, i]):8d} {int(result.errors[1, i]):8d} '
            f'{int(result.bits[:, i].sum()):14d} {int(result.prescale[i]):3d} '
            f'{fmtBer(result.ber[i], result.berUpper[i])}'
        )

# Print whether the raw GT words kept their values over the run of a lane
def printRawWords(lane, meta):
    before, after = meta.get('rawBefore'), meta.get('rawAfter')
    if before is None or after is None:
        return
    shared = all(before[key] == after[key] for key in ('0x4F', '0x93', '0x97'))
    word3c = (int(before['0x3C'], 16) & ~ENABLE_BITS) == (int(after['0x3C'], 16) & ~ENABLE_BITS)
    ctrl   = before['Ctrl'] == after['Ctrl']
    print(
        f'Lane[{lane}] raw words: 0x4F/0x93/0x97 {"unchanged" if shared else "CHANGED"}, '
        f'0x3C {"unchanged except bits 9:8" if word3c else "CHANGED"}, '
        f'Ctrl {"unchanged" if ctrl else "CHANGED"}'
    )

# Text of a number that may be missing
def fmtNum(value, spec):
    return '-' if value is None else format(value, spec)

# Text of one reported opening: its value, how it was obtained and whether it is only a lower bound
def fmtOpening(value, source, clipped, insufficient, digits, unit, floor, target):
    if value is None and source == 'closed':
        return f'none (no position meets BER {floor:g})'
    if value is None:
        return 'insufficient_data' if insufficient else 'none (no position meets the floor)'
    text = f'{value:.{digits}f} {unit} at BER {(target if source == "extrapolated" else floor):g} ({source})'
    if clipped:
        text += ', clipped at the scan range (lower bound)'
    if insufficient:
        text += ', extrapolation insufficient_data'
    return text

# Print the common first line of an Eye or Margin lane
def printGridHeader(lane, kind, eye, result):
    meta = eye.meta
    print(
        f'Lane[{lane}] {kind} status={result.status.value} W={meta["bitsPerSample"]} RxOutDiv={meta["rxOutDiv"]} '
        f'grid={eye.horzAxis.size}x{eye.vertAxis.size} measured={int(eye.measured.sum())}/{eye.measured.size} '
        f'linkDrops={result.linkDrops} elapsed={result.meta["elapsed"]:.1f}s msg={result.message}'
    )

# Print the eye text summary of one lane
def printEyeSummary(lane, result):
    meta       = result.meta
    centre     = result.centre
    confidence = meta['confidence']
    printGridHeader(lane, 'eye', result, result)
    if centre is None:
        print(f'Lane[{lane}] opening at floor {meta["floor"]:g}: none (no position on the vertical-0 row meets the floor) (measured)')
        return
    print(
        f'Lane[{lane}] opening at floor {meta["floor"]:g}: {centre.horzOpeningUI:.4f} UI'
        + (' (clipped, lower bound)' if centre.clippedH else '')
        + f' by {centre.vertOpeningCodes:.1f} codes'
        + (' (clipped, lower bound)' if centre.clippedV else '')
        + ' (measured)'
    )
    print(f'Lane[{lane}] centre offset: {centre.offsetUI:+.4f} UI ({centre.horz:+.1f} counts), {centre.offsetCodes:+.1f} codes')
    at = (centre.row, centre.column)
    print(f'Lane[{lane}] centre point: ' + formatBer(float(result.ber[at]), float(result.berUpper[at]), bool(result.isBound[at]), confidence))

# Print the margin text summary of one lane
def printMarginSummary(lane, result):
    summary = result.summary
    printGridHeader(lane, 'margin', result.eye, result)
    print(f'Lane[{lane}] {summary.text}')
    print(
        f'Lane[{lane}] horizontal opening: '
        + fmtOpening(summary.horzOpeningUI, summary.horzOpeningSource, summary.clippedH, summary.insufficientDataH,
                     4, 'UI', summary.bathtubFloor, summary.targetBer)
    )
    print(
        f'Lane[{lane}] vertical opening: '
        + fmtOpening(summary.vertOpeningCodes, summary.vertOpeningSource, summary.clippedV, summary.insufficientDataV,
                     1, 'codes', summary.bathtubFloor, summary.targetBer)
    )
    print(f'Lane[{lane}] centre offset: {fmtNum(summary.offsetUI, "+.4f")} UI, {fmtNum(summary.offsetCodes, "+.1f")} codes')
    print(
        f'Lane[{lane}] open area at BER {summary.eyeFloor:g}: {fmtNum(summary.openAreaUiCodes, ".4f")} UI x codes '
        f'({fmtNum(summary.openPoints, "d")} points), asymmetry LR {fmtNum(summary.asymmetryLR, "+.3f")} TB {fmtNum(summary.asymmetryTB, "+.3f")}'
    )
    print(f'Lane[{lane}] centre point: {summary.berAtCenterText}')

# Text of a reported value with its flags: E extrapolated, C clipped, I insufficient_data
def fmtFlagged(value, digits, extrapolated, clipped, insufficient):
    flags = ('E' if extrapolated else '') + ('C' if clipped else '') + ('I' if insufficient else '')
    text  = fmtNum(value, f'.{digits}f')
    return f'{text} [{flags}]' if flags else text

# Text of the BER at the bathtub count nearest 0
def bathtubCentreBer(result):
    if not result.horzCounts.size:
        return '-'
    centre = int(np.argmin(np.abs(result.horzCounts)))
    return formatBer(float(result.ber[centre]), float(result.berUpper[centre]), bool(result.isBound[centre]), result.meta['confidence'])

# One row of the cross-lane table
def summaryRow(lane, mode, outcome, saved):
    row = dict.fromkeys(TABLE_KEYS, '-')
    row['lane'] = str(lane)
    row['mode'] = mode
    statuses    = outcomeStatuses(outcome)
    bad         = [status for status in statuses if status not in GOOD_STATUS]
    row['status'] = (bad or statuses)[0]
    if isinstance(outcome, BathtubResult):
        opening = outcome.openingAtTargetUI if outcome.extrapolated else outcome.openingAtFloorUI
        row['horz'] = fmtFlagged(opening, 3, outcome.extrapolated, False, outcome.insufficientData)
        row['ber']  = bathtubCentreBer(outcome)
    elif isinstance(outcome, EyeResult) and outcome.centre is not None:
        centre = outcome.centre
        at     = (centre.row, centre.column)
        row['horz']   = fmtFlagged(centre.horzOpeningUI, 3, False, centre.clippedH, False)
        row['vert']   = fmtFlagged(centre.vertOpeningCodes, 1, False, centre.clippedV, False)
        row['offset'] = f'{centre.offsetUI:+.3f}/{centre.offsetCodes:+.1f}'
        row['ber']    = formatBer(float(outcome.ber[at]), float(outcome.berUpper[at]), bool(outcome.isBound[at]), outcome.meta['confidence'])
    elif isinstance(outcome, MarginResult):
        summary = outcome.summary
        row['horz']   = fmtFlagged(summary.horzOpeningUI, 3, summary.extrapolatedH, summary.clippedH, summary.insufficientDataH)
        row['vert']   = fmtFlagged(summary.vertOpeningCodes, 1, summary.extrapolatedV, summary.clippedV, summary.insufficientDataV)
        row['area']   = fmtNum(summary.openAreaUiCodes, '.3f')
        row['offset'] = '-' if summary.offsetUI is None else f'{summary.offsetUI:+.3f}/{summary.offsetCodes:+.1f}'
        row['lr']     = fmtNum(summary.asymmetryLR, '+.3f')
        row['tb']     = fmtNum(summary.asymmetryTB, '+.3f')
        row['ber']    = summary.berAtCenterText
    if saved is not None and saved.npzPath:
        row['file'] = os.path.basename(saved.npzPath)
    return row

# Print one row per lane with the flags E (extrapolated), C (clipped) and I (insufficient_data)
def printSummaryTable(rows):
    widths = {key: max(len(title), *(len(row[key]) for row in rows)) for key, title in TABLE_COLUMNS}
    print('Summary (E extrapolated, C clipped so a lower bound, I insufficient_data):')
    print('  '.join(title.ljust(widths[key]) for key, title in TABLE_COLUMNS).rstrip())
    for row in rows:
        print('  '.join(row[key].ljust(widths[key]) for key, _ in TABLE_COLUMNS).rstrip())

#################################################################

# Arrays of a Probe run: one per row field across the repetitions
def probeArrays(rows):
    def numbers(key):
        return np.array([math.nan if row[key] is None else row[key] for row in rows], dtype=float)
    return {
        'rep'          : np.array([row['rep'] for row in rows], dtype=np.int64),
        'softCold'     : np.array([row['softCold'] for row in rows], dtype=str),
        'policy'       : np.array([row['policy'] for row in rows], dtype=str),
        'status'       : np.array([row['status'] for row in rows], dtype=str),
        'eyeScanEn'    : np.array([row['eyeScanEn'] for row in rows], dtype=np.int64),
        'errDetEn'     : np.array([row['errDetEn'] for row in rows], dtype=np.int64),
        'statusBefore' : np.array([row['statusBefore'] for row in rows], dtype=np.int64),
        'statusAfter'  : np.array([row['statusAfter'] for row in rows], dtype=np.int64),
        'samples'      : np.array([row['samples'] for row in rows], dtype=np.int64),
        'reset'        : np.array([row['reset'] for row in rows], dtype=bool),
        'sawFall'      : np.array([row['sawFall'] for row in rows], dtype=bool),
        'tFall'        : numbers('tFall'),
        'tReady'       : numbers('tReady'),
        'elapsed'      : numbers('elapsed'),
        'message'      : np.array([row['message'] for row in rows], dtype=str),
    }

# File name of one lane of one run, built only from validated values
def npzPath(outDir, stamp, mode, lane, tag):
    name = f'eyescan_{stamp}_{mode.lower()}_lane{int(lane)}' + (f'_{tag}' if tag else '') + '.npz'
    return os.path.join(outDir, name)

# Base metadata of one lane of one run
def laneMeta(args, lane, info, version, now):
    return {
        'lane'         : lane,
        'mode'         : args.mode,
        'tag'          : args.tag,
        'timestamp'    : now.isoformat(timespec = 'seconds'),
        'stamp'        : now.strftime('%Y%m%d_%H%M%S'),
        'host'         : socket.gethostname(),
        'equalizer'    : args.equalizer,
        'resetPolicy'  : args.resetPolicy,
        'noResetHook'  : args.noResetHook,
        'repeat'       : args.repeat,
        'floor'        : args.berFloor,
        'bathtubFloor' : args.bathtubFloor,
        'confidence'   : args.confidence,
        'targetBer'    : args.targetBer,
        'step'         : args.step,
        'horzStep'     : args.horzStep,
        'vertStep'     : args.vertStep,
        'horzRange'    : args.horzRange,
        'vertRange'    : args.vertRange,
        'fixedPrescale': args.prescale,
        'lineRate'     : args.lineRate,
        'loopback'     : None,
        'traffic'      : f'{args.traffic} swRx=False swTx=False',
        'firmware'     : info,
        'surfVersion'  : version,
    }

# Write the npz of a Probe lane into the run folder; the numbers of the metadata stay numbers
def saveProbeLane(folder, args, meta, rows):
    saved = SaveOutcome()
    path  = npzPath(folder, meta['stamp'], args.mode, meta['lane'], args.tag)
    try:
        np.savez(path, **probeArrays(rows), meta = metaJson(meta))
        saved.npzPath = path
    except OSError as exc:
        saved.errors.append(f'npz: {type(exc).__name__}: {exc}')
    return saved

# Final status texts of a lane outcome: Probe rows, a lane failure or a result
def outcomeStatuses(outcome):
    if isinstance(outcome, list):
        return [row['status'] for row in outcome]
    if isinstance(outcome, dict):
        return [outcome['status']]
    return [outcome.status.value]

# True when a stop was requested or a lane ended ABORTED, so the run ends after the lane
def stopAfterLane(statuses):
    return ACTIVE['stop'] or any(status == ScanStatus.ABORTED.value for status in statuses)

# Record the stop request and abort the running scan if any; a second Ctrl-C raises KeyboardInterrupt
def onSigint(signum, frame):
    if ACTIVE['stop']:
        raise KeyboardInterrupt
    ACTIVE['stop'] = True
    control = ACTIVE['control']
    if control is not None and not control.aborted:
        control.abort()
        print('Stop requested: restoring the registers (Ctrl-C again to force)')
    else:
        print('Stop requested: the run ends after this lane (Ctrl-C again to force)')

#################################################################

# Run the selected mode on every lane; returns the exit code
def main():
    args = buildParser().parse_args()

    # Validate the arguments and create the run folder before touching the hardware
    lanes = parseLanes(args.lanes, args.numLane)
    checkArgs(args)
    folder = None
    if args.mode != 'Status':
        prepareOutDir(args.outDir)
        folder = prepareRunFolder(args, datetime.datetime.now().astimezone())

    #################################################################

    failed = False

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
        lineRate   = args.lineRate,
        pollEn     = False,
        initRead   = False,
    ) as root:

        printCard(root)

        if (args.mode == 'Status'):
            lines = []
            with makeBar(len(lanes), 'Status:') as bar:
                for lane in lanes:
                    lines.append(runStatusLane(root.PgpGtDrp[lane], root.Lane[lane], lane))
                    bar.update(1)
            for line in lines:
                print(line)

        else:
            # Reads only: a refused run writes nothing to any lane
            try:
                checkLanes([(lane, root.PgpGtDrp[lane]) for lane in lanes], args)
            except ValueError:
                os.rmdir(folder)
                raise

            print(f'Run folder: {folder}')
            reader  = RawWordReader(root.memMap)
            info    = cardInfo(root)
            version = surfVersion()
            signal.signal(signal.SIGINT, onSigint)

            # Lanes run one at a time; the table of the lanes that finished prints even after an abort
            rows = []
            try:
                for lane in lanes:
                    gt      = root.PgpGtDrp[lane]
                    laneDev = root.Lane[lane]
                    meta    = laneMeta(args, lane, info, version, datetime.datetime.now().astimezone())
                    if args.noResetHook:
                        gt.EyeScan.clearRxReset()

                    if args.mode == 'Probe':
                        outcome = runProbeLane(gt, laneDev, reader, args, meta)
                        saved   = saveProbeLane(folder, args, meta, outcome)
                        printSaved(lane, saved)
                    else:
                        outcome, saved = runScanLane(gt, laneDev, reader, args, meta, folder)

                    rows.append(summaryRow(lane, args.mode, outcome, saved))
                    statuses = outcomeStatuses(outcome)
                    failed   = failed or (saved is not None and bool(saved.errors)) or any(status not in GOOD_STATUS for status in statuses)

                    # A stop request ends the run, the lane above already restored its registers
                    if stopAfterLane(statuses):
                        # A stop before the last requested lane means lanes were skipped
                        failed = failed or lane != lanes[-1]
                        break
            finally:
                if rows:
                    printSummaryTable(rows)

    #################################################################

    return 2 if failed else 0

#################################################################

if __name__ == "__main__":
    sys.exit(main())
