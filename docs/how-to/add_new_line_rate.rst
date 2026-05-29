Add a New Line Rate
===================

PGP4, PGP3, PGP2b, and HTSP each support a small set of line rates.  Add
a new rate by cloning an existing target and changing the ``RATE_G``
generic.

Procedure
---------

1. Identify the closest existing target.  Example: starting from
   ``XilinxKcu1500Pgp4_6Gbps`` to add ``XilinxKcu1500Pgp4_10Gbps``.

2. Clone the directory and rename per
   :doc:`/how-to/add_new_board_target`.

3. Open the new top-level VHDL.  Find the ``RATE_G`` generic on the
   ``Hardware`` (or equivalent ``PgpLaneWrapper``) instantiation and set
   it to the new rate.  Valid strings:

   * ``"6.25Gbps"``
   * ``"10.3125Gbps"``
   * ``"12.5Gbps"``
   * ``"15.46875Gbps"``
   * ``"25Gbps"`` (PGP4 with FEC only)

   The exact set of supported strings is encoded in the shared
   protocol layer — search ``firmware/common/<proto>/shared/rtl/`` for
   the ``RATE_G`` generic's case statement to see what's mapped.

4. For PGP4 25 Gbps targets, also set ``PGP_FEC_ENABLE_G => true`` (FEC
   is required at that line rate).

5. The QPLL configuration is auto-selected from ``RATE_G`` inside
   ``PgpLaneWrapper`` / ``PgpGtyLaneWrapper`` — you should not need to
   touch the QPLL primitive generics directly.

6. Build with ``make``.

Verification
------------

After the build completes:

- ``make`` exits 0, no critical warnings beyond the documented PCIe PHY
  black-box messages (see :doc:`/tutorial/first_build`).
- Vivado timing report shows no failing endpoints at the new clock rate.
- After flashing, run ``software/scripts/PgpTesting.py`` against the
  board and confirm the PRBS bit-error counters stay at zero
  (:doc:`/how-to/run_pgp_testing`).

Cross-References
----------------

- :doc:`/explanation/protocol_variants` — line-rate vs FEC vs PGP
  generation matrix.
- :doc:`/explanation/clock_domains` — what ``RATE_G`` actually drives
  (QPLL ref, GTY line rate, FIFO crossings).
