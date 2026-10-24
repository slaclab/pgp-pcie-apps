Data Flow
=========

Four independent flows cross the design.  Each has a documented entry
point and a documented synchronizer at every clock-domain boundary.

PGP RX Path (Optical → Host DMA)
--------------------------------

.. code-block:: text

   QSFP RX (serial)
        │
        ▼
   surf.Pgp4GtyUs  (GTY + PGP4 core)            <-- pgpClk
        │
        ▼  per-VC AXI-Stream
   PgpLaneRx                                     <-- pgpClk
        │   ┌── rxlinkReady blowoff filter
        │   ├── per-VC FIFO with resize to the DMA width
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

The DDR/HBM buffer is a large elastic FIFO (``AxiStreamDmaV2Fifo``)
that absorbs bursts when host DMA cannot keep up.  It drains to
``dmaIbMasters`` on its own; its almost-full pause is exported as
``eventTrigMsgCtrl`` (see the back-pressure section below).

The per-VC RX FIFO is URAM-backed (4 x 4k deep) in the PGP4 GTY lane and
block RAM (4k deep) elsewhere.

PGP TX Path (Host DMA → Optical)
--------------------------------

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

The flush logic ensures that frames sourced from the host do not stall
the entire DMA path when the optical link goes down; they are dropped in
the ``AxiStreamFlush`` block until ``linkReady`` returns.

AXI-Lite Register Path (Software → Firmware Registers)
------------------------------------------------------

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
        ├── 0x00100000  MigDmaBuffer / HbmDmaBuffer (optional)
        ├── 0x00200000-0x00400000  unused on PGP targets
        └── 0x00800000  Hardware (PgpLaneWrapper)
                │
                ▼  per-lane crossbar (stride 0x10000)
            Lane[0..7]
                │
                ▼  per-lane internal crossbar
                ├── 0x0000  PGP core monitor (PGP3/PGP4)
                ├── 0x1000  GT DRP (PGP3/PGP4, inside the PGP core)
                ├── 0x3000  TX stream monitor
                └── 0x4000  RX stream monitor

The full per-lane register layout is in :doc:`/reference/axi_lite_address_map`.

Back-Pressure Path (DMA Pause → PGP Pause)
------------------------------------------

Two signals carry back-pressure toward the remote end of the link:

* ``axi-pcie-core``'s DMA engine asserts ``dmaBuffGrpPause`` when
  host-side DMA buffers fill up.  ``PgpLaneRx`` synchronizes it to
  ``pgpClk`` and drives the ``AxiStreamMux`` ``disableSel``, so the
  affected per-VC FIFOs stop draining.  As they fill, they assert
  ``pgpRxCtrl.pause``, which the PGP core turns into in-band flow
  control to the remote sender.
* On targets with a DDR/HBM buffer, the buffer's
  ``eventTrigMsgCtrl.pause`` is sent to the remote end as the user
  sideband bit ``pgpTxIn.locData(0)``, for the remote application to act
  on.

Together these stop ingress locally **and** tell the upstream sender to
slow down.

State
-----

There is no shared global RTL state.  Every block holds only its own
local state, and inter-block signalling is exclusively through
AXI-Stream / AXI-Lite / well-documented sideband signals like
``dmaBuffGrpPause``.
