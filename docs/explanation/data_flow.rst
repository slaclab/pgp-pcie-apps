Data Flow
=========

Three independent flows cross the design.  Each has a documented entry
point and a documented synchroniser at every clock-domain boundary.

PGP RX Path  (Optical → Host DMA)
----------------------------------

.. code-block:: text

   QSFP RX (serial)
        │
        ▼
   surf.Pgp4GtyUs  (GTY + PGP4 core)            <-- pgpClk
        │
        ▼  per-VC AXI-Stream
   PgpLaneRx                                     <-- pgpClk
        │   ┌── rxlinkReady blowoff filter
        │   ├── per-VC URAM FIFO (4×4 k deep, 64-bit)
        │   └── surf.AxiStreamMux (burst arbitration, 128-word)
        ▼
   surf.AxiStreamFifoV2 (async)                 pgpClk → dmaClk
        │
        ▼  dmaIbMasters
   <Board>Core (axi-pcie-core)
        │
        ▼  PCIe DMA write
   Host memory

With an optional DDR/HBM buffer (``MigDmaBuffer`` / ``HbmDmaBuffer``
from ``axi-pcie-core``):

.. code-block:: text

   PgpLaneRx → buffIbMasters → MigDmaBuffer → DDR/HBM → back to dmaIbMasters

The DDR/HBM buffer enables event-triggered readout — frames sit in
on-board memory until the host issues a read request via descriptor.

PGP TX Path  (Host DMA → Optical)
----------------------------------

.. code-block:: text

   Host memory
        │
        ▼  PCIe DMA read
   <Board>Core (axi-pcie-core)
        │  dmaObMasters
        ▼
   PgpLaneTx                                     <-- dmaClk
        │   ├── AxiStreamFlush (flushEn = NOT linkReady)
        │   └── surf.AxiStreamFifoV2 (async + resize)
        ▼                                        dmaClk → pgpClk
   surf.SsiInsertSof                            <-- pgpClk
        │
        ▼
   surf.AxiStreamDeMux  (route by tDest → VC)
        │
        ▼
   surf.Pgp4GtyUs  (GTY + PGP4 core)
        │
        ▼
   QSFP TX (serial)

The flush logic on link-down ensures that frames sourced from the host
do not stall the entire DMA path when the optical link goes down — they
are dropped in the ``AxiStreamFlush`` block until ``linkReady`` returns.

AXI-Lite Register Path  (Software → Firmware Registers)
--------------------------------------------------------

.. code-block:: text

   Python: rogue.hardware.axi.AxiMemMap('/dev/datadev_0')
        │  PCIe BAR0 reads/writes
        ▼
   <Board>Core (axi-pcie-core)
        │  AXI4 → AXI-Lite (AxiPcieReg)
        ▼
   appReadMaster / appWriteMaster                <-- appClk
        │
        ▼
   Top-level AxiLiteCrossbar (in <Target>.vhd)
        │
        ├── 0x00100000  MigDmaBuffer (optional)
        ├── 0x002–0x004…00000  Utility A/B/C
        └── 0x00800000  Hardware (PgpLaneWrapper)
                │
                ▼  per-lane crossbar (stride 0x10000)
            Lane[0..7]
                │
                ▼  per-lane internal crossbar
                ├── 0x0000  GT core
                ├── 0x1000  PGP monitor
                ├── 0x2000  Ctrl
                ├── 0x3000  TX stream monitor
                └── 0x4000  RX stream monitor

The full per-lane register layout is in :doc:`/reference/axi_lite_address_map`.

Back-Pressure Path  (DMA Pause → PGP Pause)
--------------------------------------------

``axi-pcie-core``'s DMA engine asserts ``dmaBuffGrpPause`` when host-side
DMA buffers fill up.  ``pgp-pcie-apps`` propagates that signal back into
two places:

* Into ``PgpLaneRx.disableSel`` — synchronised to ``pgpClk``, blocks
  ingress on the affected VCs to stop new frames being absorbed.
* Into ``pgpTxIn.locData(0)`` — synchronised, signals the **remote**
  end of the PGP link to pause via the PGP4 in-band flow-control
  channel.

This is the canonical SLAC two-sided back-pressure model: stop ingress
locally **and** ask the upstream sender to slow down.

State
-----

There is no shared global RTL state.  Every block holds only its own
local state, and inter-block signalling is exclusively through
AXI-Stream / AXI-Lite / well-documented sideband signals like
``dmaBuffGrpPause``.
