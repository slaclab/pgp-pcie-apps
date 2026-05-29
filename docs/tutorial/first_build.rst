First Build — XilinxVariumC1100DmaLoopback
===========================================

This tutorial walks you through building a real PCIe bitstream for the
**Xilinx Varium C1100** board using the ``XilinxVariumC1100DmaLoopback``
target.  Loopback is the simplest application: every DMA channel's
inbound (host→FPGA) stream is wired directly to its outbound (FPGA→host)
stream, exercising the ``axi-pcie-core`` DMA engine without any
PGP/HTSP optical link.

.. note::

   Vivado 2024.2 is the minimum version for ``XilinxVariumC1100`` because
   the board uses the Xilinx CMS block design and HBM2 IP.  At SLAC the
   current tested production toolchain is **Vivado 2025.2**, which is
   what this tutorial assumes.

The board is a Gen4x8 PCIe card with HBM2 on-board memory.  The end
artefact is a ``.bit`` bitstream and a ``.mcs`` SPIx4 PROM image.

Prerequisites
-------------

- **git 2.x with git-lfs** installed and initialised — ``axi-pcie-core``
  uses LFS for pre-compiled IP ``.dcp`` checkpoints.  Without active LFS
  the build fails on missing binary IP.
- **Vivado 2024.2 or later** on your ``PATH``.  At SLAC S3DF:

  .. code-block:: bash

     source /sdf/group/faders/tools/xilinx/2025.2/Vivado/2025.2/settings64.sh

  Outside SLAC, source your site's equivalent ``settings64.sh``.

- A JTAG cable + Vivado Hardware Manager are *not* needed to build —
  only to flash the resulting bitstream onto a physical board.

Confirm git-lfs is active:

.. code-block:: bash

   git lfs version

Clone and Initialise
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
   # Expected:  Vivado v2025.2 (64-bit)

Build the Bitstream
-------------------

Navigate to the target and run ``make``:

.. code-block:: bash

   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback
   make

``make`` invokes Vivado in batch mode through the ruckus build system.
ruckus assembles the project, runs synthesis and implementation, and
generates the bitstream + MCS programming file.  A full first build takes
several hours on a modern workstation.

Where the Build Runs
~~~~~~~~~~~~~~~~~~~~

ruckus writes the Vivado project and per-run artefacts under:

.. code-block:: text

   firmware/build/XilinxVariumC1100DmaLoopback/

That is the working build tree (Vivado ``.xpr``, synth/impl runs,
checkpoints).  The final shipping artefacts are copied to the target's
own ``images/`` directory — see `Build Artefacts`_ below.

Expected Critical Warnings
~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``XilinxVariumC1100`` build emits two non-fatal ``CRITICAL_WARNING``
lines that are expected and safe to ignore:

* ``[Designutils 20-1280] Could not find module
  'XilinxVariumC1100PciePhyGen4x8_pcie4c_ip'``

  The PCIe PHY is delivered as a pre-compiled ``.dcp`` checkpoint, so the
  inner module is not visible to the late-XDC pass.  Vivado applies the
  PHY's own XDC when the DCP is linked in.

* ``[Project 1-498] One or more constraints failed evaluation while
  reading constraint file [...] XilinxVariumC1100Timing.xdc``

  Same root cause — the PHY is a black box at this elaboration point;
  the timing constraints are re-read and applied post-synthesis.

Useful Makefile Targets
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   make            # full bitstream + MCS PROM image (default)
   make gui        # open the Vivado project in the GUI for debugging
   make bit        # build only the .bit file
   make prom       # build the .bit + .mcs PROM image (same as default)
   make clean      # remove the build/ tree

Build Artefacts
---------------

On a successful build, output files are placed under:

.. code-block:: text

   firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/images/

With default flags (``GEN_BIT_IMAGE=1``, ``GEN_MCS_IMAGE=1``, gzip flags off)
the directory contains a ``.bit`` and a ``.mcs`` whose basename is
ruckus's ``IMAGENAME``:

.. code-block:: text

   XilinxVariumC1100DmaLoopback-0x03030000-20260521094121-ruckman-b94c4a7.bit   (~21 MB)
   XilinxVariumC1100DmaLoopback-0x03030000-20260521094121-ruckman-b94c4a7.mcs   (~57 MB)

``IMAGENAME`` is defined in
:repo:`firmware/submodules/ruckus/system_shared.mk` as
``$(PROJECT)-$(PRJ_VERSION)-$(BUILD_TIME)-$(USER)-$(GIT_HASH_SHORT)``,
which embeds the full build provenance in each artefact name:

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
     - ``0x03030000``
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
segment is replaced with the literal string ``dirty`` — so a casual
uncommitted build is obvious from the filename alone.

For partial-reconfiguration flows (``RECONFIG_STATIC_HASH != 0``), an
additional ``_<RECONFIG_STATIC_HASH>`` suffix is appended after the git
hash.

Set ``GEN_BIT_IMAGE_GZIP=1`` and/or ``GEN_MCS_IMAGE_GZIP=1`` in the
environment before invoking ``make`` to also produce gzipped copies
(``.bit.gz``, ``.mcs.gz``).

Use the ``.bit`` file to program the board over JTAG (Vivado Hardware
Manager).  Use the ``.mcs`` file to program the SPI configuration PROM
for persistent boot — see :doc:`/how-to/program_with_updatepciefpga`.

Next Steps
----------

- Build the in-hardware PRBS application variant of the same board:
  :doc:`/tutorial/prbs_tester_build`.
- Exercise the loopback target end-to-end from Python:
  :doc:`/tutorial/run_loopback_test`.
- For the underlying PCIe DMA engine that this build instantiates, see
  the `axi-pcie-core docs
  <https://slaclab.github.io/axi-pcie-core/explanation/architecture.html>`_.
