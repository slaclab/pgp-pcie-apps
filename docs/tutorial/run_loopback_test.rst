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

  This activates a ``rogue_v6.15.0`` conda environment (``rogue``,
  ``pyrogue``, ``pyrogue.pydm``, and ZMQ) from your own miniforge
  install at ``/sdf/group/faders/users/$USER/miniforge3``; edit the path
  if yours differs.  At other sites, ensure ``rogue`` v6.15.0 or later
  is on ``PYTHONPATH``.

Run the Test
------------

.. code-block:: bash

   cd software/scripts
   python LoopbackTesting.py

``LoopbackTesting.py`` (:repo:`software/scripts/LoopbackTesting.py`) builds a
``pgp_pcie_apps.LoopbackRoot``
(:repo:`firmware/python/pgp_pcie_apps/_LoopbackRoot.py`), which opens
BAR0 and the DMA streams and attaches a SW PRBS transmitter
(``SwPrbsTx[lane][vc]``) and receiver (``SwPrbsRx[lane][vc]``) to each
lane and VC.  At start it prints ``Number of RX buffers = N`` and
enables every SW PRBS transmitter, so traffic flows without any GUI
action.  It then starts the PyDM GUI.

Useful Flags
~~~~~~~~~~~~

* ``--numLane N`` must match the target's DMA lane count: 1 (the
  default) for ``XilinxVariumC1100DmaLoopback``, 6 for
  ``XilinxKcu1500DmaLoopback``.
* ``--dev /dev/datadev_N`` selects another card.
* ``--guiType None`` runs headless until Ctrl-C (see
  :doc:`/reference/pyrogue_scripts`).

Backend Selection
~~~~~~~~~~~~~~~~~

``LoopbackTesting.py`` also accepts a ``--type`` flag:

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
* ``AxiPcieCore.DmaIbAxisMon`` and ``AxiPcieCore.DmaObAxisMon`` show
  matching frame counts.
* ``SwPrbsRx[*][*].rxCount`` increments and ``SwPrbsRx[*][*].rxErrors``
  stays at **zero**.

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
