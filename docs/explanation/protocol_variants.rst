Protocol Variants
=================

``pgp-pcie-apps`` carries four protocol layers under
``firmware/common/``.  They share the same DMA interface contract and
the same three-layer target decomposition (:doc:`/explanation/architecture`),
but differ in framing, line rate, and forward error correction.

Common Contract
---------------

Every protocol layer exposes the same ``Hardware`` entity signature:

* ``dmaClk`` / ``dmaRst`` from ``<Board>Core``
* ``dmaObMasters[N-1:0]`` / ``dmaObSlaves[N-1:0]`` (host → FPGA)
* ``dmaIbMasters[N-1:0]`` / ``dmaIbSlaves[N-1:0]`` (FPGA → host)
* ``axilReadMaster`` / ``axilReadSlave`` / ``axilWriteMaster`` /
  ``axilWriteSlave`` for protocol-layer registers
* The board's QSFP / SFP differential pairs

Targets swap one protocol for another by changing exactly one
``loadRuckusTcl`` line in their ``ruckus.tcl`` (see
:doc:`/how-to/select_protocol`).

PGP2b
-----

* **Line rates**: 1.25, 2.5, 3.125 Gbps.
* **Virtual channels**: up to 8 lanes × 4 VCs.
* **FEC**: none.
* **When to use**: legacy detectors; pre-existing PGP2b firmware
  ecosystems.

PGP3
----

* **Line rates**: 6.25, 10.3125 Gbps.
* **VCs**: up to 8 lanes × 4 VCs.
* **FEC**: optional Reed-Solomon (PGP3 RS-FEC).
* **When to use**: detectors and DAQ links in the 6.25–10 Gbps range
  where PGP2b is too slow.

PGP4
----

* **Line rates**: 6.25, 10.3125, 12.5, 15.46875, 25 Gbps.
* **VCs**: up to 8 lanes × 4 VCs.
* **FEC**: optional Reed-Solomon (PGP4 RS-FEC).  Required at 25 Gbps.
* **When to use**: default for new designs unless you need 100 Gbps.

Three target-level generics drive PGP4 configuration:

* ``RATE_G : string`` — line rate string ("6.25Gbps", "10.3125Gbps",
  "12.5Gbps", "15.46875Gbps", "25Gbps").  Drives QPLL configuration.
* ``NUM_VC_G : positive`` — VC count (typically 4).
* ``PGP_FEC_ENABLE_G : boolean`` — FEC enable.  Must be ``true`` at
  25 Gbps; optional at lower rates.

HTSP
----

* **Aggregate rate**: 100 Gbps per QSFP (4 × 25 GbE lanes).
* **Framing**: 802.3 Ethernet-style with KP-FEC; not VC-based.
* **When to use**: detector farms or other workloads requiring ≥100 Gbps
  aggregate throughput per cage.

HTSP replaces ``PgpLaneWrapper`` with ``HtspWrapper`` in the protocol
layer.  Software exercises it via
``software/scripts/HtspTesting.py``.  Because HTSP is not VC-based, the
per-lane register layout differs from PGP — see ``HtspWrapper``'s own
register set.

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
     - 3.125 Gbps
     - No
     - Yes (4 VC)
     - Lowest complexity; legacy.
   * - PGP3
     - 10.3125 Gbps
     - Optional
     - Yes (4 VC)
     - Mid-range.
   * - PGP4
     - 25 Gbps
     - Optional (req'd at 25 G)
     - Yes (4 VC)
     - Default for new designs.
   * - HTSP
     - 100 Gbps aggregate
     - KP-FEC (mandatory)
     - No (single stream)
     - Use for high-rate detector farms.
