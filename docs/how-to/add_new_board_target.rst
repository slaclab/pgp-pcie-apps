Add a New Board Target
======================

This guide shows how to add a new ``firmware/targets/<Board>/<Target>/``
build for an existing protocol+board combination.  Adding a *brand-new
board* (one not in :doc:`/reference/supported_targets`) is out of scope
here — that work lives in ``axi-pcie-core`` (see the
`axi-pcie-core add-new-board how-to
<https://slaclab.github.io/axi-pcie-core/how-to/add_new_board.html>`_).

Recipe
------

To add ``firmware/targets/<Board>/<Board><Protocol>_<Rate>/`` for an
existing supported board:

1. **Copy** the nearest existing target.  For example, to add
   ``XilinxVariumC1100Pgp4_25Gbps`` you would clone
   ``XilinxVariumC1100Pgp4_15Gbps``:

   .. code-block:: bash

      cp -r firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_15Gbps \
            firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_25Gbps

2. **Rename** the top-level ``hdl/`` files and entity name to match the
   new target directory:

   .. code-block:: bash

      cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_25Gbps/hdl
      mv XilinxVariumC1100Pgp4_15Gbps.vhd  XilinxVariumC1100Pgp4_25Gbps.vhd
      mv XilinxVariumC1100Pgp4_15Gbps.xdc  XilinxVariumC1100Pgp4_25Gbps.xdc
      # then edit the .vhd to rename the VHDL entity to match

3. **Update** the ``RATE_G`` (or equivalent) generic in the top-level
   VHDL to the new line rate.  See :doc:`/how-to/add_new_line_rate` for
   the per-protocol QPLL/rate mapping.

4. **Verify** the ``Makefile`` settings (``PRJ_PART``, ``PARALLEL_SYNTH``)
   are still correct for the board.  ``PRJ_PART`` is per-board and rarely
   changes between targets on the same board.

5. **Build** with ``make`` per :doc:`/tutorial/first_build`.

How the ruckus.tcl Chain Works
-------------------------------

Every target's ``ruckus.tcl`` follows the same three-step pattern (see
:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps/ruckus.tcl`
for a worked example):

.. code-block:: tcl

   source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

   loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
   loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/<Board>
   loadRuckusTcl $::env(PROJ_DIR)/../../../common/<proto>/hardware/<Board>

   loadSource      -dir "$::DIR_PATH/hdl"
   loadConstraints -dir "$::DIR_PATH/hdl"

The three ``loadRuckusTcl`` calls pull in:

* ``surf`` — base SLAC RTL library (AXI/stream primitives, PGP cores).
* ``axi-pcie-core/hardware/<Board>`` — PCIe DMA + board-specific I/O
  for the carrier card.
* ``common/<proto>/hardware/<Board>`` — the board-specific
  ``Hardware.vhd`` adapter for the chosen protocol (PGP2b / PGP3 /
  PGP4 / HTSP).

The fourth ``loadSource`` plus ``loadConstraints`` adds your target's
own top-level VHDL and XDC.

See :doc:`/explanation/architecture` for why the chain is layered this
way.

Cross-References
----------------

- :doc:`/how-to/add_new_line_rate` — modify the line rate of an existing
  target.
- :doc:`/how-to/select_protocol` — choose between PGP2b, PGP3, PGP4,
  and HTSP for a given board.
- :doc:`/reference/supported_targets` — the matrix of all existing
  targets.
