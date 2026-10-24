First Build: XilinxVariumC1100DmaLoopback
=========================================

This tutorial walks you through building a real PCIe bitstream for the
**Xilinx Varium C1100** board using the ``XilinxVariumC1100DmaLoopback``
target.  Loopback is the simplest application: every DMA channel's
outbound (host→FPGA) stream is wired directly to its inbound (FPGA→host)
stream, exercising the ``axi-pcie-core`` DMA engine without any
PGP/HTSP optical link.

.. note::

   Vivado 2024.2 is the minimum version for ``XilinxVariumC1100`` because
   the board uses the Xilinx CMS block design and HBM2 IP.  At SLAC, the
   currently tested production toolchain is **Vivado 2026.1**, which this
   tutorial assumes.

The board is a Gen4x8 PCIe card with HBM2 on-board memory.  The end
artifact is a ``.bit`` bitstream and a ``.mcs`` SPIx4 PROM image.

Prerequisites
-------------

- **git 2.x with git-lfs** installed and initialized.  ``axi-pcie-core``
  uses LFS for pre-compiled IP ``.dcp`` checkpoints; without active LFS,
  the build fails on missing binary IP.
- **Vivado 2024.2 or later** on your ``PATH``.  At SLAC S3DF:

  .. code-block:: bash

     source /sdf/group/faders/tools/xilinx/2026.1/Vivado/2026.1/settings64.sh

  Outside SLAC, source your site's equivalent ``settings64.sh``.

- A JTAG cable and Vivado Hardware Manager are *not* needed to build;
  they are only needed to flash the resulting bitstream onto a physical
  board.

Confirm git-lfs is active:

.. code-block:: bash

   git lfs version

Clone and Initialize
--------------------

.. code-block:: bash

   git clone https://github.com/slaclab/pgp-pcie-apps.git
   cd pgp-pcie-apps
   git submodule update --init --recursive

The recursive submodule init pulls in ``axi-pcie-core``, ``surf``,
``ruckus``, and their LFS-tracked binary IP.  The first clone transfers
roughly 1 GB.

Verify Vivado
-------------

After sourcing ``settings64.sh``, confirm:

.. code-block:: bash

   which vivado
   vivado -version | head -1
   # Expected:  Vivado v2026.1 (64-bit)

Build the Bitstream
-------------------

Navigate to the target and run ``make``:

.. code-block:: bash

   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback
   make

``make`` invokes Vivado in batch mode through the ruckus build system,
which assembles the project, runs synthesis and implementation, and
generates the bitstream and MCS programming file.  A full first build takes
several hours on a modern workstation.

Where the Build Runs
~~~~~~~~~~~~~~~~~~~~

ruckus writes the Vivado project and per-run artifacts under:

.. code-block:: text

   firmware/build/XilinxVariumC1100DmaLoopback/

That is the working build tree (Vivado ``.xpr``, synth/impl runs,
checkpoints).  On hosts with a ``/u1`` local disk, ruckus makes
``firmware/build`` a symlink to ``/u1/$USER/build`` so the build runs on
local storage.  The final shipping artifacts are copied to the target's
own ``images/`` directory (see `Build Artifacts`_ below).

Expected Critical Warnings
~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``XilinxVariumC1100`` build emits a few dozen non-fatal
``CRITICAL WARNING`` messages that are expected and safe to ignore.  All
of them come from constraints that ``axi-pcie-core`` shares across the
board's targets:

* ``[Designutils 20-1280] Could not find module
  'XilinxVariumC1100PciePhyGen4x8_pcie4c_ip'`` (and its ``_gt``
  sibling).  The PCIe PHY is delivered as a pre-compiled ``.dcp``
  checkpoint, so the inner module is not visible to the late-XDC pass.
  Vivado applies the PHY's own XDC when the DCP is linked in.
