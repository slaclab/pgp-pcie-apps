Select a Protocol: PGP2b vs PGP3 vs PGP4 vs HTSP
================================================

Each target chooses one protocol layer from
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
     - 3.125 Gbps (fixed)
     - up to 8 / 4 VC
     - No
     - Legacy detectors; existing PGP2b firmware ecosystems.
   * - **PGP3**
     - 6.25, 10.3125 Gbps
     - up to 8 / 4 VC
     - No
     - Mid-rate links; broad camera/detector support.
   * - **PGP4**
     - 6.25, 10.3125, 12.5, 15.46875, 25 Gbps (25 Gbps on GTY boards
       only; GTH tops out at 15.46875 Gbps)
     - up to 8 / 4 VC
     - Optional RS-FEC (``PGP_FEC_ENABLE_G``, ``XilinxVariumC1100``
       adapter only; used by the 25 Gbps target)
     - Default for new designs unless 100G is needed.
   * - **HTSP**
     - 100 Gbps (CAUI-4 per QSFP)
     - 2 (one CAUI-4 link per QSFP) / 4 VC
     - IEEE 802.3 RS-FEC (CMAC ``INCLUDE_RS_FEC``, always on)
     - When you need 100 Gbps or more aggregate, e.g., detector farms.

Where to Find the Layer
-----------------------

For each protocol, the RTL lives under:

.. code-block:: text

   firmware/common/<proto>/
       hardware/<Board>/core/Hardware.vhd       # board adapter
       shared/rtl/PgpLaneRx.vhd                  # RX VC path
       shared/rtl/PgpLaneTx.vhd                  # TX VC path
       shared/rtl/gtyUs+/PgpGtyLane.vhd          # GTY UltraScale+ lane
       shared/rtl/gthUs/PgpLane.vhd              # GTH UltraScale lane

The layout shown is for ``pgp3`` / ``pgp4``.  ``pgp2b`` keeps some
adapters under ``hardware/<Board>/rtl/`` and uses
``shared/rtl/gtyUs+/PgpLane.vhd`` (no ``PgpGtyLane``).  HTSP uses
``shared/rtl/gtyUs+/HtspWrapper.vhd`` plus ``shared/rtl/HtspRxFifo.vhd``
/ ``HtspTxFifo.vhd`` instead of ``PgpLane*``, and is GTY-only.

Switching Protocols on an Existing Board
----------------------------------------

Suppose ``XilinxKcu1500Pgp4_6Gbps`` works and you want a PGP3
variant.  (``XilinxKcu1500Pgp3_6Gbps`` already exists and is exactly
this change, so use it as the reference.)

1. Clone the target directory under a new name and rename the files and
   entity per :doc:`/how-to/add_new_board_target`.

2. Edit the new top-level VHDL.  The ``U_Hardware : entity
   work.Hardware`` line stays the same, but the protocol package and the
   ``pgpTxIn`` type change:

   .. code-block:: vhdl

      -- before
      use surf.Pgp4Pkg.all;
      signal pgpTxIn : Pgp4TxInArray(7 downto 0) := (others => PGP4_TX_IN_INIT_C);

      -- after
      use surf.Pgp3Pkg.all;
      signal pgpTxIn : Pgp3TxInArray(7 downto 0) := (others => PGP3_TX_IN_INIT_C);

3. Edit the new ``ruckus.tcl``:

   .. code-block:: tcl

      # before
      loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp4/hardware/XilinxKcu1500

      # after
      loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp3/hardware/XilinxKcu1500

   Confirm that ``firmware/common/pgp3/hardware/<Board>/`` exists for
   your board; not every board ships every protocol (for example, there
   is no PGP3 adapter for ``XilinxVariumC1100``).

4. Update ``RATE_G`` to a value supported by the PGP3 GT wrapper for
   your board (existing PGP3 targets use 6.25 and 10.3125 Gbps).

5. Build and verify with :doc:`/how-to/run_pgp_testing`.

HTSP Differs
~~~~~~~~~~~~

HTSP runs over a 100G CAUI-4 Ethernet MAC instead of a PGP GT lane, but
still carries ``NUM_VC_G`` (4) virtual channels.  The ``Hardware``
adapter instantiates ``HtspWrapper`` instead of ``PgpLaneWrapper``; the software path uses ``software/scripts/HtspTesting.py``
instead of ``PgpTesting.py``.  See :doc:`/explanation/protocol_variants`
for the architectural differences.
