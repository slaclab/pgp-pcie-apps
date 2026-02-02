export PARALLEL_SYNTH = 8

# Define target part
export PRJ_PART = xcu55c-fsvh2892-2L-e

# Define target output
target: dcp

# Define use of the BD file
export CMS_BLOCK_DESIGN_BD_FILE = 1

# Using a non-standard target directory structure,
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# Use top level makefile
include $(TOP_DIR)/targets/shared_config.mk
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk
