Run an Eye Scan
===============

The GT eye scan measures how much margin a live PGP lane has: a horizontal
bathtub, a 2D statistical eye, or a margin summary that combines both.  The
scan code lives in the ``surf`` library (the ``EyeScan`` child of
``surf.xilinx.Gthe3Channel`` and ``surf.xilinx.Gtye4Channel``).  This
repository drives it in two ways: the headless command-line tool
``software/scripts/PgpEyeScan.py`` (:repo:`software/scripts/PgpEyeScan.py`) and the
``EyeScan`` node under each ``PgpGtDrp[n]`` of the PyDM tree.  It was
validated on the GTH transceivers of a KCU1500 and the GTY transceivers of a
Varium C1100 (see `Validation Scope`_).

Quick Start
-----------

.. code-block:: bash

   source software/setup_env_slac.sh   # rogue + pyrogue
   cd software/scripts

   # Read the eye-scan state of lanes 4-7 (read only, nothing is written)
   python PgpEyeScan.py --boardType XilinxKcu1500 --lanes 4-7 --mode Status

   # Margin summary of lanes 4-7, files go to a new run folder under ./scans
   python PgpEyeScan.py --boardType XilinxKcu1500 --lanes 4-7 --mode Margin --outDir ./scans

How It Works
------------

``PgpRoot`` (:repo:`firmware/python/pgp_pcie_apps/_PgpRoot.py`) adds one GT
DRP device per lane as ``PgpGtDrp[n]``.  The class comes from the
``GT_DRP_CLASS`` table, keyed by ``--boardType``: ``Gthe3Channel`` for
``SlacPgpCardG4`` and ``XilinxKcu1500``, ``Gtye4Channel`` for
``XilinxAlveoU200`` and ``XilinxVariumC1100``.  Every one of those classes
carries an ``EyeScan`` child, so ``PgpGtDrp[n].EyeScan`` exists whenever the
GT DRP device does.  Adding it does not touch the hardware, nothing polls, and
none of its variables is stored in a saved configuration YAML.

The scan needs a receiver that has just been reset, so ``PgpRoot`` registers a
reset hook for every PGP4 lane (``--version 4``, the default of the scripts):

* the reset is ``Lane[n].Ctrl.ResetRx``;
* the ready signal is ``Lane[n].RxStatus.PhyRxActive``, which must read True
  again after the pulse;
* every activation of the sampler pulses the reset once or more, and no other
  ``Pgp4AxiL`` bit is touched.

For PGP2b and PGP3 no hook is registered, so the default reset policy
refuses the scan (status ``NOT_ENABLED``).  The two sampler enables are left
set after a scan; every other register the scan changed is restored, also
after an abort or an error.

Headless Use
------------

``PgpEyeScan.py`` builds a ``PgpRoot`` for an idle PGP4 link (no software PRBS,
polling off, no read at start) and runs one mode on the selected lanes, one
lane at a time.  It takes ``--dev`` (default ``/dev/datadev_0``) and
``--boardType`` (``SlacPgpCardG4``, ``XilinxKcu1500`` or
``XilinxVariumC1100``, default ``XilinxKcu1500``), but not ``--guiType``: it
never starts PyDM.

.. code-block:: bash

   python PgpEyeScan.py --lanes 4-7 --mode Status    # read the eye-scan state, no write
   python PgpEyeScan.py --lanes 4-7 --mode Probe     # activate the sampler, report if it came alive
   python PgpEyeScan.py --lanes 4-7 --mode Bathtub   # two-sided horizontal bathtub
   python PgpEyeScan.py --lanes 4-7 --mode Eye       # 2D statistical eye
   python PgpEyeScan.py --lanes 4-7 --mode Margin    # eye plus the bathtubs through its centre, with summary

   # Another card, a Varium C1100
   python PgpEyeScan.py --boardType XilinxVariumC1100 --lanes 4-7 --mode Margin --outDir ./scans --tag c1100

