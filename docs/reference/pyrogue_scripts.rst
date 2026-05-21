PyRogue Scripts
===============

Every script under :repo:`software/scripts/` is a standalone PyDM
launcher: it builds a ``pr.Root`` containing the relevant ``AxiPcieCore``
device tree, optionally wires up stream sources/sinks, and starts the
PyDM GUI.  All scripts accept a common ``--type`` flag selecting the
backend (``pcie`` or ``sim``).

Common Bootstrap
----------------

Every script starts with:

.. code-block:: python

   import setupLibPaths  # adds surf and axi-pcie-core python/ to sys.path

This MUST be the first import.  ``setupLibPaths.py``
(:repo:`software/scripts/setupLibPaths.py`) calls
``pr.addLibraryPath()`` for each submodule's Python tree.  Without it
``import axipcie`` and ``import surf`` fail.

Script Catalogue
----------------

LoopbackTesting.py
~~~~~~~~~~~~~~~~~~

:repo:`software/scripts/LoopbackTesting.py`

Drives the DMA loopback path with a PRBS source and a PRBS sink wired
through ``rogue.utilities.Prbs``.  Use this against any ``DmaLoopback``
target (e.g. ``XilinxVariumC1100DmaLoopback``).

.. code-block:: bash

   python LoopbackTesting.py            # /dev/datadev_0
   python LoopbackTesting.py --type sim # rogue TCP-socket backend

PgpTesting.py
~~~~~~~~~~~~~

:repo:`software/scripts/PgpTesting.py`

Builds a per-lane PRBS test against a PGP-protocol target (PGP2b, PGP3,
or PGP4).  See :doc:`/how-to/run_pgp_testing`.

PgpMonitor.py
~~~~~~~~~~~~~

:repo:`software/scripts/PgpMonitor.py`

Read-only monitoring variant of ``PgpTesting.py``.  Same PyDM GUI minus
the PRBS source/sink — useful when another application is already
driving traffic.

HtspTesting.py
~~~~~~~~~~~~~~

:repo:`software/scripts/HtspTesting.py`

HTSP 100 Gbps equivalent of ``PgpTesting.py``.  Use against
``Htsp100Gbps`` targets.

PrbsTesting.py
~~~~~~~~~~~~~~

:repo:`software/scripts/PrbsTesting.py`

Drives the in-hardware ``firmware/common/PrbsTester`` application
without involving an optical link.  Use against ``*PrbsTester``
targets (e.g. ``XilinxVariumC1100PrbsTester``).

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

Activates conda env ``rogue_v6.12.0``.

At PCDS / CDS:

.. code-block:: bash

   source software/cds_env_setup.sh

Activates conda env ``rogue_v6.5.0``.

Outside SLAC: ensure ``rogue`` >= 6.5.0 is on ``PYTHONPATH`` and that
``pyrogue.pydm`` is importable.
