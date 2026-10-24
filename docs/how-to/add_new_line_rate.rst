Add a New Line Rate
===================

PGP3 and PGP4 targets select their line rate with the ``RATE_G``
generic.  Add a new rate by cloning an existing target and changing it.
PGP2b (fixed 3.125 Gbps GT IP) and HTSP (fixed 100G CAUI-4) have no rate
generic.

Procedure
---------

1. Identify the closest existing target.  For example, start from
   ``XilinxKcu1500Pgp4_10Gbps`` to add ``XilinxKcu1500Pgp4_12Gbps``
   (``"12.5Gbps"``).

2. Clone the directory and rename per
   :doc:`/how-to/add_new_board_target`.

3. Open the new top-level VHDL.  Find the ``RATE_G`` generic on the
   ``Hardware`` (or equivalent ``PgpLaneWrapper``) instantiation and set
   it to the new rate.  Strings used by existing targets:

   * ``"6.25Gbps"``
   * ``"10.3125Gbps"``
   * ``"12.5Gbps"``
   * ``"15.46875Gbps"``
   * ``"25.0Gbps"`` (PGP4, GTY boards only)

   The exact set of supported strings differs between GTY and GTH.  GTY
   rates are decoded in
   ``firmware/submodules/surf/protocols/pgp/pgp3/gtyUs+/rtl/Pgp3GtyUsIpWrapper.vhd``
   and ``Pgp3GtyUsQpll.vhd`` (shared by PGP3 and PGP4).  GTH rates are
   limited by the assert in ``pgp4/gthUs/rtl/Pgp4GthUs.vhd`` (up to
   ``"15.46875Gbps"``).

4. The existing 25 Gbps target (``XilinxVariumC1100Pgp4_25Gbps_Fec``)
   also sets ``PGP_FEC_ENABLE_G => true`` to enable RS-FEC.  That generic
   is only exposed by the ``XilinxVariumC1100`` PGP4 adapter.

5. The QPLL configuration is auto-selected from ``RATE_G`` inside
   ``PgpLaneWrapper`` / ``PgpGtyLaneWrapper``, so you should not need to
   touch the QPLL primitive generics directly.

6. Build with ``make``.

Verification
------------

After the build completes:

- ``make`` exits 0 with no critical warnings beyond the expected ones
  for the board (see :doc:`/tutorial/first_build` for
  ``XilinxVariumC1100``).
- The Vivado timing report shows no failing endpoints at the new clock
  rate.
- After flashing, run ``software/scripts/PgpTesting.py`` against the
  board and confirm the PRBS bit-error counters stay at zero
  (:doc:`/how-to/run_pgp_testing`).

Cross-References
----------------

- :doc:`/explanation/protocol_variants`: line rate vs FEC vs PGP
  generation matrix.
- :doc:`/explanation/clock_domains`: what ``RATE_G`` actually drives
  (QPLL reference, GTY line rate, FIFO crossings).
