Simulate the DMA Loopback Path
================================

The DmaLoopback target ships with a VHDL testbench
(:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/tb/XilinxVariumC1100DmaLoopbackTb.vhd`)
that runs the full DMA engine under Vivado simulation, with the PCIe PHY
replaced by a rogue TCP-socket server.  This is the fastest debug loop
when you don't have hardware in hand.

How the Sim Backend Works
--------------------------

When ``ROGUE_SIM_EN_G => true`` is set on the ``<Board>Core`` instance
(or its enclosing top-level), ``axi-pcie-core`` swaps the PCIe DMA path
for ``surf.RogueTcpStreamWrap`` / ``surf.RogueTcpMemoryWrap`` TCP-socket
stubs:

* BAR0 register access becomes a
  ``rogue.interfaces.memory.TcpClient`` on a TCP port.
* Each DMA lane's stream becomes a
  ``rogue.interfaces.stream.TcpClient`` on a deterministic port pair.

The Python side opens those sockets by passing ``driverPath='sim'`` to
the ``createAxiPcieMemMap`` / ``createAxiPcieDmaStreams`` helpers (see
the
`axi-pcie-core use_pyrogue how-to
<https://slaclab.github.io/axi-pcie-core/how-to/use_pyrogue.html>`_).

Run the Simulation
------------------

In the firmware tree:

.. code-block:: bash

   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback
   make sim

This launches the Vivado simulator with ``XilinxVariumC1100DmaLoopbackTb``
as the top.  When the simulator reaches a steady state, the TCP socket
server is listening.

In a second terminal, start the host-side PRBS test:

.. code-block:: bash

   cd software/scripts
   python LoopbackTesting.py --type sim

The PyRogue stack now talks to the simulator over TCP rather than the
``/dev/datadev_0`` device node.  The PyDM GUI looks identical to the
real-hardware run.

When to Use This
-----------------

- Debugging DMA descriptor-engine behaviour against a known-good firmware.
- Regression-testing changes to ``firmware/common/<proto>/shared/rtl/``
  before committing.
- CI smoke tests where no board hardware is available.

What This Doesn't Cover
-----------------------

Simulation does not exercise:

- The PCIe PHY's serial transceivers.
- The actual ``aes-stream-drivers`` kernel module.
- The board-specific I2C / QSFP / flash paths (those are also stubbed
  out under ``ROGUE_SIM_EN_G``).

Use simulation to catch logic bugs early, then move to hardware once the
sim run is clean.
