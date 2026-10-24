Building XilinxVariumC1100PrbsTester
====================================

The PrbsTester target is a second XilinxVariumC1100 application.  Unlike
``XilinxVariumC1100DmaLoopback`` (which wires DMA-in to DMA-out for a
host-side soak test), PrbsTester instantiates ``firmware/common/PrbsTester``
in hardware, generating PRBS streams on the FPGA itself and validating
the DMA path independently of any host-side traffic generator.

The build flow is identical to :doc:`/tutorial/first_build`; the
differences are in the target's ``hdl/`` top-level and its
``ruckus.tcl``.

Prerequisites
-------------

Same as :doc:`/tutorial/first_build`: git-lfs, recursively initialized
submodules, Vivado 2024.2+ on ``PATH`` (Vivado 2026.1 at SLAC).

Build
-----

.. code-block:: bash

   source /sdf/group/faders/tools/xilinx/2026.1/Vivado/2026.1/settings64.sh
   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester
   make

What Differs From DmaLoopback
-----------------------------

The PrbsTester ``ruckus.tcl`` (:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester/ruckus.tcl`)
adds one line on top of what DmaLoopback loads:

.. code-block:: tcl

   loadRuckusTcl $::env(PROJ_DIR)/../../../common/PrbsTester

This pulls in the in-hardware PRBS application
(:repo:`firmware/common/PrbsTester/rtl/Hardware.vhd`, with one
``PrbsLane`` per DMA lane wrapping ``surf``'s ``SsiPrbsTx`` /
``SsiPrbsRx``, plus a ``SyncTrigger``).  The ``ruckus.tcl`` also selects
the ``Performance_ExplorePostRoutePhysOpt`` implementation strategy and
does not load a ``tb/`` simulation testbed.

The top-level ``hdl/XilinxVariumC1100PrbsTester.vhd`` is a different
design from DmaLoopback: it adds an application ``AxiLiteCrossbar``, an
``HbmDmaBufferV2`` between the PRBS lanes and the DMA engine, and an
inbound ``AxiStreamMonAxiL``.  The HBM buffer RTL comes from the shared
``axi-pcie-core`` board ``ruckus.tcl`` that both targets load.

The Makefile is identical: same ``PRJ_PART = XCU55N-FSVH2892-2L-E``,
same ``PARALLEL_SYNTH = 8``, same ``target: prom``.

Build Artifacts
---------------

Output files appear in the following directory, named with the same
``IMAGENAME`` convention described in :doc:`/tutorial/first_build`:

.. code-block:: text

   firmware/targets/XilinxVariumC1100/XilinxVariumC1100PrbsTester/images/
       XilinxVariumC1100PrbsTester-<version>-<time>-<user>-<hash>.bit
       XilinxVariumC1100PrbsTester-<version>-<time>-<user>-<hash>.mcs

The build emits the same expected critical warnings as ``DmaLoopback``
(the PCIe PHY black-box constraints); see :doc:`/tutorial/first_build`
for explanations.

Exercising the PRBS Tester
--------------------------

After flashing the board and rescanning the PCIe bus, drive the
in-hardware PRBS engine from Python with
``software/scripts/PrbsTesting.py``.  See
:doc:`/how-to/run_pgp_testing` for the operating recipe.
