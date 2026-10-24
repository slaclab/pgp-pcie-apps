Protocol Variants
=================

``pgp-pcie-apps`` carries four protocol layers under
``firmware/common/``.  They share the same DMA interface contract and
the same three-layer target decomposition (:doc:`/explanation/architecture`),
but differ in framing, line rate, and forward error correction.

Common Contract
---------------

Every protocol layer's ``Hardware`` entity exposes a common set of
ports:

* ``dmaClk`` / ``dmaRst`` from ``<Board>Core``
* ``dmaObMasters[N-1:0]`` / ``dmaObSlaves[N-1:0]`` (host → FPGA)
* ``dmaIbMasters[N-1:0]`` / ``dmaIbSlaves[N-1:0]`` (FPGA → host)
* ``axilReadMaster`` / ``axilReadSlave`` / ``axilWriteMaster`` /
  ``axilWriteSlave`` for protocol-layer registers
* The board's QSFP / SFP differential pairs

Generics and sideband ports differ by protocol (for example,
``pgpClkOut`` for PGP3/PGP4 versus ``pgpTxClkOut`` / ``pgpRxClkOut`` for
PGP2b, and ``RATE_G`` is absent for PGP2b).  Swapping protocols changes
the ``loadRuckusTcl`` line in ``ruckus.tcl`` plus a few lines in the
target VHDL: the ``surf`` package ``use`` clause, the ``pgpTxIn`` type,
``RATE_G``, and the clock port name (see :doc:`/how-to/select_protocol`).

PGP2b
-----

* **Line rate**: 3.125 Gbps (fixed by the ``surf`` GT IP cores).
* **Virtual channels**: up to 8 lanes × 4 VCs.
* **FEC**: none.
* **When to use**: legacy detectors; pre-existing PGP2b firmware
  ecosystems.

PGP3
----

* **Line rates**: 6.25, 10.3125 Gbps.
* **Virtual channels**: up to 8 lanes × 4 VCs.
* **FEC**: none.
* **When to use**: detectors and DAQ links in the 6.25 to 10 Gbps range
  where PGP2b is too slow.

PGP4
----

* **Line rates**: 6.25, 10.3125, 12.5, 15.46875, 25 Gbps.
* **Virtual channels**: up to 8 lanes × 4 VCs.
* **FEC**: optional RS-FEC, GTY only (exposed on ``XilinxVariumC1100``).
  Recommended at 25 Gbps, as in ``XilinxVariumC1100Pgp4_25Gbps_Fec``.
* **When to use**: default for new designs unless you need 100 Gbps.

PGP4 configuration is set by ``Hardware`` generics in the target's
``U_Hardware`` generic map:

* ``RATE_G : string``: line rate string (``"6.25Gbps"``,
  ``"10.3125Gbps"``, ``"12.5Gbps"``, ``"15.46875Gbps"``, ``"25.0Gbps"``).
  Drives QPLL configuration.
* ``PGP_FEC_ENABLE_G : boolean``: FEC enable (``XilinxVariumC1100``
  adapter only).

``NUM_VC_G`` is fixed at 4 inside each ``Hardware.vhd``.

HTSP
----

* **Aggregate rate**: 100 Gbps per QSFP (CAUI-4, 4 × 25.78125 Gbps).
* **Framing**: HTSP over the 802.3 100G Ethernet MAC (CMAC), with
  RS-FEC always enabled.
* **Virtual channels**: 4 per lane (``NUM_VC_G = 4``).
* **When to use**: detector farms or other workloads requiring 100 Gbps
  or more of aggregate throughput per cage.

HTSP replaces ``PgpLaneWrapper`` with ``HtspWrapper`` in the protocol
layer.  Software exercises it via
``software/scripts/HtspTesting.py``.  The per-lane register layout
differs from PGP; see ``HtspWrapper``'s own register set and
``pgp_pcie_apps.HtspRoot``.

Trade-Off Summary
-----------------

.. list-table::
   :header-rows: 1
   :widths: 14 18 18 18 32

   * - Protocol
     - Max line rate
     - FEC
     - VC model
     - Notes
   * - PGP2b
     - 3.125 Gbps (fixed)
     - No
     - Yes (4 VC)
     - Lowest complexity; legacy.
   * - PGP3
     - 10.3125 Gbps
     - No
     - Yes (4 VC)
     - Mid-range.
   * - PGP4
     - 25 Gbps
     - Optional, GTY only (recommended at 25 G)
     - Yes (4 VC)
     - Default for new designs.
   * - HTSP
     - 100 Gbps aggregate
     - RS-FEC (always on)
     - Yes (4 VC)
     - Use for high-rate detector farms.
