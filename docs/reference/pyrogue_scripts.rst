PyRogue Scripts
===============

Each launcher script under :repo:`software/scripts/`
(``LoopbackTesting.py``, ``PgpTesting.py``, ``PgpMonitor.py``,
``HtspTesting.py``, ``HtspMonitor.py``, ``PrbsTesting.py``) parses its
command-line arguments, builds one of the ``pr.Root`` classes from the
``pgp_pcie_apps`` library, and starts the PyDM GUI.  All launchers
accept ``--dev`` (default ``/dev/datadev_0``) to select the card and
``--guiType`` (``PyDM`` by default, or ``None``) to run headless.  Only
``LoopbackTesting.py`` also accepts ``--type`` to select the backend
(``pcie`` or ``sim``).  ``updatePcieFpga.py`` is a standalone PROM
programming tool and ``setupLibPaths.py`` is a path helper.

Running Headless
----------------

``--guiType None`` starts the Root and its ZMQ server without opening
PyDM, then waits for Ctrl-C.  The ZMQ server binds ``127.0.0.1``, so
attach a GUI or a script on the same host (use an SSH tunnel from
elsewhere) using the port printed at startup:

.. code-block:: bash

   python LoopbackTesting.py --guiType None
   python -m pyrogue gui --server='localhost:9099'

.. code-block:: python

   import pyrogue.interfaces
   client = pyrogue.interfaces.VirtualClient(addr='localhost', port=9099)
   print(client.root.SwPrbsRx[0][0].rxCount.get())

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
       ``AxiStreamDmaV2Fifo`` monitors and per-lane ``PgpGtDrp`` GT DRP
       devices (both selected by ``boardType``)
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
     - ``AxiPcieCore``, FW ``SsiPrbsTx`` / ``SsiPrbsRx`` per VC,
       optional ``SyncTrigger``, SW PRBS per VC, and the DMA buffer
       monitors (``MigDmaBuffer``, ``BuffIbMon``) selected by
       ``boardType``
   * - ``SyncTrigger``
     - ``PrbsRoot``
     - ``pr.Device`` for the PrbsTester trigger generator at
       ``0x0088_0000``

Every Root takes its options as constructor keyword arguments (most
command-line flags map directly onto them; the Monitor scripts fix the
PRBS options) plus the standard ``pr.Root`` ``pollEn`` / ``initRead``
arguments:

.. code-block:: python

   import setupLibPaths
   import pgp_pcie_apps

   with pgp_pcie_apps.PgpRoot(dev='/dev/datadev_1', numLane=4, numVc=4) as root:
       print(root.AxiPcieCore.AxiVersion.ImageName.get())

Common Bootstrap
----------------

Every launcher script starts with:

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

Drives the DMA loopback path with a PRBS source and a PRBS sink
(``pyrogue.utilities.prbs.PrbsTx`` / ``PrbsRx``).  Use this against any ``DmaLoopback``
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
``AxiStreamDmaV2Fifo`` monitors when ``--boardType`` is
``XilinxAlveoU200``, ``XilinxKcu1500``, or ``XilinxVariumC1100`` (the
boards whose PGP targets have a DDR/HBM DMA buffer).  Defaults to 4
lanes and 4 VCs.
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
targets (e.g., ``XilinxVariumC1100PrbsTester``).  Pass ``--boardType``
to add the board's DMA buffer monitors: ``MigDmaBuffer[n]`` for
``XilinxKcu1500`` and ``XilinxVariumC1100``, plus ``BuffIbMon`` for
``XilinxVariumC1100``.

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

This sources a per-user miniforge install at
``/sdf/group/faders/users/$USER/miniforge3`` and activates its
``rogue_v6.15.0`` conda environment.

At PCDS / CDS:

.. code-block:: bash

   source software/cds_env_setup.sh

This activates the ``rogue_v6.5.0`` conda environment.

Outside SLAC, ensure ``rogue`` v6.5.0 or later is on ``PYTHONPATH`` and
that ``pyrogue.pydm`` is importable.
