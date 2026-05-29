Building XilinxVariumC1100PrbsTester
=====================================

The PrbsTester target is a second XilinxVariumC1100 application.  Unlike
``XilinxVariumC1100DmaLoopback`` (which wires DMA-in to DMA-out for a
host-side soak test), PrbsTester instantiates ``firmware/common/PrbsTester``
in-hardware, generating PRBS streams on the FPGA itself and validating
the DMA path independent of any host-side traffic generator.

The build flow is identical to :doc:`/tutorial/first_build` — the
differences are entirely inside the target's ``ruckus.tcl``.

Prerequisites
-------------

Same as :doc:`/tutorial/first_build`: git-lfs, recursively initialised
submodules, Vivado 2024.2+ on ``PATH`` (Vivado 2025.2 at SLAC).

Build
-----

.. code-block:: bash

   source /sdf/group/faders/tools/xilinx/2025.2/Vivado/2025.2/settings64.sh
   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester
   make

What Differs From DmaLoopback
-----------------------------

The PrbsTester ``ruckus.tcl`` (:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester/ruckus.tcl`)
pulls in two pieces of RTL on top of what DmaLoopback uses:

.. code-block:: tcl

   loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxVariumC1100/ddr
   loadRuckusTcl $::env(PROJ_DIR)/../../../common/PrbsTester

The first pulls in the board's HBM DMA buffer support; the second pulls
in the in-hardware PRBS generator/checker application
(:repo:`firmware/common/PrbsTester/rtl/PrbsLane.vhd`).

The Makefile is otherwise identical — same ``PRJ_PART = XCU55N-FSVH2892-2L-E``,
same ``PARALLEL_SYNTH = 8``, same ``target: prom``.

Build Artefacts
---------------

Output files appear in:

.. code-block:: text

   firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester/images/
       XilinxVariumC1100PrbsTester-<version>.bit
       XilinxVariumC1100PrbsTester-<version>.mcs

Same expected critical warnings as ``DmaLoopback`` (the PCIe PHY black-box
constraints) — see :doc:`/tutorial/first_build` for explanations.

Exercising the PRBS Tester
--------------------------

After flashing the board and rescanning the PCIe bus, drive the
in-hardware PRBS engine from Python with
``software/scripts/PrbsTesting.py`` — see
:doc:`/how-to/run_pgp_testing` for the operating recipe.