Main flags and their defaults:

.. list-table::
   :header-rows: 1
   :widths: 22 14 64

   * - Flag
     - Default
     - Meaning
   * - ``--lanes``
     - ``4-7``
     - lanes to scan, for example ``4-7``, ``4,6`` or ``5``
   * - ``--numLane``
     - ``8``
     - number of DMA lanes of the image
   * - ``--mode``
     - ``Status``
     - ``Status``, ``Probe``, ``Bathtub``, ``Eye`` or ``Margin``
   * - ``--resetPolicy``
     - ``Auto``
     - ``Auto`` and ``Always`` reset the RX on every activation, ``Never`` only sets the enables
   * - ``--lineRate``
     - ``6.25``
     - line rate in Gb/s for the time estimate and the metadata; 0 makes the scan measure it, with a warning
   * - ``--berFloor``
     - by mode
     - BER every point must prove: ``1e-9`` for ``Bathtub``, ``1e-6`` for ``Eye`` and ``Margin``
   * - ``--bathtubFloor``
     - ``1e-9``
     - ``Margin``: floor of the bathtubs through the eye centre
   * - ``--targetBer``
     - ``1e-12``
     - BER the openings are extrapolated to
   * - ``--confidence``
     - ``0.95``
     - confidence of every bound
   * - ``--step``
     - ``1``
     - ``Bathtub``: spacing of the horizontal counts
   * - ``--horzStep``
     - ``2``
     - ``Eye`` and ``Margin``: horizontal spacing of the eye
   * - ``--vertStep``
     - ``4``
     - ``Eye`` and ``Margin``: vertical spacing of the eye
   * - ``--horzRange``
     - ``0``
     - ``Eye`` and ``Margin``: largest horizontal offset in counts, 0 for the full range
   * - ``--vertRange``
     - ``0``
     - ``Eye`` and ``Margin``: largest vertical offset in codes, 0 for the full range
   * - ``--equalizer``
     - ``dfe``
     - ``dfe`` or ``lpm``
   * - ``--outDir``
     - ``.``
     - folder that receives the run folder
   * - ``--tag``
     - empty
     - label appended to the run folder name
   * - ``--noPng true``
     - ``false``
     - skip the PNG plots
   * - ``--loopback``
     - not set
     - see `Loopback`_

The remaining flags (``--prescale``, ``--softCold``, ``--noResetHook``,
``--repeat``, ``--traffic``) are listed by ``python PgpEyeScan.py --help``.
``--noPng``, ``--softCold`` and ``--noResetHook`` take a value, ``true`` or
``false`` (for example ``--noPng true``), and any other value is refused.

Every ``Bathtub``, ``Eye``, ``Margin`` and ``Probe`` invocation creates one run
folder ``eyescan_<yyyymmdd_hhmmss>[_<tag>]`` under ``--outDir``.  It holds an
``.npz``, a ``.csv`` and (unless ``--noPng true``) the PNG plots of each lane
for Bathtub, Eye and Margin, and the ``.npz`` of each lane only for Probe;
nothing is overwritten.  Every mode shows a progress bar with the percent done and the estimated time
to completion: ``Bathtub``, ``Eye`` and ``Margin`` also show the scan stage,
``Probe`` counts the ``--repeat`` repetitions of each lane and ``Status`` the
lanes, and the rows of those two modes print once their bar closes.  When the
lanes are done the script prints one cross-lane summary table.  An opening followed by ``[E]`` is extrapolated to
``--targetBer``, ``[C]`` marks a clipped value that is only a lower bound, and
``[I]`` marks insufficient data: the value is the measured opening at the
bathtub floor, not an extrapolation.  An axis with no open position prints
``-`` in the table and "none (no position meets BER ...)" in the per-lane
opening lines.

