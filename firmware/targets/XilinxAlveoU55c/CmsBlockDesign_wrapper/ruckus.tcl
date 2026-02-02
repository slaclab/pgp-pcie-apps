# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../../submodules/axi-pcie-core/hardware/XilinxAlveoU55c

# Generate the BD wrapper
GenerateBdWrappers

# Set BD wrapper as top level
set_property top CmsBlockDesign_wrapper [current_fileset]

# Set the design as "out of context"
SetSynthOutOfContext
