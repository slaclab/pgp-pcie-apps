Directory Layout
================

The repository decomposes work into three top-level trees:

.. code-block:: text

   pgp-pcie-apps/
       firmware/
           Makefile               # Serial rebuild of the release targets
           releases.yaml          # ruckus release configuration
           common/                # Shared RTL by protocol
               pgp2b/
               pgp3/
               pgp4/
               htsp/
               PrbsTester/        # Common PRBS application
           python/
               pgp_pcie_apps/     # PyRogue Root classes and devices
           submodules/
               ruckus/            # TCL build system
               surf/              # SLAC RTL library
               axi-pcie-core/     # PCIe DMA + board support
           targets/               # One subdirectory per build target
               shared_config.mk   # PRJ_VERSION, RELEASE
               XilinxVariumC1100/
               XilinxKcu1500/
               ...
       software/
           scripts/               # PyRogue launchers + updatePcieFpga.py
           setup_env_slac.sh      # SLAC env activation
           cds_env_setup.sh       # PCDS/CDS env activation
       docs/                      # This documentation site

Key Directories
---------------

``firmware/targets/<Board>/<Target>/``
   A self-contained build unit for one ``(Board, Protocol, Rate)`` tuple.
   Contains ``hdl/<Target>.vhd`` (top-level entity), ``hdl/<Target>.xdc``
   (pin/timing constraints), ``ruckus.tcl`` (build script), ``Makefile``
   (per-target ``PRJ_PART``), and, where a PROM image is produced,
   ``vivado/promgen.tcl`` (PROM generation recipe).  A ``tb/`` testbench directory is present for some
   DmaLoopback targets (``XilinxVariumC1100``, ``XilinxKcu1500``,
   ``SlacPgpCardG4``).

``firmware/common/<proto>/hardware/<Board>/{core,rtl}/Hardware.vhd``
   Board-specific adapter for one protocol on one board.  Usually a thin
   wrapper over ``shared/rtl/<gtyUs+|gthUs>/Pgp[Gty]LaneWrapper`` (or
   ``htsp/shared/rtl/gtyUs+/HtspWrapper``).

``firmware/common/<proto>/shared/rtl/``
   Protocol-common lane logic: ``PgpLaneRx``, ``PgpLaneTx``, and the
   GT-family wrappers in ``gtyUs+/`` (UltraScale+) and ``gthUs/``
   (UltraScale).  HTSP has ``HtspRxFifo`` / ``HtspTxFifo`` and
   ``gtyUs+/`` only.

``firmware/common/PrbsTester/``
   In-hardware PRBS application: ``PrbsLane``, ``Hardware.vhd``, and
   timing constraints.  Used by the ``*PrbsTester`` targets.

``firmware/submodules/axi-pcie-core/``
   PCIe DMA + board management RTL and PyRogue device tree.  See its
   own documentation at https://slaclab.github.io/axi-pcie-core/.

``firmware/python/pgp_pcie_apps/``
   PyRogue library with one ``pr.Root`` per test flow (``PgpRoot``,
   ``HtspRoot``, ``LoopbackRoot``, ``PrbsRoot``) and the ``SyncTrigger``
   device.

``software/scripts/``
   PyRogue launchers that parse arguments, build a ``pgp_pcie_apps``
   Root, and start the PyDM GUI (or run headless with
   ``--guiType None``), plus ``setupLibPaths.py`` and the
   ``updatePcieFpga.py`` PROM tool; see :doc:`/reference/pyrogue_scripts`.

Build Outputs
-------------

ruckus splits build artifacts across two locations:

* **Working tree**: ``firmware/build/<TargetName>/``.  Contains
  ``<TargetName>_project.xpr``, ``<TargetName>_project.runs/synth_1/``
  and ``.../impl_1/``, checkpoints, and logs.  Gitignored.  On hosts
  with a ``/u1`` local disk, ruckus makes ``firmware/build`` a symlink
  to ``/u1/$USER/build``.
* **Image tree**: ``firmware/targets/<Board>/<Target>/images/``.
  Contains the final ``.bit`` and ``.mcs`` (plus ``.bit.gz`` /
  ``.mcs.gz`` when the ``*_GZIP`` variables are set).  Also gitignored;
  bitstreams are not committed but are shipped via the release
  pipeline.

Submodule Pinning
-----------------

``.gitmodules`` holds each submodule's path and URL; the pinned commit
is the gitlink SHA recorded at the submodule path.  The submodule version locks enforced by
``firmware/submodules/axi-pcie-core/shared/ruckus.tcl`` are:

* ``ruckus >= 4.24.2``
* ``surf >= 2.71.0``

Bypass via ``OVERRIDE_SUBMODULE_LOCKS=1`` for development only.