The exit code is 0 when every requested lane ran and ended ``OK`` or
``CLOSED`` and every file was saved, and 2 when a lane ended in another
status, a save failed, or a stop ended the run before every lane ran.  The
first Ctrl-C stops the run: a running scan is aborted and its partial result
is saved, the registers are restored, no further lane is started, and the
table of the lanes that finished is still printed.  A second Ctrl-C forces the
exit.

Loopback
--------

``--loopback N`` (``N`` from 0 to 7) writes ``N`` to ``Lane[n].Ctrl.Loopback``
before the Bathtub, Eye or Margin scan of each lane and writes the previous
value back afterwards.  Status and Probe refuse the flag before the card is
touched.  Without the flag ``Ctrl.Loopback`` is never written.  Use it only on
a card you may take off its normal link; the examples on this page do not use
it.

Link Impact
-----------

Scanning does not touch the link; activating the sampler does:

* every RX reset or sync re-arm of an activation is a PHY re-init, so the PGP
  link goes down for about 0.05 to 0.5 s;
* setting ``ES_EYE_SCAN_EN`` and ``ES_ERRDET_EN`` on a running GTYE4 lane
  drops the link once;
* with ``--resetPolicy Never`` on a lane that is already enabled and in step,
  a Bathtub, Eye or Margin scan leaves ``LinkDownCnt`` and ``PhyRxInitCnt``
  unchanged (measured on GTYE4 at 6.25, 10.3125, 15.46875 and 25 Gb/s).

To scan during data taking, activate once with ``Auto`` or ``Always`` between
runs, then scan with ``Never``.  Frame or CRC errors in live traffic during a
``Never`` scan have not been checked yet.

PyDM Use
--------

Start the GUI with a board type, and with a line rate so the time estimate is
available:

.. code-block:: bash

   python PgpMonitor.py --boardType XilinxKcu1500 --numLane 8 --lineRate 6.25
   # or, with the PRBS source and sink
   python PgpTesting.py --boardType XilinxKcu1500 --numLane 8

``PgpTesting.py`` has no ``--lineRate``; set ``LineRateGbps`` on the node
instead.  Open ``PgpGtDrp[n].EyeScan`` and set:

* ``Mode``: ``Bathtub``, ``Eye`` or ``Margin``;
* the floors and steps (``EyeBerFloor``, ``BathtubBerFloor``, ``TargetBer``,
  ``Confidence``, ``HorzStep``, ``VertStep``), ``ResetPolicy``, ``Equalizer``,
  ``LineRateGbps``, ``SavePng`` and ``OutputDir``.

Press ``Start``; ``Stop`` ends the scan within a second and keeps the partial
result.  ``Progress``, ``Message`` and ``Running`` follow the scan, and
``Status``, ``HorzOpeningUI``, ``VertOpeningCodes``, ``BerAtCenter`` and
``ResultFile`` (the ``.npz`` of the last save) hold its outcome.
``EtaSeconds`` is NaN until the line rate is set or a scan has measured it.
None of these variables is saved in a configuration YAML.

Status Meanings
---------------

``OK``
   The scan completed and, for ``Eye`` and ``Margin``, the eye centre is open.

``CLOSED``
   The scan completed and found no opening, or the lane delivers no usable
   data.  Every activation, in Probe, Bathtub, Eye and Margin and whatever
   ``--step``, ``--horzStep`` or ``--horzRange``, checks the eye centre and then
   runs the sampler at both ends of the UI, where a live link shows its data
   transitions.  An eye-centre error counter that stays full after 12 RX
   resets, or no errors at both ends of the UI, ends the lane ``CLOSED`` with a
   warning that names both causes (the sampler is out of step with the data
   sampler, or the link is closed or unlocked), and the measured points are
   kept and saved.  A link drop during a scan repeats the eye-centre run once
   the link is back, because the PHY re-init behind the drop can leave the
   sampler out of step; a full error counter there also ends ``CLOSED`` with
   the same warning.  Under ``--resetPolicy Never`` an out-of-step lane is not
   reset to realign it, so it also ends ``CLOSED`` with that warning.

