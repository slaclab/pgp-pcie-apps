Clock Domains
=============

A typical PGP target runs three principal clock domains.  Knowing which
signals live in which domain, and where the synchronizers sit, is the
key to reading the RTL without getting lost.

The Three Domains
-----------------

``dmaClk`` (250 MHz nominal)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: ``<Board>Core.dmaClk`` output, the PCIe hard-IP user clock
exposed by the PHY wrapper to the rest of the design.

Lives here:

* The DMA engine internals (``AxiPcieDma`` + ``AxiStreamDmaV2``).
* The PCIe AXI4 interface to the PHY.
* The application side of every ``dmaObMasters`` / ``dmaIbMasters``
  pair.

The DMA bus width (``DMA_AXIS_CONFIG_G``) is set per target (for
example, 8 bytes on the ``XilinxVariumC1100`` PGP4 targets and 64 bytes
on ``XilinxVariumC1100DmaLoopback``); the shared
``PgpLaneRx`` / ``PgpLaneTx`` auto-resize between this width and the
fixed protocol-layer width (``PGP4_AXIS_CONFIG_C``).

``axilClk`` (typically 156.25 MHz)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: a ``ClockManagerUltraScale`` MMCM in the target top-level.
Its input depends on the board: the 156.25 MHz ``userClk156`` on
``XilinxAlveoU200`` and the ``XilinxKcu1500`` PGP3/PGP4 targets, the
100 MHz ``userClk`` on ``XilinxVariumC1100``, and ``dmaClk`` on
``SlacPgpCardG4`` and ``XilinxKcu1500Pgp2b``.

Lives here:

* The AXI-Lite register tree from BAR0 onwards.
* The application-region crossbar.
* Most per-lane control + monitor logic.

The boundary between ``dmaClk`` and ``axilClk`` is handled inside
``axi-pcie-core`` (``AxiPcieReg`` uses ``surf.AxiLiteAsync``).

``pgpClk`` (per-lane, GT-recovered)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: the per-lane GT TX user clock that ``surf.Pgp4GtyUs`` (or
``Pgp3GtyUs``) exports as ``pgpClk``; the PGP RX user interface runs on
the same clock, so there is one ``pgpClk`` per lane.  (PGP2b instead
exports separate ``pgpTxClk`` / ``pgpRxClk``.)  The GT runs 64b66b with
a 64-bit user interface, so ``pgpClk`` is the line rate divided by 66:
about 94.7 MHz at 6.25 Gbps and 156.25 MHz at 10.3125 Gbps.

Lives here:

* ``PgpLaneRx`` ingress path (per-VC FIFOs, Mux to a single stream).
* ``PgpLaneTx`` final stages after the DMA crossing
  (``SsiInsertSof``, ``AxiStreamDeMux`` to VCs, the GT TX side).
* The per-lane PGP framer state in ``surf.Pgp4GtyUs``.

Crossings
---------

Every domain crossing in the application layer uses one of two
``surf`` primitives:

* **Stream crossings**: ``surf.AxiStreamFifoV2`` with
  ``GEN_SYNC_FIFO_G => false``.  Used for ``pgpClk ↔ dmaClk`` (PGP RX,
  PGP TX) and for any ``dmaClk ↔ axilClk`` stream crossing (rare).
* **Single-bit / vector crossings**: ``surf.Synchronizer`` and
  ``surf.SynchronizerVector``.  Used for ``dmaBuffGrpPause`` propagation
  into ``pgpClk``, and for the DDR buffer's ``eventTrigMsgCtrl.pause``
  into ``pgpClk`` where it drives ``pgpTxIn.locData(0)`` (not needed on
  ``XilinxVariumC1100``, where ``HbmDmaBuffer`` already outputs on
  ``pgpClk``).

No combinational paths cross domain boundaries.  Every crossing uses an
explicit ``surf`` synchronizer primitive; besides the two above, the
design also uses ``AxiLiteAsync`` (inside ``AxiPcieReg``), ``RstSync``,
and asynchronous ``AxiStreamMonAxiL`` instances.

Why dmaClk Is 250 MHz
---------------------

``dmaClk`` is the 250 MHz user clock of the PCIe hard IP, so its
frequency is fixed by the PCIe PHY IP configuration in
``axi-pcie-core``.  ``DMA_CLK_FREQ_C`` in each board's
``AxiPciePkg.vhd`` records that value for consumers such as
``AxiPcieReg`` and ``AxiPcieDma``.  Changing it is not a per-target
decision.

Implications for Application Design
-----------------------------------

* If you add a custom DMA sink in the application, it must run on
  ``dmaClk`` (or cross into your own clock with a
  ``surf.AxiStreamFifoV2``).
* If you add custom AXI-Lite registers, expose them on ``axilClk``;
  ``AxiPcieReg`` already handles the BAR0 ↔ ``axilClk`` crossing.
* Do **not** introduce a fourth global clock unless you have a
  documented reason.  Adding domains is the most common source of
  timing failures in this codebase.
