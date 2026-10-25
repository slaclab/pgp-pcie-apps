Makefile Targets
================

The ruckus Makefile chain provides a set of PHONY targets that all
per-target ``Makefile``\s inherit via
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
     - Default target (most target ``Makefile``\s set ``target: prom``;
       a few use the equivalent ``bit`` or ``mcs`` alias).  Runs
       synthesis, implementation, ``write_bitstream``, and
       ``write_cfgmem`` for the PROM image.  Produces
       ``images/<IMAGENAME>.bit`` and ``images/<IMAGENAME>.mcs`` (the
       ``.mcs`` only if the target has ``vivado/promgen.tcl``; the
       ``AlphaDataKu3`` targets do not).
   * - ``make bit`` / ``make prom`` / ``make mcs``
     - Aliases for the same batch build.  Which images are written is
       controlled by the `Image Generation Flags`_ below (for example,
       ``GEN_MCS_IMAGE=0 make bit`` skips the ``.mcs``).
   * - ``make pdi``
     - Same batch build, for Versal-class targets that produce a ``.pdi``.
   * - ``make syn``
     - Run synthesis only.
   * - ``make gui``
     - Open the Vivado project in GUI mode, creating it first if needed.
       Use after a batch ``make`` to inspect timing reports, debug a
       failing run, or place debug probes.
   * - ``make xsim``
     - Run the Vivado simulator (XSIM) on the ``sim_1`` top set in the
       target's ``ruckus.tcl``.  Only meaningful where a ``tb/``
       directory exists.  ``make vcs`` and ``make msim`` are the VCS and
       ModelSim/Questa equivalents.
   * - ``make clean``
     - Delete ``firmware/build/<Target>/``.  The ``images/`` directory
       is left untouched.
   * - ``make release``
     - Tag and publish the GitHub release described by
       ``firmware/releases.yaml`` (needs ``GITHUB_TOKEN``).
       ``make release_files`` generates the release files locally
       without publishing.
   * - ``make test``
     - Print the resolved ruckus variables, for debugging the
       ``Makefile`` chain.

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
     - Parallel-synthesis worker count.  Defaults to the host CPU
       count.  The ``XilinxVariumC1100`` and ``XilinxAlveoU55c`` targets
       pin 8; the ``XilinxAlveoU200`` protocol/PrbsTester and
       ``XilinxKcu1500`` protocol targets pin 1.
   * - ``TOP_DIR``
     - Path to ``firmware/`` from the target directory.  Set to
       ``$(abspath $(PWD)/../../..)``, which is required because the
       target sits three levels below ``firmware/``.
   * - ``RELEASE``
     - Inherited from ``firmware/targets/shared_config.mk``
       (default: ``pgp_pcie_apps``).  Selects the ``releases.yaml``
       entry for ``make release``.  ``XilinxKcu1500DmaLoopback``
       overrides it to ``XilinxKcu1500``.
   * - ``PRJ_VERSION``
     - Inherited from ``firmware/targets/shared_config.mk``
       (currently ``0x03040000``, i.e., v3.4.0.0).

Top-Level ``firmware/Makefile``
-------------------------------

``firmware/Makefile`` runs ``make clean``, removes ``images/``, and
rebuilds each of the release targets listed in ``releases.yaml``, one
after another (``make`` or ``make build``).  Publishing is a separate
``make release`` step.  For day-to-day development, ``cd`` into the
specific target directory and run ``make`` there.

``make syn`` (not the default) is a faster pre-release check: it runs
``make clean`` then ``make syn`` (synthesis only, no implementation or
bitstream) on each release target, and stops on the first failure.

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
   * - ``GEN_PDI_IMAGE``
     - 1
     - Copy ``.pdi`` to ``images/`` (Versal targets).
   * - ``GEN_PDI_IMAGE_GZIP``
     - 0
     - Also produce ``.pdi.gz``.
   * - ``GEN_XSA_IMAGE``
     - 0
     - Export the ``.xsa`` hardware handoff.

Set any flag to ``1`` (or ``0``) in your environment before invoking
``make`` to override:

.. code-block:: bash

   GEN_MCS_IMAGE_GZIP=1 make
