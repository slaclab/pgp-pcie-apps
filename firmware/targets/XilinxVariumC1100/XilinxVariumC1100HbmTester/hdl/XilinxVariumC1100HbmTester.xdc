##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Hardware}]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_HbmDmaBuffer}]

create_pblock HBM0_GRP
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[0].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[1].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[2].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[3].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[0].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[1].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[2].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM0_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[3].U_HbmAxiFifo]]
resize_pblock [get_pblocks HBM0_GRP] -add {CLOCKREGION_X0Y0:CLOCKREGION_X3Y3}

create_pblock HBM1_GRP
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[4].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[5].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[6].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[7].U_AxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[4].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[5].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[6].U_HbmAxiFifo]]
add_cells_to_pblock [get_pblocks HBM1_GRP] [get_cells [list U_HbmDmaBuffer/GEN_FIFO[7].U_HbmAxiFifo]]
resize_pblock [get_pblocks HBM1_GRP] -add {CLOCKREGION_X4Y0:CLOCKREGION_X7Y3}

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_HbmDmaBuffer/U_hbmClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_HbmDmaBuffer/U_hbmClk/PllGen.U_Pll/CLKOUT1]]