``UNLOCKED``
   The link dropped twice during the scan, did not come back within the hook
   timeout after a drop, or a run without a reset hook ended with no samples.

``NOT_ENABLED``
   The sampler could not be activated: no reset hook under ``Auto`` or
   ``Always``, a ``PhyRxActive`` that never returns, enables that do not read
   back set, or a sampler run that reached no END or counted no samples.

``TIMEOUT``
   A stopped run counted no samples, or the sampler did not return to idle,
   while ``ready`` read True (a stuck sampler).  A run that reaches the time
   limit after counting samples is stopped and its partial counts are used.

``ABORTED``
   Stop or Ctrl-C ended the scan; the partial result is saved.

``ERROR``
   An invalid parameter, a failed register restore, or an analysis that failed
   after the scan (the measured counts are kept and saved).

Validation Scope
----------------

Measured:

* GTH on a KCU1500 (image ``XilinxKcu1500Pgp4_6Gbps``) and GTY on a Varium
  C1100 (image ``XilinxVariumC1100Pgp4_6Gbps``), lanes 4 to 7, over the
  QSFP[1] fiber loopback on the host ``rdsrv403``, at 6.25 Gb/s.  The GTY
  comparison of the phase rule was also run at 10.3125, 15.46875 and
  25 Gb/s.
* After the last activation changes, lanes 4 to 7 were measured again.  The
  GTH openings stayed inside the recorded range.  The GTY openings were above
  that range on lanes 4, 5 and 7 and inside the allowed band on lane 6 only.
  That is reported as wider, not as a pass: the QSFP module was re-seated after
  the original battery, so its CDR state changed.
* QSFP[0] lanes 0 to 3 of both cards, with the QSFP module present and no
  fiber (the module and the missing fiber were not confirmed by hand), at
  6.25 Gb/s with default floors and grid:

  * KCU1500 (GTH): every mode ended ``CLOSED`` (Probe, Bathtub, Margin and
    Probe with ``--resetPolicy Never``).
  * Varium C1100 (GTY): Probe, Bathtub and Margin ended ``NOT_ENABLED``
    because the sampler of those lanes did not run; Probe with
    ``--resetPolicy Never`` ended ``CLOSED`` on lane 0 and ``NOT_ENABLED`` on
    lanes 1 to 3.

  The KCU1500 times were 1.06 s (Probe), 255.7 to 256.4 s (Bathtub) and 537.2
  to 620.7 s (Margin); the C1100 lanes ended in 0.56 to 3.15 s.  On the KCU1500
  lanes ``PhyRxActive`` read True and the sampler reached a full 65535-sample
  END while ``LinkReady`` was False, so a signal source on those lanes is not
  excluded.  Every lane finished inside the time bound fixed before the run,
  and every register was identical before and after the run apart from the two
  enable bits.  That bound left out the two runs at both ends of the UI, up to
  6 s per activation, which every activation of the current code adds, so the
  current worst case is 6 s higher in every mode.  A first run of the same
  checks failed (24 of 32 results) until the activation was fixed; the rerun
  passed all 32.

Not validated: GTX (``Gtxe2Channel``) and GTP (``Gtpe2Channel``) are not
supported yet and have no ``EyeScan`` child; no ``SlacPgpCardG4`` or
``XilinxAlveoU200`` card was measured; the evidence is one card per family;
the QSFP CDR state of the C1100 was never read back.

Example Output
--------------

Margin summary of the GTH lanes 4 to 7 of a KCU1500 (image
``XilinxKcu1500Pgp4_6Gbps``, 6.25 Gb/s), from ``PgpEyeScan.py --mode Margin``
with the ``File`` column removed:

