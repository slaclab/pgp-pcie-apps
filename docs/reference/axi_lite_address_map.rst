AXI-Lite Address Map
====================

The PCIe BAR0 register space is decoded by a tree of ``AxiLiteCrossbar``
instances rooted in ``axi-pcie-core``.  ``pgp-pcie-apps`` adds its own
application-region crossbar on top — this page documents the application
layer.

BAR0 Top Level (from axi-pcie-core)
------------------------------------

The BAR0 register tree below offset ``0x00100000`` is owned by
``axi-pcie-core`` and is documented in the
`axi-pcie-core register_map reference
<https://slaclab.github.io/axi-pcie-core/reference/register_map.html>`_.

The address window from ``0x00100000`` upwards is forwarded as the
``appReadMaster`` / ``appWriteMaster`` pair to the application
(``appClk`` domain).  ``pgp-pcie-apps`` decodes that range as follows.

Application Region (Top-Level pgp-pcie-apps Crossbar)
------------------------------------------------------

The top-level target VHDL (e.g.
:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps/hdl/XilinxVariumC1100Pgp4_6Gbps.vhd`)
instantiates an AXI-Lite crossbar inside the ``app`` clock domain with
the following layout:

.. list-table::
   :header-rows: 1
   :widths: 18 22 60

   * - Offset
     - Slave
     - Contents
   * - ``0x00100000``
     - ``MigDmaBuffer`` (optional)
     - When the target includes the DDR/HBM-backed DMA buffer; otherwise
       responds with ``DECERR``.
   * - ``0x00200000``
     - Utility A
     - Per-target utility AXI-Lite slave.
   * - ``0x00300000``
     - Utility B
     - Per-target utility AXI-Lite slave.
   * - ``0x00400000``
     - Utility C
     - Per-target utility AXI-Lite slave.
   * - ``0x00800000``
     - ``Hardware`` (PgpLaneWrapper / HtspWrapper)
     - The protocol layer — see `Hardware Sub-Tree`_ below.

Hardware Sub-Tree
~~~~~~~~~~~~~~~~~

Within the ``Hardware`` slave at ``0x00800000``, the
``PgpLaneWrapper`` distributes per-lane access:

.. list-table::
   :header-rows: 1
   :widths: 22 22 56

   * - Lane Base
     - Lane Index
     - Allocation
   * - ``0x00800000``
     - 0
     - First PGP lane (QSFP cage 0, lane 0)
   * - ``0x00810000``
     - 1
     - Second PGP lane
   * - ``0x00820000``
     - 2
     - Third PGP lane
   * - …
     - …
     - up to lane 7 at ``0x00870000``
   * - **Stride**
     -
     - ``0x00010000`` per lane (64 KB window).

Per-Lane Layout
~~~~~~~~~~~~~~~

Within each lane window the ``PgpGtyLane`` / ``PgpLane`` further
decodes:

.. list-table::
   :header-rows: 1
   :widths: 22 22 56

   * - Offset (within lane)
     - Slave
     - Contents
   * - ``0x0000``
     - GT core
     - ``surf.Pgp4GtyUs`` registers — link status, line rate, FEC.
   * - ``0x1000``
     - PGP monitor
     - ``surf.Pgp4AxiL`` — RX/TX frame counters, drops, link state.
   * - ``0x2000``
     - Control
     - Lane-specific control bits (``locData`` pause, etc.).
   * - ``0x3000``
     - TX stream monitor
     - ``surf.AxiStreamMonAxiL`` — per-VC TX frame/byte counters.
   * - ``0x4000``
     - RX stream monitor
     - ``surf.AxiStreamMonAxiL`` — per-VC RX frame/byte counters.

Tracing in Software
-------------------

The PyRogue device tree mirrors this layout.  From any
``LoopbackTesting.py`` or ``PgpTesting.py`` session:

.. code-block:: python

   # Top-level
   root.AxiPcieCore.AxiVersion.UpTimeCnt.get()
   # Application region (per target)
   root.Hardware.Pgp[0].PgpAxiL.RxFrameCnt.get()

Adjust the path for HTSP targets — see ``software/scripts/HtspTesting.py``
for the device-tree path through ``HtspWrapper``.
