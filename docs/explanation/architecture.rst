Architecture
============

``pgp-pcie-apps`` is a three-layer wrapper around ``axi-pcie-core``,
``surf``, and ``ruckus``.  Each layer has a single responsibility; the
boundaries between them are what allow the same RTL to ship across 14
boards and four protocols.

The Three Layers
----------------

.. code-block:: text

   ┌──────────────────────────────────────────────────────────────┐
   │  Target Top-Level                                             │
   │  firmware/targets/<Board>/<Target>/hdl/<Target>.vhd          │
   │                                                               │
   │  - Board pin assignments (.xdc)                              │
   │  - Clock generation (ClockManagerUltraScale)                 │
   │  - Top-level AXI-Lite crossbar                               │
   │  - Optional DDR/HBM buffer instantiation                     │
   └────────┬─────────────────────────────────────────────────────┘
            │
            │ instantiates
            ▼
   ┌──────────────────────────────────────────────────────────────┐
   │  Hardware (board + protocol adapter)                          │
   │  firmware/common/<proto>/hardware/<Board>/core/Hardware.vhd  │
   │                                                               │
   │  - Adapts generic PgpLaneWrapper to board port widths        │
   │  - Pure structural — no protocol logic                       │
   └────────┬─────────────────────────────────────────────────────┘
            │
            │ instantiates
            ▼
   ┌──────────────────────────────────────────────────────────────┐
   │  Shared Protocol Layer                                        │
   │  firmware/common/<proto>/shared/rtl/                         │
   │                                                               │
   │  - PgpLaneWrapper / PgpGtyLaneWrapper (QPLL, QSFP map)       │
   │  - PgpLane / PgpGtyLane (per-lane GT + TX + RX + monitors)   │
   │  - PgpLaneRx (per-VC FIFO + Mux to DMA)                      │
   │  - PgpLaneTx (DMA OB → flush → resize → SOF → DeMux)         │
   └──────────────────────────────────────────────────────────────┘

Why three layers
~~~~~~~~~~~~~~~~

Layer 1 (target) is the only place that knows physical pins.  Adding a
new board involves new target VHDLs but **no changes to layers 2 or 3**.

Layer 2 (hardware adapter) is the only place that knows
board-specific port widths (QSFP count, transceiver lane count).  It is
a thin structural wrapper — no actual logic.  This is the "anti-pattern
that pays for itself": yes, every (board, protocol) pair has a separate
``Hardware.vhd``, but each one is small and the contract between layers
is enforced by the unified ``Hardware`` entity port list.

Layer 3 (shared protocol layer) is the only place that knows
PGP/HTSP framing, QPLL configuration, and AXI-Stream-to-DMA bridging.
Once a protocol works on one board, it works on all boards that ship a
layer-2 adapter for that protocol.

What axi-pcie-core Provides Underneath
---------------------------------------

The target top-level (layer 1) also instantiates ``<Board>Core`` from
``axi-pcie-core``.  That entity provides:

* The PCIe PHY wrapping (board-specific pre-compiled ``.dcp``).
* The AXI-Stream DMA engine (``AxiPcieDma`` + ``AxiStreamDmaV2``).
* The BAR0 register crossbar (``AxiPcieReg``) — version registers, PROM
  access, I2C, sysmon, SPI/BPI flash.
* The application-region AXI-Lite master pair
  (``appReadMaster`` / ``appWriteMaster``) routed through to the
  ``appClk`` domain.

The target's job is to wire the DMA streams (``dmaObMasters`` /
``dmaIbMasters``) and the application AXI-Lite into the protocol layer's
``Hardware`` instance.  See :doc:`/explanation/data_flow` for the full
signal trace.

For the internals of ``<Board>Core``, see the
`axi-pcie-core architecture explanation
<https://slaclab.github.io/axi-pcie-core/explanation/architecture.html>`_.

Bus Conventions
---------------

* **All data paths** are AXI4-Stream (``surf.AxiStreamPkg``).
* **All register access** is AXI4-Lite (``surf.AxiLitePkg``), distributed
  through a tree of ``surf.AxiLiteCrossbar`` instances rooted at
  ``axi-pcie-core``'s BAR0.
* **All clock-domain crossings** for streams use
  ``surf.AxiStreamFifoV2`` with ``GEN_SYNC_FIFO_G => false``.
* **All clock-domain crossings** for single bits or vectors use
  ``surf.Synchronizer`` / ``surf.SynchronizerVector``.

These conventions are not flexible — deviating breaks downstream tooling
that assumes them (verification, simulation backends, the
``axi-pcie-core`` DMA contract).

GT-Family Selection
-------------------

The shared ``ruckus.tcl`` uses ``getFpgaFamily`` to conditionally load
either:

* ``firmware/common/<proto>/shared/rtl/gtyUs+/`` (GTY UltraScale+ — Alveo
  U-series, Varium C1100, VCU128) or
* ``firmware/common/<proto>/shared/rtl/gthUs/`` (GTH UltraScale — KCU105,
  KCU116, KCU1500, PgpCardG4).

The directory name is the only difference; the entity name is the same
(``PgpLane`` or ``PgpGtyLane``).  Targets do not need to know which
GT family they use — ``getFpgaFamily`` makes the choice at build time.