.. code-block:: text

   Summary (E extrapolated, C clipped so a lower bound, I insufficient_data):
   Lane  Mode    Status  Horz UI    Vert codes  Open area  Offset UI/codes  LR asym  TB asym  BER at centre
   4     Margin  OK      0.766 [E]  172.0 [I]   152.250    -0.016/-10.0     -0.021   +0.038   BER < 2.6e-10 at 95%
   5     Margin  OK      0.752 [E]  136.0 [I]   113.375    +0.000/+2.0      -0.024   -0.013   BER < 2.6e-10 at 95%
   6     Margin  OK      0.719 [E]  80.0 [I]    70.438     -0.008/-2.0      -0.054   +0.013   BER < 2.6e-10 at 95%
   7     Margin  OK      0.717 [E]  81.0 [I]    65.562     +0.000/-4.0      -0.019   +0.006   BER < 2.6e-10 at 95%

The same for the GTY lanes 4 to 7 of a Varium C1100 (image
``XilinxVariumC1100Pgp4_6Gbps``, 6.25 Gb/s):

.. code-block:: text

   Summary (E extrapolated, C clipped so a lower bound, I insufficient_data):
   Lane  Mode    Status  Horz UI    Vert codes  Open area  Offset UI/codes  LR asym  TB asym  BER at centre
   4     Margin  OK      0.744 [E]  91.0 [I]    79.375     +0.000/-2.0      -0.058   +0.000   BER < 5.4e-10 at 95%
   5     Margin  OK      0.744 [E]  97.0 [I]    86.188     +0.000/+0.0      -0.027   +0.050   BER < 5.4e-10 at 95%
   6     Margin  OK      0.727 [E]  91.0 [I]    80.688     +0.000/-4.0      -0.060   +0.031   BER < 5.4e-10 at 95%
   7     Margin  OK      0.702 [E]  97.0 [I]    82.000     +0.000/+2.0      -0.028   -0.003   BER < 5.4e-10 at 95%

The horizontal opening is in UI, the vertical opening in codes, and the open
area in UI times codes.

Known Limitations
-----------------

Stated as measured on the lanes above:

* The vertical Q-scale fit gate (r2 of at least 0.95) fails at step 1 on
  every GTH and GTY lane that was measured, on at least one tail.  The vertical
  margin is therefore the measured opening at 1e-9 (``[I]``), not a 1e-12
  value.
* The vertical opening moves with the receiver adaptation state: between RX
  resets of one lane it differed by up to a factor of 2.6 (GTH lane 7, 228 and
  88 codes at the 1e-6 floor), and the horizontal opening moved by 7 to 15
  counts over 10 resets on the GTH lanes.  Compare settings within one RX
  reset.
* The GTYE4 ``defaultDivider`` is 2, which is right only at 6.25 Gb/s: the
  RXOUT_DIV decodes 1 at 10.3125, 15.46875 and 25 Gb/s.  It only affects the
  lane that ``EtaSeconds`` prices before the first scan.
* On the 25 Gb/s RS-FEC image ``PhyRxInitCnt`` rose by 22, 22, 7 and 26 more
  than the resets, re-arms and enable changes of the scan account for on
  lanes 4 to 7.  The cause is open.
* The QSFP[0] no-fiber result was taken with the default floors and grid on
  the code from before every scan ran the check at both ends of the UI (the
  scans then checked both ends only when their axis reached them).  That a lane
  without data now ends ``CLOSED`` on any step or range is shown by the
  emulated tests, not on a card.

Tests
-----

The eye-scan engine is covered by the emulated GTHE3 and GTYE4 suite in surf
(``tests/xilinx/eyescan``), which needs no FPGA.  From
``firmware/submodules/surf`` in the rogue environment:

.. code-block:: bash

   PYTHONPATH="$PWD/python" python -m pytest -q --noconftest tests/xilinx/eyescan

See Also
--------

* The surf eye-scan README, for the API, the result file formats and the
  per-family status:
  `python/surf/xilinx/README.md
  <https://github.com/slaclab/surf/blob/pre-release/python/surf/xilinx/README.md>`_
* :doc:`/how-to/run_pgp_testing`
* :doc:`/reference/pyrogue_scripts`
