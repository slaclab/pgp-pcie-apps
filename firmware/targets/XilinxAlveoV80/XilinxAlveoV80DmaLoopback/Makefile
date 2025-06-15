# Define target part
export PRJ_PART = xcv80-lsva4737-2MHP-e-S

# Define target output
target: mcs

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# Use top level makefile
include $(TOP_DIR)/targets/shared_config.mk
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk
