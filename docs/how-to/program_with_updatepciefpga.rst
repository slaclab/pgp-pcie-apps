Program a Board with ``updatePcieFpga.py``
==========================================

:repo:`software/scripts/updatePcieFpga.py` is a symlink to
``axi-pcie-core``'s ``scripts/updatePcieFpga``.  It programs the card's
boot PROM over PCIe, reloads the FPGA, and rescans the PCIe bus so the
new firmware becomes active without a JTAG cable or a host reboot.

The script, its options, the post-reload rescan, and its error messages
are documented in the
`axi-pcie-core Reprogram the PCIe Card PROM how-to
<https://slaclab.github.io/axi-pcie-core/how-to/reprogram_pcie_prom.html>`_.
This page only covers what is specific to ``pgp-pcie-apps``.

Prerequisites
-------------

- The ``aes-stream-drivers`` kernel module loaded and the card visible
  as ``/dev/datadev_<N>``; see :doc:`/how-to/load_driver`.
- The Rogue environment activated (``source software/setup_env_slac.sh``
  at SLAC S3DF, ``source software/cds_env_setup.sh`` at PCDS/CDS).
- A ``.mcs`` (or ``.mcs.gz``) image built for the card, from a prior
  ``make`` (see :doc:`/tutorial/first_build`) or a release.

Usage
-----

Point ``--path`` at the target's ``images/`` directory.  ``sudo`` does
not inherit your conda environment, so pass the interpreter explicitly:

.. code-block:: bash

   cd software/scripts
   sudo $(which python) updatePcieFpga.py \
       --path ../../firmware/targets/XilinxVariumC1100/XilinxVariumC1100DmaLoopback/images/

The script lists the images it finds and prompts you to pick one.  Add
``--dev /dev/datadev_<N>`` to select another card.

Notes for pgp-pcie-apps Targets
-------------------------------

- **No PROM image:** the ``AlphaDataKu3`` targets build no ``.mcs`` and
  their firmware reports no programmable boot PROM, so program them over
  JTAG with the ``.bit`` instead.
- **Bifurcated PCIe:** on the ``*BifurcatedPcie`` targets, point
  ``--dev`` at the primary endpoint; the secondary endpoint stops with
  ``No PROM type detected!!!``.
- **Lost PCIe link:** if the script reports
  ``Unable to reprogram FPGA as lost of PCIe link``, the recovery script
  it refers to is
  ``firmware/submodules/axi-pcie-core/scripts/rescanPcieFpga.sh`` in this
  repository.
- **No .mcs in images/:** with ``GEN_MCS_IMAGE=0`` (and
  ``GEN_MCS_IMAGE_GZIP=0``) the build copies no ``.mcs`` into
  ``images/``; see :doc:`/reference/make_targets`.