* ``[Project 1-498] One or more constraints failed evaluation`` for
  ``XilinxVariumC1100Timing.xdc`` and ``XilinxAlveoU55cCore.xdc``, with
  the matching ``[Vivado 12-627]``, ``[Vivado 12-508]``,
  ``[Vivado 12-4739]``, ``[Vivado 12-5201]``, ``[Constraints 18-4644]``,
  and ``[Common 17-55]`` messages.  These constraints reference the
  second PCIe reference clock (``pciRefClk1``) and ``U_ExtendedCore``,
  which only exist in the ``*BifurcatedPcie`` targets.

Any other ``CRITICAL WARNING`` is worth investigating.

Useful Makefile Targets
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   make            # full bitstream + MCS PROM image (default)
   make gui        # open the Vivado project in the GUI for debugging
   make clean      # remove this target's firmware/build/<Target>/ tree

``make bit`` and ``make prom`` are aliases for the same batch build.  To
skip the ``.mcs``, set ``GEN_MCS_IMAGE=0`` (see
:doc:`/reference/make_targets`).

Build Artifacts
---------------

On a successful build, output files are placed under:

.. code-block:: text

   firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/images/

With default flags (``GEN_BIT_IMAGE=1``, ``GEN_MCS_IMAGE=1``, gzip flags off)
the directory contains a ``.bit`` and a ``.mcs`` whose basename is
ruckus's ``IMAGENAME``:

.. code-block:: text

   XilinxVariumC1100DmaLoopback-0x03040000-20260521094121-ruckman-b94c4a7.bit   (~21 MB)
   XilinxVariumC1100DmaLoopback-0x03040000-20260521094121-ruckman-b94c4a7.mcs   (~57 MB)

``IMAGENAME`` is defined in
`ruckus/system_shared.mk <https://github.com/slaclab/ruckus/blob/main/system_shared.mk>`_
(``firmware/submodules/ruckus/system_shared.mk`` in your checkout) as
``$(PROJECT)-$(PRJ_VERSION)-$(BUILD_TIME)-$(USER)-$(GIT_HASH_SHORT)``,
which embeds the full build provenance in each artifact name:

.. list-table::
   :header-rows: 1
   :widths: 22 16 20 42

   * - Field
     - Make variable
     - Example
     - Source
   * - target name
     - ``$(PROJECT)``
     - ``XilinxVariumC1100DmaLoopback``
     - target directory name
   * - firmware version
     - ``$(PRJ_VERSION)``
     - ``0x03040000``
     - :repo:`firmware/targets/shared_config.mk`
   * - build timestamp
     - ``$(BUILD_TIME)``
     - ``20260521094121``
     - ``date +%Y%m%d%H%M%S`` at build start
   * - user
     - ``$(USER)``
     - ``ruckman``
     - the Unix user that ran ``make``
   * - git hash
     - ``$(GIT_HASH_SHORT)``
     - ``b94c4a7``
     - ``git rev-parse --short HEAD`` of this repo

If the working tree is dirty when ``make`` runs, the trailing git-hash
segment is replaced with the literal string ``dirty``, so an uncommitted
build is obvious from the filename alone.

For partial-reconfiguration flows (``RECONFIG_STATIC_HASH != 0``), an
additional ``_<RECONFIG_STATIC_HASH>`` suffix is appended after the git
hash.

Set ``GEN_BIT_IMAGE_GZIP=1`` and/or ``GEN_MCS_IMAGE_GZIP=1`` in the
environment before invoking ``make`` to also produce gzipped copies
(``.bit.gz``, ``.mcs.gz``).

Use the ``.bit`` file to program the board over JTAG (Vivado Hardware
Manager).  Use the ``.mcs`` file to program the SPI configuration PROM
for persistent boot (see :doc:`/how-to/program_with_updatepciefpga`).

Next Steps
----------

- Build the in-hardware PRBS application variant of the same board:
  :doc:`/tutorial/prbs_tester_build`.
- Exercise the loopback target end-to-end from Python:
  :doc:`/tutorial/run_loopback_test`.
- For the underlying PCIe DMA engine that this build instantiates, see
  the `axi-pcie-core docs
  <https://slaclab.github.io/axi-pcie-core/explanation/architecture.html>`_.
