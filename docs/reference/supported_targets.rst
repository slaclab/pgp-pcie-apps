Supported Targets
=================

The matrix of ``firmware/targets/`` build outputs.  Each row maps a
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
     - DMA loopback with PCIe bifurcation (two Gen4 x8 endpoints).
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
     - PGP4 @ 25 Gbps, RS-FEC enabled (requires Vivado 2025.1 to
       2026.2).
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
   * - ``XilinxKcu1500DmaLoopbackBifurcatedPcie``
     - DMA loopback with PCIe bifurcation.
   * - ``XilinxKcu1500PrbsTester``
     - In-hardware PRBS tester.
   * - ``XilinxKcu1500Pgp2b``
     - PGP2b protocol.
   * - ``XilinxKcu1500Pgp3_6Gbps`` / ``XilinxKcu1500Pgp3_10Gbps``
     - PGP3 @ 6.25 / 10.3125 Gbps.
   * - ``XilinxKcu1500Pgp4_6Gbps`` / ``XilinxKcu1500Pgp4_10Gbps``
     - PGP4 @ 6.25 / 10.3125 Gbps.
   * - ``XilinxKcu1500Pgp4_6Gbps_repeater``
     - PGP4 @ 6.25 Gbps repeater variant.

Other Boards
~~~~~~~~~~~~

Only ``XilinxAlveoU200`` and ``SlacPgpCardG4`` also carry protocol
targets; the remaining boards have DmaLoopback (and some PrbsTester)
targets only.

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Board
     - Targets
   * - :repo:`XilinxAlveoU200 <firmware/targets/XilinxAlveoU200/>`
     - ``DmaLoopback``, ``PrbsTester``, ``Pgp2b``, ``Pgp3_6Gbps``,
       ``Pgp3_10Gbps``, ``Pgp4_6Gbps``, ``Pgp4_10Gbps``, ``Pgp4_12Gbps``,
       ``Pgp4_15Gbps``, ``Htsp100Gbps``, ``Htsp_FebEmu``
   * - :repo:`SlacPgpCardG4 <firmware/targets/SlacPgpCardG4/>`
     - ``DmaLoopback``, ``PrbsTester``, ``Pgp2b``, ``Pgp3_6Gbps``,
       ``Pgp3_10Gbps``, ``Pgp4_6Gbps``, ``Pgp4_10Gbps``,
       ``Pgp4_6Gbps_repeater``
   * - :repo:`BittWareXupVv8 <firmware/targets/BittWareXupVv8/>`
     - ``DmaLoopback``, ``DmaLoopback_VU9P``, ``PrbsTester``
   * - :repo:`AbacoPc821Ku085 <firmware/targets/AbacoPc821Ku085/>`
     - ``DmaLoopback``, ``PrbsTester``
   * - :repo:`AbacoPc821Ku115 <firmware/targets/AbacoPc821Ku115/>`
     - ``DmaLoopback``, ``PrbsTester``
   * - :repo:`AlphaDataKu3 <firmware/targets/AlphaDataKu3/>`
     - ``DmaLoopback``, ``PrbsTester`` (no PROM image; see
       :doc:`/reference/make_targets`)
   * - :repo:`XilinxAlveoU55c <firmware/targets/XilinxAlveoU55c/>`
     - ``DmaLoopback`` (plus ``CmsBlockDesign_wrapper``, a ``dcp``
       helper, not an application)
   * - :repo:`XilinxAlveoU250 <firmware/targets/XilinxAlveoU250/>`,
       :repo:`XilinxAlveoU280 <firmware/targets/XilinxAlveoU280/>`,
       :repo:`XilinxAlveoU50 <firmware/targets/XilinxAlveoU50/>`,
       :repo:`XilinxKcu105 <firmware/targets/XilinxKcu105/>`,
       :repo:`XilinxKcu116 <firmware/targets/XilinxKcu116/>`,
       :repo:`XilinxVcu128 <firmware/targets/XilinxVcu128/>`
     - ``DmaLoopback``

Target names in this table omit the board prefix; the directory is
``firmware/targets/<Board>/<Board><Target>/`` (for example
``XilinxAlveoU200/XilinxAlveoU200Pgp4_12Gbps``).

For per-board PCIe-core details (PCIe generation, memory type,
``HW_TYPE_*`` constant, etc.) see the
`axi-pcie-core supported_boards reference
<https://slaclab.github.io/axi-pcie-core/reference/supported_boards.html>`_.
