PyRogue Scripts
===============

Every script under :repo:`software/scripts/` is a thin PyDM launcher:
it parses its command-line arguments, builds one of the ``pr.Root``
classes from the ``pgp_pcie_apps`` library, and starts the PyDM GUI.
All scripts accept ``--dev`` (default ``/dev/datadev_0``) to select the
card.  Only ``LoopbackTesting.py`` also accepts ``--type`` to select the
backend (``pcie`` or ``sim``).

The pgp_pcie_apps Library
-------------------------

The device trees live in :repo:`firmware/python/pgp_pcie_apps/`, one
module per ``pr.Root``, so they can be reused outside the launchers
(for example from an interactive session or a test script):

.. list-table::
   :header-rows: 1

   * - Class
     - Used by
     - Contents
   * - ``PgpRoot``
     - ``PgpTesting.py``, ``PgpMonitor.py``
     - ``AxiPcieCore``, per-lane PGP2b/PGP3/PGP4 core and RX/TX
       ``AxiStreamMonAxiL``, optional SW PRBS per VC, optional
       ``AxiStreamDmaV2Fifo`` monitors
   * - ``HtspRoot``
     - ``HtspTesting.py``, ``HtspMonitor.py``
     - ``AxiPcieCore``, two ``HtspAxiL`` lanes with RX/TX
       ``AxiStreamMonAxiL``, optional SW PRBS per VC
   * - ``LoopbackRoot``
     - ``LoopbackTesting.py``
     - ``AxiPcieCore``, ``GtRefClockMon``, SW PRBS TX/RX per VC over the
       DMA driver or the VCS TCP-socket backend
   * - ``PrbsRoot``
     - ``PrbsTesting.py``
     - ``AxiPcieCore``, MIG DMA buffer monitors, FW ``SsiPrbsTx`` /
       ``SsiPrbsRx`` per VC, optional ``SyncTrigger``, SW PRBS per VC
   * - ``SyncTrigger``
     - ``PrbsRoot``
     - ``pr.Device`` for the PrbsTester trigger generator at
       ``0x0088_0000``

Every Root takes its options as constructor keyword arguments (the
script's command-line flags map onto them one to one) plus the
standard ``pr.Root`` ``pollEn`` / ``initRead`` arguments:

.. code-block:: python

   import setupLibPaths
   import pgp_pcie_apps

   with pgp_pcie_apps.PgpRoot(dev='/dev/datadev_1', numLane=4, numVc=4) as root:
       print(root.AxiPcieCore.AxiVersion.ImageName.get())

Common Bootstrap
----------------

Every script starts with:

.. code-block:: python

   import setupLibPaths  # adds the surf, axi-pcie-core and pgp_pcie_apps python/ trees

This **must** be the first import.  ``setupLibPaths.py``
(:repo:`software/scripts/setupLibPaths.py`) calls
``pr.addLibraryPath()`` for ``firmware/python`` and each submodule's
Python tree.  Without it, ``import pgp_pcie_apps``, ``import axipcie``
and ``import surf`` fail.

Script Catalog
--------------

LoopbackTesting.py
~~~~~~~~~~~~~~~~~~

:repo:`software/scripts/LoopbackTesting.py`

Drives the DMA loopback path with a PRBS source and a PRBS sink wired
through ``rogue.utilities.Prbs``.  Use this against any ``DmaLoopback``
target (e.g., ``XilinxVariumC1100DmaLoopback``).

.. code-block:: bash

   python LoopbackTesting.py            # /dev/datadev_0
   python LoopbackTesting.py --type sim # rogue TCP-socket backend

PgpTesting.py
~~~~~~~~~~~~~

:repo:`software/scripts/PgpTesting.py`

Builds a per-lane PRBS test against a PGP-protocol target (PGP2b, PGP3,
or PGP4, selected with ``--version``).  See :doc:`/how-to/run_pgp_testing`.

PgpMonitor.py
~~~~~~~~~~~~~

:repo:`software/scripts/PgpMonitor.py`

Read-only monitoring variant of ``PgpTesting.py``: the same
``PgpRoot`` without the PRBS source/sink, plus the per-lane
``AxiStreamDmaV2Fifo`` monitors.  Defaults to 4 lanes and 4 VCs.
Useful when another application is already driving traffic.

HtspTesting.py
~~~~~~~~~~~~~~

:repo:`software/scripts/HtspTesting.py`

HTSP 100 Gbps equivalent of ``PgpTesting.py``.  Use against
``Htsp100Gbps`` targets.  On the bifurcated-PCIe image, ``HtspRoot``
hides and disables the lane owned by the other PCIe endpoint at
startup.

HtspMonitor.py
~~~~~~~~~~~~~~

:repo:`software/scripts/HtspMonitor.py`

Read-only monitoring variant of ``HtspTesting.py`` (``HtspRoot``
without the PRBS source/sink), analogous to ``PgpMonitor.py``.
Defaults to 4 VCs.

PrbsTesting.py
~~~~~~~~~~~~~~

:repo:`software/scripts/PrbsTesting.py`

Drives the in-hardware ``firmware/common/PrbsTester`` application
without involving an optical link.  Use against ``*PrbsTester``
targets (e.g., ``XilinxVariumC1100PrbsTester``).

updatePcieFpga.py
~~~~~~~~~~~~~~~~~

:repo:`software/scripts/updatePcieFpga.py`

Programs the SPI/BPI PROM with a ``.mcs`` file and rescans PCIe.  See
:doc:`/how-to/program_with_updatepciefpga`.

Environment Setup
-----------------

At SLAC S3DF (``rdsrv*``):

.. code-block:: bash

   source software/setup_env_slac.sh

This activates the ``rogue_v6.15.0`` conda environment.

At PCDS / CDS:

.. code-block:: bash

   source software/cds_env_setup.sh

This activates the ``rogue_v6.5.0`` conda environment.

Outside SLAC, ensure ``rogue`` v6.5.0 or later is on ``PYTHONPATH`` and
that ``pyrogue.pydm`` is importable.
