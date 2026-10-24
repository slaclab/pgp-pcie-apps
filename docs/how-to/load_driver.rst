Load the PCIe Kernel Driver
===========================

``pgp-pcie-apps`` bitstreams are driven by the ``aes-stream-drivers``
Linux kernel module (``datadev.ko``).  Once the module is loaded, each
SLAC PCIe card appears as a ``/dev/datadev_<N>`` device node that the
PyRogue scripts in :repo:`software/scripts/` open as their
``AxiMemMap`` / ``AxiStreamDma`` backend.

Building, loading, and configuring the driver is documented in the
`aes-stream-drivers documentation <https://slaclab.github.io/aes-stream-drivers/>`_;
this page only covers what is specific to ``pgp-pcie-apps``.

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

Build and Load the Driver
-------------------------

Follow the aes-stream-drivers guides:

* `Build and Load the Driver
  <https://slaclab.github.io/aes-stream-drivers/how-to/build-and-load.html>`_:
  build ``datadev.ko``, load it with ``insmod``, and configure
  persistent loading through ``modprobe.d``.
* `DKMS Install
  <https://slaclab.github.io/aes-stream-drivers/how-to/dkms-install.html>`_:
  keep the module rebuilt across kernel updates.
* `Module Parameters
  <https://slaclab.github.io/aes-stream-drivers/reference/module-parameters.html>`_:
  the ``cfg*`` DMA buffer size and count options.
* `Device Nodes
  <https://slaclab.github.io/aes-stream-drivers/reference/device-nodes.html>`_:
  ``/dev/datadev_<N>`` naming and permissions.

Verify
------

.. code-block:: bash

   ls -l /dev/datadev_*
   cat /proc/datadev_0

The driver creates the device nodes with ``0666`` permissions, so no
``chmod`` or ``sudo`` is needed to open them.  ``/proc/datadev_0`` prints
the running firmware's ``AxiVersion`` (version, git hash, build string),
the DMA driver version, and the read/write buffer counts and sizes; the
build string confirms which target is loaded.

Selecting a Card
----------------

With the default ``cfgDevName=0``, nodes are numbered in probe order
(``/dev/datadev_0``, ``/dev/datadev_1``, ...); with ``cfgDevName=1`` the
suffix is the PCIe bus number in hex.  Every launcher script defaults to
``--dev /dev/datadev_0``; pass ``--dev`` to select another card (see
:doc:`/reference/pyrogue_scripts`).

Troubleshooting
---------------

``/dev/datadev_0`` does not appear after loading
   Check ``dmesg``.  See the aes-stream-drivers guides above for build
   and kernel-header issues.

PCIe link goes down after reprogramming
   The running ``datadev`` is still bound to the old BAR layout.  Rescan
   the PCIe bus or reboot the host.
