Run the PGP Test Suite
======================

Once a PGP target is built and flashed (or programmed via
:doc:`/how-to/program_with_updatepciefpga`), exercise the link with
``software/scripts/PgpTesting.py``.

Quick Start
-----------

.. code-block:: bash

   source software/setup_env_slac.sh   # rogue + pyrogue
   cd software/scripts
   python PgpTesting.py

``PgpTesting.py`` (:repo:`software/scripts/PgpTesting.py`) builds a
``pgp_pcie_apps.PgpRoot`` (:repo:`firmware/python/pgp_pcie_apps/_PgpRoot.py`)
containing:

* ``AxiPcieCore``: register tree at BAR0 (versions, monitors, board ID).
* ``Lane[n]``: PGP core status and control (``Pgp4AxiL``, ``Pgp3AxiL``,
  or ``Pgp2bAxi`` per ``--version``), plus ``PgpTxAxisMon[n]`` and
  ``PgpRxAxisMon[n]``.
* ``PgpGtDrp[n]``: GT transceiver DRP registers, added when
  ``--boardType`` is ``SlacPgpCardG4`` or ``XilinxKcu1500``
  (``surf.xilinx.Gthe3Channel``) or ``XilinxAlveoU200`` or
  ``XilinxVariumC1100`` (``Gtye4Channel``).
* ``SwPrbsRx[n][vc]`` / ``SwPrbsTx[n][vc]``: ``pyrogue.utilities.prbs``
  PRBS receiver and transmitter on each virtual channel.

It then launches the PyDM GUI exposing the live monitor tree.  Use
``--version`` (default ``4``) to select the PGP generation, and
``--numLane`` / ``--numVc`` to match the target.

What "Working" Looks Like
-------------------------

In the GUI:

- ``AxiPcieCore.AxiVersion.UpTimeCnt`` is incrementing.
- ``AxiPcieCore.AxiVersion.PCIE_HW_TYPE_G`` matches the board (e.g.,
  ``XilinxVariumC1100``).
- ``Lane[n].RxStatus.LinkReady`` shows ``True`` (PGP4; on PGP3 it is
  ``Lane[n].RxLocalLinkReady``).
- ``Lane[n].RxStatus.FrameErrorCnt`` and
  ``Lane[n].TxStatus.FrameErrorCnt`` are zero and not incrementing.
- ``SwPrbsRx[n][vc].rxErrors`` stays at zero.

Read-Only Monitoring
~~~~~~~~~~~~~~~~~~~~

For monitoring without driving traffic, use
``software/scripts/PgpMonitor.py``: the same ``PgpRoot`` with the PRBS
source/sink disabled.  With ``--boardType XilinxAlveoU200``,
``XilinxKcu1500``, or ``XilinxVariumC1100`` it also adds the
``AxiStreamDmaV2Fifo`` DMA buffer monitors.  Its defaults are
``--numLane 4 --numVc 4``.

Selecting a Card
~~~~~~~~~~~~~~~~

All scripts default to ``--dev /dev/datadev_0``.  Pass
``--dev /dev/datadev_<N>`` to target a different card.  Only
``LoopbackTesting.py`` supports the ``--type sim`` simulation backend
(see :doc:`/how-to/simulate_dma_loopback`).

For PRBS-Tester Targets
-----------------------

The PrbsTester targets (e.g., ``XilinxVariumC1100PrbsTester``) skip
the PGP optics and instead drive the DMA path with in-hardware PRBS
generators.  Use
``software/scripts/PrbsTesting.py``
(:repo:`software/scripts/PrbsTesting.py`) instead of ``PgpTesting.py``
for those targets, and pass ``--boardType`` (for example
``--boardType XilinxVariumC1100``) to include that board's DMA buffer
monitors.

For HTSP Targets
----------------

Use ``software/scripts/HtspTesting.py``
(:repo:`software/scripts/HtspTesting.py`) for the HTSP 100 Gbps targets,
or ``software/scripts/HtspMonitor.py`` for read-only monitoring.  They
follow the same PyDM-driven monitoring pattern with different RX/TX
monitor variables.
