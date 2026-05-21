Relation to axi-pcie-core
==========================

``pgp-pcie-apps`` is a downstream consumer of ``axi-pcie-core``.  This
page draws the boundary so you know which repo to look at for a given
question.

What Lives Where
----------------

``axi-pcie-core`` (the library, submodule)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Everything in ``firmware/submodules/axi-pcie-core/`` is owned by the
``slaclab/axi-pcie-core`` repository.  It provides:

* **PCIe PHY wrapping** — per-board pre-compiled Vivado ``.dcp``
  checkpoints under ``hardware/<Board>/pcie/``.
* **AXI-Stream DMA engine** — ``AxiPcieDma`` + ``AxiStreamDmaV2``,
  shared across all boards.
* **BAR0 register crossbar** — ``AxiPcieReg`` plus PROM access (SPI,
  BPI), sysmon, I2C, AxiVersion.
* **Board-management Python** — the ``axipcie`` PyRogue package
  (``AxiPcieCore``, ``AxiPcieRoot``, ``CmsSubsystem``, etc.).

Look at the
`axi-pcie-core documentation <https://slaclab.github.io/axi-pcie-core/>`_
for questions about:

* "How does the DMA engine work?" → ``explanation/pcie_dma_model``.
* "What does BAR0 look like?" → ``reference/register_map``.
* "How do I open a connection from Python?" → ``how-to/use_pyrogue``.
* "What boards does ``axi-pcie-core`` support, and what are their
  PCIe gen/lane/memory profiles?" → ``reference/supported_boards``.
* "How do I add a new board to ``axi-pcie-core`` itself?" →
  ``how-to/add_new_board``.

``pgp-pcie-apps`` (this repo)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Everything outside ``firmware/submodules/`` belongs here.  It provides:

* **Per-board, per-protocol build targets** under
  ``firmware/targets/<Board>/<Target>/``.
* **Shared protocol RTL** under ``firmware/common/<proto>/`` (PGP2b,
  PGP3, PGP4, HTSP).
* **PrbsTester application** under ``firmware/common/PrbsTester/``.
* **PyRogue test scripts** under ``software/scripts/`` that drive
  PGP/HTSP/PRBS traffic through the ``axi-pcie-core`` DMA engine.

Look at this documentation for questions about:

* "How do I build a bitstream for my board?" → :doc:`/tutorial/first_build`.
* "How do I change protocol or line rate on an existing target?" →
  :doc:`/how-to/select_protocol` and :doc:`/how-to/add_new_line_rate`.
* "Which target directory should I copy from?" →
  :doc:`/reference/supported_targets`.
* "What does the PGP RX/TX path look like?" →
  :doc:`/explanation/data_flow`.
* "What scripts are in ``software/scripts/`` and what do they do?" →
  :doc:`/reference/pyrogue_scripts`.

How They Interact
-----------------

The target top-level VHDL (in ``firmware/targets/<Board>/<Target>/hdl/``)
instantiates **both** sides:

.. code-block:: vhdl

   -- from axi-pcie-core: PCIe DMA + board management
   U_Core : entity axi_pcie_core.XilinxVariumC1100Core
      generic map (
         BUILD_INFO_G      => BUILD_INFO_C,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => 1)
      port map ( ... );

   -- from pgp-pcie-apps: the protocol layer
   U_Hardware : entity work.Hardware
      generic map (
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         RATE_G            => "6.25Gbps")
      port map ( ... );

The DMA streams from ``U_Core`` connect to ``U_Hardware``; the
application AXI-Lite master pair from ``U_Core`` is routed through the
top-level crossbar to ``U_Hardware`` and any utility slaves.

When to Update Which Repo
--------------------------

* Fixing a DMA, PROM, AxiVersion, or PCIe PHY bug → ``axi-pcie-core``.
* Fixing a PGP framing, QPLL, or per-VC FIFO bug → ``pgp-pcie-apps``
  (``firmware/common/<proto>/shared/rtl/``).
* Adding a new board with a new PCIe variant → ``axi-pcie-core`` first,
  then add per-protocol ``hardware/<Board>/`` adapters and target
  directories in ``pgp-pcie-apps``.
* Adding a new line rate for an existing (board, protocol) pair →
  ``pgp-pcie-apps`` only (clone an existing target).

Version Coordination
--------------------

``pgp-pcie-apps`` pins ``axi-pcie-core`` to a specific commit via
``.gitmodules``.  Bumping the pin is a deliberate, atomic operation:

.. code-block:: bash

   cd firmware/submodules/axi-pcie-core
   git fetch origin
   git checkout <tag>
   cd -
   git add firmware/submodules/axi-pcie-core
   git commit -m "updating to axi-pcie-core (<tag>)"

The repository's recent commit history shows examples of this pattern.
``shared/ruckus.tcl`` inside ``axi-pcie-core`` enforces minimum versions
of ``ruckus`` and ``surf`` — bumping the ``axi-pcie-core`` pin may
require also bumping those.
