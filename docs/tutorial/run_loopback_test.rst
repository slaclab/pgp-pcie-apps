Run the DMA Loopback Test
=========================

This tutorial picks up where :doc:`/tutorial/first_build` ends: you have
a ``XilinxVariumC1100DmaLoopback`` ``.bit`` (or ``.mcs``) image and a
board in a host with the ``aes-stream-drivers`` PCIe kernel module
(``datadev.ko``) installed.  This tutorial exercises the DMA engine end
to end using ``software/scripts/LoopbackTesting.py``.

Prerequisites
-------------

- A programmed board reachable as ``/dev/datadev_0`` (or ``/dev/datadev_1``
  etc. for multiple cards).  Confirm:

  .. code-block:: bash

     ls -l /dev/datadev_*

  If no device nodes exist, install or reload ``aes-stream-drivers``
  (see :doc:`/how-to/load_driver`).

- A conda-managed Rogue environment.  At SLAC S3DF:

  .. code-block:: bash

     source software/setup_env_slac.sh

  This activates the ``rogue_v6.12.0`` conda environment that ships
  ``rogue``, ``pyrogue``, ``pyrogue.pydm``, and ZMQ.  At other sites,
  ensure ``rogue`` v6.12.0 or later is on ``PYTHONPATH``.

Run the Test
------------

.. code-block:: bash

   cd software/scripts
   python LoopbackTesting.py

``LoopbackTesting.py`` (:repo:`software/scripts/LoopbackTesting.py`) builds a
custom ``pr.Root`` that opens BAR0, opens DMA streams, and connects an
``rogue.utilities.Prbs`` transmitter and receiver around the firmware
DMA loopback path.  It then starts the PyDM GUI, which exposes
``AxiPcieCore.AxiVersion``, the IB and OB ``AxiStreamMonAxiL`` traffic
monitors, and live error counts.

Backend Selection
~~~~~~~~~~~~~~~~~

``LoopbackTesting.py`` accepts a ``--type`` flag:

* ``--type pcie`` (default): real ``/dev/datadev_*`` backend.
* ``--type sim``: rogue TCP-socket backend for software co-simulation
  against a VHDL testbench (requires ``ROGUE_SIM_EN_G => true`` in the
  firmware top-level).  See :doc:`/how-to/simulate_dma_loopback`.

What "Working" Looks Like
~~~~~~~~~~~~~~~~~~~~~~~~~

In the PyDM GUI:

* ``AxiPcieCore.AxiVersion.UpTimeCnt`` is incrementing.
* ``AxiPcieCore.AxiVersion.BuildStamp`` matches the ``.bit`` you flashed.
* ``AxiPcieCore.AxiVersion.PCIE_HW_TYPE_G`` shows ``XilinxVariumC1100``.
* The IB and OB stream monitors show matching frame counts and the PRBS
  error counters stay at **zero**.

If the PRBS error counters increase, the DMA path is dropping or
corrupting data.  See the
`axi-pcie-core DMA model explanation
<https://slaclab.github.io/axi-pcie-core/explanation/pcie_dma_model.html>`_
for the IB/OB FIFO and descriptor flow.

Next Steps
----------

- Replace the PRBS source with a real PGP feed: build a PGP target
  (e.g., ``XilinxVariumC1100Pgp4_6Gbps``) and run
  ``software/scripts/PgpTesting.py`` (see
  :doc:`/how-to/run_pgp_testing`).
- For HTSP 100G targets, see ``software/scripts/HtspTesting.py`` and the
  ``XilinxVariumC1100Htsp100Gbps`` target.
