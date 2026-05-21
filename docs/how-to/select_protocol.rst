Select a Protocol — PGP2b vs PGP3 vs PGP4 vs HTSP
==================================================

Each board+target chooses one protocol layer from
``firmware/common/<proto>/``.  Use this table to pick the right one.

Decision Matrix
---------------

.. list-table::
   :header-rows: 1
   :widths: 14 14 18 24 30

   * - Protocol
     - Line rates
     - Lanes / VCs
     - Forward error correction
     - When to choose
   * - **PGP2b**
     - 1.25, 2.5, 3.125 Gbps
     - up to 8 / 4 VC
     - No
     - Legacy detectors; existing PGP2b firmware ecosystems.
   * - **PGP3**
     - 6.25, 10.3125 Gbps
     - up to 8 / 4 VC
     - Optional (PGP3 RS-FEC)
     - Mid-rate links; broad camera/detector support.
   * - **PGP4**
     - 6.25, 10.3125, 12.5, 15.46875, 25 Gbps
     - up to 8 / 4 VC
     - Optional (PGP4 RS-FEC; required at 25 Gbps)
     - Default for new designs unless 100G is needed.
   * - **HTSP**
     - 100 Gbps (4 × 25 GbE lanes per QSFP)
     - 1 / N
     - 802.3 RS-FEC (KP-FEC)
     - When you need ≥100 Gbps aggregate, e.g. detector farms.

Where to Find the Layer
------------------------

For each protocol, the RTL lives under:

.. code-block:: text

   firmware/common/<proto>/
       hardware/<Board>/core/Hardware.vhd       # board adapter
       shared/rtl/PgpLaneRx.vhd                  # RX VC path
       shared/rtl/PgpLaneTx.vhd                  # TX VC path
       shared/rtl/gtyUs+/PgpGtyLane.vhd          # GTY UltraScale+ lane
       shared/rtl/gthUs/PgpLane.vhd              # GTH UltraScale lane

Replace ``pgp4`` with ``pgp2b`` / ``pgp3`` / ``htsp`` (HTSP uses an
``HtspWrapper`` + ``HtspRxFifo`` / ``HtspTxFifo`` instead of
``PgpLane*``).

Switching Protocols on an Existing Board
-----------------------------------------

Suppose ``XilinxVariumC1100Pgp4_6Gbps`` works and you want a PGP3
variant.

1. Clone the target directory:

   .. code-block:: bash

      cp -r firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps \
            firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp3_6Gbps

2. Edit the new top-level VHDL.  Find the ``Hardware`` entity
   instantiation and re-target the library:

   .. code-block:: vhdl

      -- before
      U_Hardware : entity work.Hardware  -- from common/pgp4/hardware/<Board>/core/

      -- after — same entity name, but bound to the pgp3 library
      -- Achieved by changing the ruckus.tcl loadRuckusTcl line below.

3. Edit the new ``ruckus.tcl``:

   .. code-block:: tcl

      # before
      loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp4/hardware/XilinxVariumC1100

      # after
      loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp3/hardware/XilinxVariumC1100

   Confirm that ``firmware/common/pgp3/hardware/XilinxVariumC1100/`` exists
   for that board+protocol pair — not every board ships every protocol.

4. Update ``RATE_G`` to a PGP3-supported value (PGP3 does not support
   line rates above 10.3125 Gbps).

5. Build and verify with :doc:`/how-to/run_pgp_testing`.

HTSP Differs
~~~~~~~~~~~~

HTSP uses 100 GbE-style framing rather than the PGP virtual-channel
model.  The Hardware adapter instantiates ``HtspWrapper`` instead of
``PgpLaneWrapper``; the software path uses ``software/scripts/HtspTesting.py``
instead of ``PgpTesting.py``.  See :doc:`/explanation/protocol_variants`
for the architectural differences.
