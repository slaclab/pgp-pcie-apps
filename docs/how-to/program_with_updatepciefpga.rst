Program a Board with ``updatePcieFpga.py``
==========================================

``software/scripts/updatePcieFpga.py``
(:repo:`software/scripts/updatePcieFpga.py`) programs a SPI/BPI
configuration PROM over PCIe and then rescans the PCIe bus so the new
bitstream becomes active.  This avoids a JTAG cable round trip when
you just want to swap firmware on an in-rack card.

Prerequisites
-------------

- A PCIe-attached SLAC card with the ``aes-stream-drivers`` kernel
  module loaded (``/dev/datadev_0`` present); see
  :doc:`/how-to/load_driver`.
- The card already runs a working ``axi-pcie-core``-based bitstream
  with the SPI/BPI PROM access path exposed via the PyRogue device
  tree.  Every target includes this except the ``AlphaDataKu3`` ones;
  on ``*BifurcatedPcie`` cards use the primary endpoint's
  ``/dev/datadev_*``.
- A ``.mcs`` (or ``.mcs.gz``) file produced by a prior ``make`` (see
  :doc:`/tutorial/first_build`).  The script takes a directory, not a
  filename.
- The Rogue environment activated (``source software/setup_env_slac.sh``
  at SLAC S3DF, ``source software/cds_env_setup.sh`` at PCDS/CDS, or
  any equivalent environment that supplies ``rogue`` v6.5.0 or later).

Usage
-----

The script lists the ``.mcs`` / ``.mcs.gz`` images in the ``--path``
directory (images matching the running ``ImageName`` first) and prompts
you to choose one; it asks for confirmation if the chosen image does not
match the running firmware.  SPIx8 boards need both the ``_primary`` and
``_secondary`` files.  Programming the PROM requires root (the script
issues a PCIe rescan via ``sysfs``):

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
     - ``None``
     - Image directory (required unless ``--package`` or
       ``--bypass_reprogramming true`` is given).
   * - ``--package <module>``
     - ``None``
     - Python package to import; its ``ImageDir`` attribute is used as
       the image directory.
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

How Long It Takes
~~~~~~~~~~~~~~~~~

A typical SPIx4 program and verify of a single-chip Varium C1100 MCS
takes roughly 5 to 15 minutes.  Most of that time is spent in PROM
erase/program cycles, not the PCIe rescan.

Troubleshooting
---------------

Permission denied
   The driver creates ``/dev/datadev_*`` with ``0666`` permissions, but
   the PCIe rescan writes to ``sysfs``, so run the script with ``sudo``
   as shown in `Usage`_.  See :doc:`/how-to/load_driver`.

"Unable to reprogram FPGA as lost of PCIe link."
   The running driver lost the BAR window.  Run
   ``firmware/submodules/axi-pcie-core/scripts/rescanPcieFpga.sh`` or
   reboot the host to recover.

"Programming (.mcs, .mcs.gz) files NOT detected in the --path arg directory"
   Confirm the ``images/`` directory actually contains a ``.mcs`` (or
   ``.mcs.gz``).  With ``GEN_MCS_IMAGE=0`` (and ``GEN_MCS_IMAGE_GZIP=0``)
   no ``.mcs`` is copied into ``images/``.

MCS file too big
   If ``write_cfgmem`` reports a size error during the original
   ``make``, check the configured ``size`` parameter (in MB) in the
   target's ``vivado/promgen.tcl``.
