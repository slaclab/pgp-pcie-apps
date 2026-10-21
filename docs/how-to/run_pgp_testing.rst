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
``pr.Root`` containing:

* ``AxiPcieCore``: register tree at BAR0 (versions, monitors, board ID).
* Per-lane PGP RX/TX monitors and ``rogue.utilities.Prbs`` instances on
  each virtual channel.

It then launches the PyDM GUI exposing the live monitor tree.  Use
``--version`` (default ``4``) to select the PGP generation, and
``--numLane`` / ``--numVc`` to match the target.

What "Working" Looks Like
-------------------------

In the GUI:

- ``AxiPcieCore.AxiVersion.UpTimeCnt`` is incrementing.
- ``AxiPcieCore.AxiVersion.PCIE_HW_TYPE_G`` matches the board (e.g.,
  ``XilinxVariumC1100``).
- Per-lane ``PgpMonitor.RxLinkReady`` shows ``True``.
- ``PgpMonitor.RxFrameErrorCnt`` and ``TxFrameErrorCnt`` are zero (or
  the saturation count of the counters).
- PRBS error counters per VC stay at zero.

Read-Only Monitoring
~~~~~~~~~~~~~~~~~~~~

For monitoring without driving traffic, use
``software/scripts/PgpMonitor.py``: the same GUI without the PRBS
source/sink.

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
for those targets.

For HTSP Targets
----------------

Use ``software/scripts/HtspTesting.py``
(:repo:`software/scripts/HtspTesting.py`) for the HTSP 100 Gbps targets,
or ``software/scripts/HtspMonitor.py`` for read-only monitoring.  They
follow the same PyDM-driven monitoring pattern with different RX/TX
monitor variables.
