# Define Firmware Version Number
export PRJ_VERSION = 0x00000001

# Define the Hardware Type in the axi-pcie-core
export PCIE_HW_TYPE = XilinxKcu1500

# Define target part
export PRJ_PART = xcku115-flvb2104-2-e

# Define the number of MIG cores
export NUM_MIG_CORES = 0

# Select either GEN1 or GEN2 or GEN3 PCIe
export PCIE_GEN_NUM = GEN3

# Define target output
target: prom

# Use top level makefile
include ../../submodules/ruckus/system_vivado.mk
