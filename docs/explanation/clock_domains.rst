Clock Domains
=============

A typical PGP target runs three principal clock domains.  Understanding
which signals live in which domain — and where the synchronisers sit —
is the only way to read the RTL without getting lost.

The Three Domains
-----------------

``dmaClk``  (250 MHz nominal)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: ``<Board>Core.dmaClk`` output.  Derived from the PCIe PHY's
recovered reference clock and exposed back to the rest of the design.

Lives here:

* The DMA engine internals (``AxiPcieDma`` + ``AxiStreamDmaV2``).
* The PCIe AXI4 interface to the PHY.
* The application side of every ``dmaObMasters`` / ``dmaIbMasters``
  pair.

The DMA bus width (``DMA_AXIS_CONFIG_G``) is per-board; the shared
``PgpLaneRx`` / ``PgpLaneTx`` auto-resize between this width and the
fixed protocol-layer width (``PGP4_AXIS_CONFIG_C``).

``axilClk``  (typically 156.25 MHz)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: ``userClk156`` from the board (gigabit reference clock divider),
optionally divided down by a ``ClockManagerUltraScale`` MMCM in the
target top-level.

Lives here:

* The AXI-Lite register tree from BAR0 onwards.
* The application-region crossbar.
* Most per-lane control + monitor logic.

The boundary between ``dmaClk`` and ``axilClk`` is handled inside
``axi-pcie-core`` (``AxiPcieReg`` uses ``surf.AxiLiteAsync``).

``pgpClk``  (per-lane, GT-recovered)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: ``surf.Pgp4GtyUs`` recovered RX clock per lane (PGP3/PGP4
provide an explicit recovered clock per direction).  The exact
frequency is line-rate-dependent — for example PGP4 @ 6.25 Gbps yields
156.25 MHz, PGP4 @ 25 Gbps yields 390.625 MHz.

Lives here:

* ``PgpLaneRx`` ingress path (per-VC FIFOs, Mux to a single stream).
* ``PgpLaneTx`` final stages after the DMA crossing
  (``SsiInsertSof``, ``AxiStreamDeMux`` to VCs, the GT TX side).
* The per-lane PGP framer state in ``surf.Pgp4GtyUs``.

Crossings
---------

Every domain crossing in the application layer uses one of two
``surf`` primitives:

* **Stream crossings** — ``surf.AxiStreamFifoV2`` with
  ``GEN_SYNC_FIFO_G => false``.  Used for ``pgpClk ↔ dmaClk`` (PGP RX,
  PGP TX) and for any ``dmaClk ↔ axilClk`` stream crossing (rare).
* **Single-bit / vector crossings** — ``surf.Synchronizer`` and
  ``surf.SynchronizerVector``.  Used for ``dmaBuffGrpPause`` propagation
  into ``pgpClk`` and for ``pgpTxIn.locData(0)`` toggles.

No combinational paths cross domain boundaries.  Every crossing is
explicit in the RTL via one of those two primitives.

Why dmaClk is 250 MHz
----------------------

The 250 MHz figure is set by ``DMA_CLK_FREQ_C`` in
``axi-pcie-core``'s per-board ``AxiPciePkg.vhd``.  It is the highest
clock frequency that meets timing on all 14 supported boards with the
standard ``AxiStreamDmaV2`` instantiation.  Raising it would require
re-timing the DMA engine and is not a per-target decision.

Implications for Application Design
------------------------------------

* If you add a custom DMA sink in the application, it must run on
  ``dmaClk`` (or cross into your own clock with a
  ``surf.AxiStreamFifoV2``).
* If you add custom AXI-Lite registers, expose them on ``axilClk``;
  ``AxiPcieReg`` already handles the BAR0 ↔ ``axilClk`` crossing.
* Do **not** introduce a fourth global clock unless you have a
  documented reason.  Adding domains is the most common source of
  timing failures in this codebase.
