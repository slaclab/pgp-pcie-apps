AXI-Lite Address Map
====================

The PCIe BAR0 register space is decoded by a tree of ``AxiLiteCrossbar``
instances rooted in ``axi-pcie-core``.  ``pgp-pcie-apps`` adds its own
application-region crossbar on top; this page documents the application
layer.

BAR0 Top Level (from axi-pcie-core)
-----------------------------------

The BAR0 register tree below offset ``0x00100000`` is owned by
``axi-pcie-core`` and is documented in the
`axi-pcie-core register_map reference
<https://slaclab.github.io/axi-pcie-core/reference/register_map.html>`_.

The address window from ``0x00100000`` upwards is forwarded as the
``appReadMaster`` / ``appWriteMaster`` pair to the application
(``appClk`` domain).  ``pgp-pcie-apps`` decodes that range as follows.

Application Region (Top-Level pgp-pcie-apps Crossbar)
-----------------------------------------------------

The top-level target VHDL of the PGP targets (e.g.,
:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps/hdl/XilinxVariumC1100Pgp4_6Gbps.vhd`)
instantiates an AXI-Lite crossbar inside the ``app`` clock domain with
the following layout.  Exceptions: the ``XilinxVariumC1100`` HTSP
targets use a two-slot crossbar (``0x00100000`` and ``0x00800000``), and
the ``SlacPgpCardG4`` protocol targets and the DmaLoopback targets have
no top-level crossbar.

.. list-table::
   :header-rows: 1
   :widths: 16 10 24 50

   * - Offset
     - Size
     - Slave
     - Contents
   * - ``0x00100000``
     - 1 MB
     - ``MigDmaBuffer`` / ``HbmDmaBuffer``
     - One ``AxiStreamDmaV2Fifo`` per DMA lane (``0x100`` stride):
       ``HbmDmaBuffer`` on ``XilinxVariumC1100``, ``MigDmaBuffer`` on
       ``XilinxKcu1500`` / ``XilinxAlveoU200``.
   * - ``0x00200000``
     - 1 MB
     - (unused)
     - Unconnected on the PGP targets (responds with ``SLVERR``).  On
       ``XilinxVariumC1100PrbsTester`` this slot is ``BuffIbMon``
       (``AxiStreamMonAxiL``).
   * - ``0x00300000``
     - 1 MB
     - (unused)
     - Unconnected (``SLVERR``).
   * - ``0x00400000``
     - 1 MB
     - (unused)
     - Unconnected (``SLVERR``) except on ``XilinxAlveoU200Htsp_FebEmu``.
   * - ``0x00800000``
     - 8 MB
     - ``Hardware`` (PgpLaneWrapper / HtspWrapper)
     - The protocol layer; see `Hardware Sub-Tree`_ below.

Hardware Sub-Tree
~~~~~~~~~~~~~~~~~

Within the ``Hardware`` slave at ``0x00800000``, the
``PgpLaneWrapper`` distributes per-lane access:

.. list-table::
   :header-rows: 1
   :widths: 22 22 56

   * - Lane Base
     - Lane Index
     - Allocation
   * - ``0x00800000``
     - 0
     - First PGP lane (QSFP cage 0, lane 0)
   * - ``0x00810000``
     - 1
     - Second PGP lane
   * - ``0x00820000``
     - 2
     - Third PGP lane
   * - …
     - …
     - up to lane 7 at ``0x00870000``
   * - **Stride**
     -
     - ``0x00010000`` per lane (64 KB window).

Per-Lane Layout
~~~~~~~~~~~~~~~

Within each lane window the ``PgpGtyLane`` / ``PgpLane`` further
decodes (PGP3 and PGP4):

.. list-table::
   :header-rows: 1
   :widths: 22 22 56

   * - Offset (within lane)
     - Slave
     - Contents
   * - ``0x0000``
     - PGP core monitor
     - ``surf.Pgp4AxiL`` / ``Pgp3AxiL`` behind the internal crossbar of
       ``Pgp4GtyUs`` / ``Pgp3GtyUs`` (``GthUs`` variants on UltraScale
       boards): link state, RX/TX frame and error counters.
   * - ``0x1000``
     - GT DRP
     - Transceiver DRP behind the PGP core's internal crossbar
       (``EN_DRP_G => true``; the lane crossbar routes
       ``0x0000``-``0x1FFF`` to the core).  PyRogue node
       ``PgpGtDrp[n]`` (``surf.xilinx.Gthe3Channel`` on GTH boards,
       ``Gtye4Channel`` on GTY boards), added only when ``--boardType``
       names a supported board.
   * - ``0x2000``
     - (unused)
     - Not decoded on PGP3 / PGP4 (AXI-Lite decode error).
   * - ``0x3000``
     - TX stream monitor
     - ``surf.AxiStreamMonAxiL``: per-VC TX frame/byte counters.
   * - ``0x4000``
     - RX stream monitor
     - ``surf.AxiStreamMonAxiL``: per-VC RX frame/byte counters.

PGP3 / PGP4 images built before the GT DRP was enabled decode ``0x1000``
as an empty slot, so ``PgpGtDrp[n]`` reads back zeros on them.

PGP2b lanes use the three middle slots: GT DRP at ``0x0000``,
``surf.Pgp2bAxi`` at ``0x1000``, and ``PgpMiscCtrl`` at ``0x2000``.
PyRogue adds the PGP2b DRP as ``PgpGtDrp[n]`` at ``0x0000`` under the
same ``--boardType`` rule.

Tracing in Software
-------------------

The PyRogue device tree mirrors this layout.  From a ``PgpTesting.py``
session against a PGP4 target:

.. code-block:: python

   # Top-level (any Root)
   root.AxiPcieCore.AxiVersion.UpTimeCnt.get()
   # Application region
   root.Lane[0].RxStatus.FrameCnt.get()

Adjust the path for HTSP targets; see
:repo:`firmware/python/pgp_pcie_apps/_HtspRoot.py` for the device-tree
path through ``HtspWrapper``.
