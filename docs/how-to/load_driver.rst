Load the PCIe Kernel Driver
===========================

``pgp-pcie-apps`` bitstreams are designed to be driven by the
``aes-stream-drivers`` Linux kernel module (``datadev.ko``).  Once the
module is loaded, each SLAC PCIe card appears as a ``/dev/datadev_<N>``
device node that the PyRogue scripts in :repo:`software/scripts/` use as
their ``AxiMemMap`` backend.

The driver lives in a separate repository
(`slaclab/aes-stream-drivers <https://github.com/slaclab/aes-stream-drivers>`_)
and is built from source.

Confirm the Board Is Visible to the Host
----------------------------------------

The SLAC PCIe cards enumerate as Vendor ID ``1a4a`` ("SLAC") and Product
ID ``2030`` ("AXI Stream DAQ"):

.. code-block:: bash

   lspci -nn | grep SLAC
   # Expected output:
   # 04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab \
   #   TID-AIR AXI Stream DAQ PCIe card [1a4a:2030]

If ``lspci`` shows nothing, the board is not seated, not powered,
or running firmware that does not expose the SLAC VID/PID.  Reprogram
it with a known-good ``.mcs`` (see
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

The three ``cfg*`` parameters set the DMA buffer size and the RX/TX
buffer counts that the driver allocates.  The values shown above are
appropriate for every target shipped from this repository; change them
only if a specific application requires a different DMA buffer budget.

Set Permissions and Verify
--------------------------

.. code-block:: bash

   sudo chmod 666 /proc/datadev_*
   cat /proc/datadev_0

The ``cat`` should print a status block reporting the driver version,
the number of open DMA channels, and per-channel queue depths.

From this point, ``/dev/datadev_0`` (and ``/dev/datadev_1`` etc. for
multiple cards) is ready to be opened by
``rogue.hardware.axi.AxiMemMap`` from any PyRogue script (see
:doc:`/reference/pyrogue_scripts`).

Unload and Reload
-----------------

To unload the module for a rebuild or a driver-config change:

.. code-block:: bash

   sudo /sbin/rmmod datadev

Then re-run ``insmod`` with the new ``.ko`` or new parameters.

Persistent Load at Boot
-----------------------

For a permanent installation, copy ``datadev.ko`` into
``/lib/modules/$(uname -r)/extra/``, run ``depmod -a``, and add
``datadev`` (with the desired ``cfg*`` parameters) to
``/etc/modules-load.d/`` and ``/etc/modprobe.d/``.  See the
``aes-stream-drivers`` repository for the canonical procedure.

Troubleshooting
---------------

``/dev/datadev_0`` does not appear after ``insmod``
   Check ``dmesg``.  The most common cause is a kernel-header /
   kernel-binary mismatch (rebuild against the ``$(uname -r)`` headers).

PCIe link goes down after reprogramming
   The running ``datadev`` is still bound to the old BAR layout.  Rescan
   the PCIe bus or reboot the host.

Permission denied on ``/dev/datadev_*``
   Apply ``chmod`` as shown above, or install the ``udev`` rules from
   ``aes-stream-drivers`` for a permanent fix.
