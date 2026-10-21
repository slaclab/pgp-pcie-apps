Makefile Targets
================

The ruckus Makefile chain provides a small set of PHONY targets that
all per-target ``Makefile``\s inherit via
``include $(TOP_DIR)/submodules/ruckus/system_vivado.mk``.

Per-Target ``make`` Entry Points
--------------------------------

From inside ``firmware/targets/<Board>/<Target>/``:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Command
     - Effect
   * - ``make``
     - Default target (each target ``Makefile`` sets ``target: prom``).
       Runs synthesis, implementation, ``write_bitstream``, and
       ``write_cfgmem`` for the PROM image.  Produces
       ``images/<IMAGENAME>.bit`` and ``images/<IMAGENAME>.mcs``.
   * - ``make bit`` / ``make prom`` / ``make mcs``
     - Aliases for the same batch build.  Which images are written is
       controlled by the `Image Generation Flags`_ below (for example,
       ``GEN_MCS_IMAGE=0 make bit`` skips the ``.mcs``).
   * - ``make pdi``
     - Same batch build, for Versal-class targets that produce a ``.pdi``.
   * - ``make syn``
     - Run synthesis only.
   * - ``make gui``
     - Open the existing Vivado project in interactive mode.  Use after a
       prior batch ``make`` to inspect timing reports, debug a failing run,
       or place debug probes.
   * - ``make xsim``
     - Run the Vivado simulator (XSIM) on the ``sim_1`` top set in the
       target's ``ruckus.tcl``.  Only meaningful where a ``tb/``
       directory exists.  ``make vcs`` and ``make msim`` are the VCS and
       ModelSim/Questa equivalents.
   * - ``make clean``
     - Delete ``firmware/build/<Target>/``.  The ``images/`` directory
       is left untouched.

Per-Target ``Makefile`` Variables
---------------------------------

Each target's ``Makefile`` (e.g.,
:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/Makefile`)
exports a small set of variables that drive the ruckus inclusion:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Variable
     - Meaning
   * - ``PRJ_PART``
     - Xilinx part number.  Required.  Per-board constant, e.g.,
       ``XCU55N-FSVH2892-2L-E`` for VariumC1100, ``xcku115-flvb2104-2-e``
       for KCU1500.
   * - ``PARALLEL_SYNTH``
     - Parallel-synthesis worker count.  Most targets use 8; some heavy
       targets set 1 to reduce peak memory.
   * - ``TOP_DIR``
     - Path to ``firmware/`` from the target directory.  Set to
       ``$(abspath $(PWD)/../../..)``, which is required because the
       target sits three levels below ``firmware/``.
   * - ``RELEASE``
     - Inherited from ``firmware/targets/shared_config.mk``
       (default: ``pgp_pcie_apps``).  Used by the release pipeline.
   * - ``PRJ_VERSION``
     - Inherited from ``firmware/targets/shared_config.mk``
       (currently ``0x03040000``, i.e., v3.4.0.0).

Top-Level ``firmware/Makefile``
-------------------------------

``firmware/Makefile`` runs builds in parallel across a curated set of
"production" targets and is used by the release pipeline.  For day-to-day
development, ``cd`` into the specific target directory and run ``make``
there.

Image Generation Flags
----------------------

The following environment variables control the output artifact format
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
