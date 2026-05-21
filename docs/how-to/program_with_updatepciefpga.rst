Program a Board with ``updatePcieFpga.py``
============================================

``software/scripts/updatePcieFpga.py``
(:repo:`software/scripts/updatePcieFpga.py`) programs a SPI/BPI
configuration PROM over PCIe and then rescans the PCIe bus so the new
bitstream becomes active.  This avoids the JTAG cable round-trip when
you just want to swap firmware on an in-rack card.

Prerequisites
-------------

- A PCIe-attached SLAC card with the ``aes-stream-drivers`` kernel
  module loaded (``/dev/datadev_0`` present) — see
  :doc:`/how-to/load_driver`.
- The card already runs a working ``axi-pcie-core``-based bitstream
  with the SPI/BPI PROM access path exposed via the PyRogue device
  tree.  (Every target built from ``pgp-pcie-apps`` includes this.)
- A ``.mcs`` (or ``.mcs.gz``) file produced by a prior ``make`` (see
  :doc:`/tutorial/first_build`) — the script picks the file up from a
  directory, not by filename.
- The Rogue environment activated (``source software/setup_env_slac.sh``
  at SLAC S3DF, ``source software/cds_env_setup.sh`` at PCDS/CDS, or
  any equivalent env that supplies ``rogue`` ≥ v6.5.0).

Usage
-----

The script takes a directory of images via ``--path`` and finds the
``.mcs`` / ``.mcs.gz`` inside.  Programming the PROM requires root (the
script issues a PCIe rescan via ``sysfs``):

.. code-block:: bash

   cd software/scripts
   sudo $(which python) updatePcieFpga.py \
       --path ../../firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/images/

Useful CLI flags (defined in
:repo:`software/scripts/updatePcieFpga.py`):

.. list-table::
   :header-rows: 1
   :widths: 30 20 50

   * - Flag
     - Default
     - Effect
   * - ``--dev <path>``
     - ``/dev/datadev_0``
     - Pick a specific card when multiple are installed.
   * - ``--path <dir>``
     - (required)
     - Directory containing the ``.mcs`` or ``.mcs.gz`` to program.
   * - ``--package <dir>``
     -
     - Alternate path used by the Debian package install.
   * - ``--rescan true|false``
     - ``true``
     - Skip the PCIe-rescan step if you plan to reboot instead.
   * - ``--bypass_reprogramming true|false``
     - ``false``
     - Debug only: skip the actual PROM write, exercise the rescan path.

After Programming
~~~~~~~~~~~~~~~~~

If you ran with ``--rescan true`` (the default), the new bitstream is
already active on the same PCIe bus address.  If you set
``--rescan false`` (or the script reports that it could not rescan),
reboot the host:

.. code-block:: bash

   sudo reboot

How long it takes
~~~~~~~~~~~~~~~~~

A typical SPIx4 program + verify of a single-chip Varium C1100 MCS is
roughly 5–15 minutes — most of the time is in PROM erase/program
cycles, not the PCIe rescan.

Troubleshooting
---------------

* **Permission denied on ``/dev/datadev_0``** — running as a non-root
  user needs ``udev`` rules from ``aes-stream-drivers`` to be
  installed, or run via ``sudo``.  See :doc:`/how-to/load_driver`.
* **"Unable to reprogram FPGA as loss of PCIe link"** — the in-running
  driver lost the BAR window.  Use
  :repo:`software/scripts/rescanPcieFpga.sh` to recover, or reboot.
* **"Programming (.mcs, .mcs.gz) files NOT detected in the --path arg
  directory"** — confirm the ``images/`` directory actually contains a
  ``.mcs`` (or ``.mcs.gz``); a ``make`` that ran with
  ``GEN_MCS_IMAGE=0`` produces no PROM file.
* **MCS file too big** — ``XilinxVariumC1100`` uses a 1 GB SPI Flash;
  bitstreams from ``axi-pcie-core``-based projects fit comfortably.
  If ``write_cfgmem`` errors out about size during the original
  ``make``, check :repo:`firmware/targets/<Board>/<Target>/vivado/promgen.tcl`
  for the configured ``size`` parameter.
