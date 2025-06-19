# pgp-pcie-apps

[DOE Code](https://www.osti.gov/doecode/biblio/75501)

<!--- ######################################################## -->

# Clone the GIT repository

Install git large filesystems (git-lfs) in your .gitconfig (1-time step per unix environment)
```bash
$ git lfs install
```
Clone the git repo with git-lfs enabled
```bash
$ git clone --recursive https://github.com/slaclab/pgp-pcie-apps.git
```

Note: `recursive flag` used to initialize all submodules within the clone

<!--- ######################################################## -->

# How to load the driver

```bash
# Confirm that you have the board the computer with VID=1a4a ("SLAC") and PID=2030 ("AXI Stream DAQ")
$ lspci -nn | grep SLAC
04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab TID-AIR AXI Stream DAQ PCIe card [1a4a:2030]

# Clone the driver github repo:
$ git clone --recursive https://github.com/slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# Load the driver
$ sudo /sbin/insmod ./datadev.ko cfgSize=0x50000 cfgRxCount=256 cfgTxCount=16

# Give appropriate group/permissions
$ sudo chmod 666 /dev/data_dev*

# Check for the loaded device
$ cat /proc/datadev_0

```

<!--- ######################################################## -->

# Example of How to build the firmware

In this example, we will build the pseudorandom binary sequence (PRBS) data generator on a Xilinx KCU1500 PCIe card.

1) Setup your Xilinx Vivado:

> If you are on the SLAC S3DF network:

```
$ source /sdf/group/faders/tools/xilinx/2024.2/Vivado/2024.2/settings64.sh
```

> Else you will need to install Vivado and install the Xilinx Licensing

2) Go to the firmware's target directory (lots of targets...using XilinxVariumC1100Pgp4_6Gbps for illustration):

```bash
$ cd pgp-pcie-apps/firmware/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps
```

3) Build the firmware

```bash
$ make
```

4) Optional: Review the results in GUI mode

```bash
$ make gui
```

Note: For more information about the firmware build system:

https://confluence.slac.stanford.edu/x/n4-jCg

<!--- ######################################################## -->

# How to install the Rogue With miniforge

> https://slaclab.github.io/rogue/installing/miniforge.html

<!--- ######################################################## -->
# How to reprogram the PCIe firmware via Rogue software

1) Setup the rogue environment (assumes that you are on SLAC S3DF network)

```bash
$ cd pgp-pcie-apps/software
$ source setup_env_slac.sh
```

2) Run the PCIe firmware update script:
```bash
$ python scripts/updatePcieFpga.py --path <PATH_TO_IMAGE_DIR>
```
where <PATH_TO_IMAGE_DIR> is path to image directory (example: ../firmware/targets/XilinxKcu1500/XilinxKcu1500DmaLoopback/images/)

3) Reboot the computer
```bash
sudo reboot
```

<!--- ########################################################################################### -->
