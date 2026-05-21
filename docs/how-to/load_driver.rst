Load the PCIe Kernel Driver
============================

``pgp-pcie-apps`` bitstreams are designed to be driven by the
``aes-stream-drivers`` Linux kernel module (``datadev.ko``).  Once the
module is loaded, each SLAC PCIe card appears as a ``/dev/datadev_<N>``
device node that the PyRogue scripts in :repo:`software/scripts/` use as
their ``AxiMemMap`` backend.

The driver lives in a separate repository
(`slaclab/aes-stream-drivers <https://github.com/slaclab/aes-stream-drivers>`_)
and is built from source.

Confirm the Board is Visible to the Host
-----------------------------------------

The SLAC PCIe cards enumerate as Vendor ID ``1a4a`` ("SLAC") and Product
ID ``2030`` ("AXI Stream DAQ"):

.. code-block:: bash

   lspci -nn | grep SLAC
   # Expected output:
   # 04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab \
   #   TID-AIR AXI Stream DAQ PCIe card [1a4a:2030]

If ``lspci`` shows nothing, the board is either not seated, not powered,
or running a firmware version that doesn't expose the SLAC VID/PID.
Re-program with a known-good ``.mcs`` (see
:doc:`/how-to/program_with_updatepciefpga`) or reseat the card.

Build the Driver
----------------

.. code-block:: bash

   git clone --recursive https://github.com/slaclab/aes-stream-drivers
   cd aes-stream-drivers/data_dev/driver/
   make

The build needs the running kernel's headers (``linux-headers-$(uname -r)``
on Debian/Ubuntu, ``kernel-devel`` on RHEL).

Load the Module
---------------

.. code-block:: bash

   sudo /sbin/insmod ./datadev.ko cfgSize=0x50000 cfgRxCount=256 cfgTxCount=16

The three ``cfg*`` parameters set the descriptor-ring sizes that the
driver allocates.  The defaults shown above are appropriate for every
target shipped from this repository — change them only if a specific
application requires a different DMA buffer budget.

Set Permissions and Verify
---------------------------

.. code-block:: bash

   sudo chmod 666 /proc/datadev_*
   cat /proc/datadev_0

The ``cat`` should print a status block reporting the driver version,
the number of open DMA channels, and per-channel queue depths.

After this point ``/dev/datadev_0`` (and ``/dev/datadev_1`` etc. for
multiple cards) is ready to be opened by
``rogue.hardware.axi.AxiMemMap`` from any PyRogue script — see
:doc:`/reference/pyrogue_scripts`.

Unload / Reload
---------------

To unload the module for a rebuild or a driver-config change:

.. code-block:: bash

   sudo /sbin/rmmod datadev

Then re-run ``insmod`` with the new ``.ko`` or new parameters.

Persistent Load at Boot
------------------------

For a permanent installation, copy ``datadev.ko`` into
``/lib/modules/$(uname -r)/extra/``, run ``depmod -a``, and add
``datadev`` (with the desired ``cfg*`` parameters) to
``/etc/modules-load.d/`` and ``/etc/modprobe.d/``.  See the
``aes-stream-drivers`` repository for the canonical procedure.

Troubleshooting
---------------

* **``/dev/datadev_0`` does not appear after ``insmod``** — check ``dmesg``;
  the most common cause is a kernel-header / kernel-binary mismatch
  (rebuild against ``$(uname -r)`` headers).
* **PCIe link goes down after reprogramming** — the running ``datadev``
  is still bound to the old BAR layout.  Rescan with
  :repo:`software/scripts/rescanPcieFpga.sh` or reboot.
* **Permission denied on ``/dev/datadev_*``** — apply ``chmod`` as
  shown above, or install ``udev`` rules from the ``aes-stream-drivers``
  repo for a permanent fix.
