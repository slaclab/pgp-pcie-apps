Makefile Targets
================

The ruckus Makefile chain provides a small set of PHONY targets that
all per-target ``Makefile``\s inherit via
``include $(TOP_DIR)/submodules/ruckus/system_vivado.mk``.

Per-Target ``make`` Entry Points
---------------------------------

From inside ``firmware/targets/<Board>/<Target>/``:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Command
     - Effect
   * - ``make``
     - Default target.  Runs synthesis + implementation + ``write_bitstream``
       + ``write_cfgmem`` for the PROM image.  Produces
       ``images/<Target>-<version>.bit`` and ``images/<Target>-<version>.mcs``.
   * - ``make bit``
     - Same as ``make`` but stops at ``.bit`` (no MCS).
   * - ``make prom``
     - Default — explicit name; alias for ``make``.
   * - ``make pdi``
     - Versal-class targets only — produces a ``.pdi`` instead of ``.bit``.
   * - ``make gui``
     - Open the existing Vivado project in interactive mode.  Use after a
       prior batch ``make`` to inspect timing reports, debug a failing run,
       or place debug probes.
   * - ``make sim``
     - Launch Vivado simulator with the target's testbench
       (``tb/*Tb.vhd``).  Only present where a ``tb/`` directory exists.
   * - ``make clean``
     - Delete ``firmware/build/<Target>/`` and ``images/``.
   * - ``make ip``
     - Generate/regenerate Vivado IP from ``.xci`` source.

Per-Target ``Makefile`` Variables
----------------------------------

Each target's ``Makefile`` (e.g.
:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/Makefile`)
exports a small set of variables that drive the ruckus inclusion:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Variable
     - Meaning
   * - ``PRJ_PART``
     - Xilinx part number.  Required.  Per-board constant —
       e.g. ``XCU55N-FSVH2892-2L-E`` for VariumC1100, ``xcku115-flvb2104-2-e``
       for KCU1500.
   * - ``PARALLEL_SYNTH``
     - Parallel-synthesis worker count.  Most targets use 8; some heavy
       targets set 1 to reduce peak memory.
   * - ``TOP_DIR``
     - Path to ``firmware/`` from the target dir.  Set to
       ``$(abspath $(PWD)/../../..)`` — required because the target
       sits three levels below ``firmware/``.
   * - ``RELEASE``
     - Inherited from ``firmware/targets/shared_config.mk``
       (default: ``pgp_pcie_apps``).  Used by the release pipeline.
   * - ``PRJ_VERSION``
     - Inherited from ``firmware/targets/shared_config.mk``
       (currently ``0x03030000``, i.e. v3.3.0.0).

Top-Level ``firmware/Makefile``
--------------------------------

``firmware/Makefile`` runs builds in parallel across a curated set of
"production" targets — used by the release pipeline.  For day-to-day
development, ``cd`` into the specific target directory and run ``make``
there.

Image Generation Flags
----------------------

The following environment variables control output artefact format
(defaults from ``ruckus/system_vivado.mk``):

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Default
     - Effect
   * - ``GEN_BIT_IMAGE``
     - 1
     - Copy ``.bit`` to ``images/``.
   * - ``GEN_BIT_IMAGE_GZIP``
     - 0
     - Also produce ``.bit.gz``.
   * - ``GEN_BIN_IMAGE``
     - 0
     - Produce ``.bin``.
   * - ``GEN_BIN_IMAGE_GZIP``
     - 0
     - Produce ``.bin.gz``.
   * - ``GEN_MCS_IMAGE``
     - 1
     - Run promgen and copy ``.mcs`` to ``images/``.
   * - ``GEN_MCS_IMAGE_GZIP``
     - 0
     - Also produce ``.mcs.gz``.

Set any flag to ``1`` (or ``0``) in your environment before invoking
``make`` to override:

.. code-block:: bash

   GEN_MCS_IMAGE_GZIP=1 make
