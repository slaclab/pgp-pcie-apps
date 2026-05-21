Supported Targets
=================

The full matrix of ``firmware/targets/`` build outputs.  Each row maps a
``(Board, Protocol, Variant)`` tuple to a target directory.  Every target
listed here builds with the same ``make`` workflow described in
:doc:`/tutorial/first_build`.

By Board
--------

XilinxVariumC1100
~~~~~~~~~~~~~~~~~

Gen4x8 PCIe + HBM2.  ``PRJ_PART = XCU55N-FSVH2892-2L-E``.  Vivado
2024.2+ required (CMS + HBM IP).

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - Target
     - Notes
   * - ``XilinxVariumC1100DmaLoopback``
     - DMA loopback application; see :doc:`/tutorial/first_build`.
   * - ``XilinxVariumC1100DmaLoopbackBifurcatedPcie``
     - DMA loopback with PCIe bifurcation (two x4 endpoints).
   * - ``XilinxVariumC1100PrbsTester``
     - In-hardware PRBS tester; see :doc:`/tutorial/prbs_tester_build`.
   * - ``XilinxVariumC1100Pgp2b``
     - PGP2b protocol.
   * - ``XilinxVariumC1100Pgp4_6Gbps``
     - PGP4 @ 6.25 Gbps.
   * - ``XilinxVariumC1100Pgp4_10Gbps``
     - PGP4 @ 10.3125 Gbps.
   * - ``XilinxVariumC1100Pgp4_15Gbps``
     - PGP4 @ 15.46875 Gbps.
   * - ``XilinxVariumC1100Pgp4_25Gbps_Fec``
     - PGP4 @ 25 Gbps, RS-FEC enabled.
   * - ``XilinxVariumC1100Htsp100Gbps``
     - HTSP 100 Gbps.
   * - ``XilinxVariumC1100Htsp100GbpsBifurcatedPcie``
     - HTSP 100 Gbps with PCIe bifurcation.

XilinxKcu1500
~~~~~~~~~~~~~

Gen3x8 PCIe + DDR4.  Multiple PGP variants.  Vivado 2020.1+.

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - Target
     - Notes
   * - ``XilinxKcu1500DmaLoopback``
     - DMA loopback application (also has ``tb/`` for simulation).
   * - ``XilinxKcu1500PrbsTester``
     - In-hardware PRBS tester.
   * - ``XilinxKcu1500Pgp*_*Gbps``
     - Various PGP2b / PGP3 / PGP4 line-rate combinations — see
       :repo:`firmware/targets/XilinxKcu1500/` for the full list.

Other Boards
~~~~~~~~~~~~

Each board has a similar set of DmaLoopback + PrbsTester + protocol
variants where supported.  Browse the source tree to see the full
matrix:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Board
     - Directory
   * - Xilinx Alveo U200
     - :repo:`firmware/targets/XilinxAlveoU200/`
   * - Xilinx Alveo U250
     - :repo:`firmware/targets/XilinxAlveoU250/`
   * - Xilinx Alveo U280
     - :repo:`firmware/targets/XilinxAlveoU280/`
   * - Xilinx Alveo U50
     - :repo:`firmware/targets/XilinxAlveoU50/`
   * - Xilinx Alveo U55c
     - :repo:`firmware/targets/XilinxAlveoU55c/`
   * - Xilinx VCU128
     - :repo:`firmware/targets/XilinxVcu128/`
   * - Xilinx KCU105
     - :repo:`firmware/targets/XilinxKcu105/`
   * - Xilinx KCU116
     - :repo:`firmware/targets/XilinxKcu116/`
   * - SLAC PGP Card G4
     - :repo:`firmware/targets/SlacPgpCardG4/`
   * - Abaco PC821 (KU085)
     - :repo:`firmware/targets/AbacoPc821Ku085/`
   * - Abaco PC821 (KU115)
     - :repo:`firmware/targets/AbacoPc821Ku115/`
   * - Alpha Data KU3
     - :repo:`firmware/targets/AlphaDataKu3/`
   * - BittWare XUP-VV8
     - :repo:`firmware/targets/BittWareXupVv8/`

For per-board PCIe-core details (PCIe generation, memory type,
``HW_TYPE_*`` constant, etc.) see the
`axi-pcie-core supported_boards reference
<https://slaclab.github.io/axi-pcie-core/reference/supported_boards.html>`_.
