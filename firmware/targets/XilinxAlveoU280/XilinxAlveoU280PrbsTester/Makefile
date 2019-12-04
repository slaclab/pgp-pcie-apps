# Define Firmware Version Number
export PRJ_VERSION = 0x00000010

# Define target part
export PRJ_PART = XCU280-FSVH2892-2L-E

# Define target output
target: mcs

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk

