# pgp-pcie-apps

[DOE Code](https://www.osti.gov/doecode/biblio/75501)

<!--- ########################################################################################### -->

# Before you clone the GIT repository

https://confluence.slac.stanford.edu/x/vJmDFg

<!--- ########################################################################################### -->

# Clone the GIT repository
> $ git clone --recursive git@github.com:slaclab/pgp-pcie-apps

<!--- ######################################################## -->

# How to load the driver

```
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
$ cat /proc/data_dev0

```

<!--- ######################################################## -->

# Example of How to build the firmware

In this example, we will build the pseudorandom binary sequence (PRBS) data generator on a Xilinx KCU1500 PCIe card.

1) Setup your Xilinx Vivado:

> If you are on the SLAC AFS network:

```
$ pgp-pcie-apps/firmware/setup_env_slac.csh
```

> Else you will need to install Vivado and install the Xilinx Licensing

2) Go to the firmware's target directory:

```
$ cd pgp-pcie-apps/firmware/targets/XilinxKcu1500PrbsTester
```

3) Build the firmware (two options available)

```
# Option#1: Build the firmware in batch mode
$ make

# Option#2: Build the firmware in GUI mode
$ make gui
```

Note: For more information about the firmware build system:

https://confluence.slac.stanford.edu/x/n4-jCg

<!--- ######################################################## -->

# How to install the Rogue With miniforge

> https://slaclab.github.io/rogue/installing/miniforge.html

<!--- ######################################################## -->
# How to reprogram the PCIe firmware via Rogue software

1) Setup the rogue environment (assumes that you are on SLAC AFS network)
```
$ cd pgp-pcie-apps/software
$ source setup_env_slac.sh
```

2) Run the PCIe firmware update script:
```
$ python scripts/updatePcieFpga.py --path <PATH_TO_IMAGE_DIR>
```
where <PATH_TO_IMAGE_DIR> is path to image directory (example: ../firmware/targets/XilinxKcu1500/XilinxKcu1500DmaLoopback/images/)

3) Reboot the computer
```
sudo reboot
```

<!--- ########################################################################################### -->
