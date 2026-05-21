Directory Layout
================

The repository decomposes work into three top-level trees:

.. code-block:: text

   pgp-pcie-apps/
       firmware/
           common/                # Shared RTL by protocol
               pgp2b/
               pgp3/
               pgp4/
               htsp/
               PrbsTester/        # Common PRBS application
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
           scripts/               # PyRogue host-side scripts
           setup_env_slac.sh      # SLAC env activation
           cds_env_setup.sh       # PCDS/CDS env activation
       docs/                      # This documentation site

Key Directories
---------------

``firmware/targets/<Board>/<Target>/``
   A self-contained build unit for one ``(Board, Protocol, Rate)`` tuple.
   Contains ``hdl/<Target>.vhd`` (top-level entity), ``hdl/<Target>.xdc``
   (pin/timing constraints), ``ruckus.tcl`` (build script), ``Makefile``
   (per-target ``PRJ_PART``), and ``vivado/promgen.tcl`` (PROM generation
   recipe).  ``tb/`` is present for DmaLoopback variants.

``firmware/common/<proto>/hardware/<Board>/core/Hardware.vhd``
   Board-specific adapter for one protocol on one board.  A thin wrapper
   over ``firmware/common/<proto>/shared/rtl/Pgp[Gty]LaneWrapper`` (or
   ``HtspWrapper``).

``firmware/common/<proto>/shared/rtl/``
   Protocol-common lane logic — ``PgpLaneRx``, ``PgpLaneTx``, GT-family
   wrappers in ``gtyUs+/`` (UltraScale+) and ``gthUs/`` (UltraScale).

``firmware/common/PrbsTester/``
   In-hardware PRBS application: ``PrbsLane``, ``Hardware.vhd``, and
   timing constraints.  Used by the ``*PrbsTester`` targets.

``firmware/submodules/axi-pcie-core/``
   PCIe DMA + board management RTL and PyRogue device tree.  See its
   own documentation at https://slaclab.github.io/axi-pcie-core/.

``software/scripts/``
   PyRogue host-side test and monitoring scripts — see
   :doc:`/reference/pyrogue_scripts`.

Build Outputs
-------------

ruckus splits build artefacts across two locations:

* **Working tree** — ``firmware/build/<TargetName>/``.  Contains the
  Vivado ``.xpr`` project, ``runs/synth_1/``, ``runs/impl_1/``,
  checkpoints, logs.  Gitignored.
* **Image tree** — ``firmware/targets/<Board>/<Target>/images/``.
  Contains the final ``.bit`` and ``.mcs`` (or ``.bit.gz`` / ``.mcs.gz``
  when the GZIP env vars are set).  Also gitignored — bitstreams are
  not committed; they are shipped via the release pipeline.

Submodule Pinning
-----------------

Submodule pins live in ``.gitmodules`` plus the commit SHA recorded at
the submodule path.  The submodule version locks enforced by
``firmware/submodules/axi-pcie-core/shared/ruckus.tcl`` are:

* ``ruckus >= 4.24.2``
* ``surf >= 2.71.0``

Bypass via ``OVERRIDE_SUBMODULE_LOCKS=1`` for development only.
