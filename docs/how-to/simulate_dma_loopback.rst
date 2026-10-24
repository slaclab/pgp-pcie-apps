Simulate the DMA Loopback Path
==============================

The DmaLoopback target ships with a VHDL testbench
(:repo:`firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/tb/XilinxVariumC1100DmaLoopbackTb.vhd`)
that runs the application-side firmware under Vivado simulation, with
the PCIe PHY, DMA engine, and register path replaced by Rogue TCP
bridges.  This is the fastest debug loop
when you do not have hardware in hand.

How the Sim Backend Works
-------------------------

When ``ROGUE_SIM_EN_G => true`` is set on the ``<Board>Core`` instance
(or its enclosing top-level), ``axi-pcie-core`` removes the PCIe
crossbar and the ``AxiStreamDmaV2`` engine and substitutes
``surf.RogueTcpStreamWrap`` / ``surf.RogueTcpMemoryWrap`` TCP-socket
stubs:

* BAR0 register access becomes a
  ``rogue.interfaces.memory.TcpClient`` on a TCP port.
* Each DMA lane's stream becomes a
  ``rogue.interfaces.stream.TcpClient`` on a deterministic port pair.

On the Python side, ``LoopbackRoot(sim=True)`` (used by
``LoopbackTesting.py --type sim``) connects a memory ``TcpClient`` to
``localhost:8000`` (BAR0, matching ``ROGUE_SIM_PORT_NUM_G``) and a
stream ``TcpClient`` per lane and VC at ``8002 + 512*lane + 2*vc``.  The
same mapping is available from ``axi-pcie-core``'s
``createAxiPcieMemMap`` / ``createAxiPcieDmaStreams`` helpers with
``driverPath='sim'`` (see the
`axi-pcie-core use_pyrogue how-to
<https://slaclab.github.io/axi-pcie-core/how-to/use_pyrogue.html>`_).

Run the Simulation
------------------

In the firmware tree:

.. code-block:: bash

   cd firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback
   make xsim

This launches the Vivado simulator (XSIM) with
``XilinxVariumC1100DmaLoopbackTb`` as the top, as set by the
``set_property top`` line in the target's ``ruckus.tcl``.  Use
``make vcs`` instead to generate VCS simulation scripts.  When the
simulator reaches a steady state, the TCP socket server is listening.

In a second terminal, start the host-side PRBS test:

.. code-block:: bash

   cd software/scripts
   python LoopbackTesting.py --type sim

The PyRogue stack now talks to the simulator over TCP rather than the
``/dev/datadev_0`` device node.  The PyDM GUI looks identical to the
real-hardware run.

When to Use This
----------------

- Regression-testing application-side changes in the DmaLoopback top
  level (protocol targets have their own ``sim_1`` tops, for example
  ``Pgp4FecTb``).
- Exercising the host-side PyRogue scripts without a card.
- CI smoke tests where no board hardware is available.

What This Does Not Cover
------------------------

Simulation does not exercise:

- The PCIe PHY's serial transceivers.
- The ``AxiStreamDmaV2`` descriptor engine and the PCIe crossbar.
- The actual ``aes-stream-drivers`` kernel module.
- The board-specific I2C / QSFP / flash paths (those are also stubbed
  out under ``ROGUE_SIM_EN_G``).

Use simulation to catch logic bugs early, then move to hardware once the
sim run is clean.
