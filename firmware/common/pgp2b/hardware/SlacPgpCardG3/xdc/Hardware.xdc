##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'PGP PCIe APP DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######
# PGP #
#######

create_clock -name pgpRxClk0 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk1 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[1].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk2 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[2].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk3 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[3].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]

# create_clock -name pgpRxClk4 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[0].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
# create_clock -name pgpRxClk5 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[1].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
# create_clock -name pgpRxClk6 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[2].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
# create_clock -name pgpRxClk7 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[3].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]

create_clock -name pgpTxClk0 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk1 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[1].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk2 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[2].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk3 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[3].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]

# create_clock -name pgpTxClk4 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[0].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
# create_clock -name pgpTxClk5 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[1].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
# create_clock -name pgpTxClk6 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[2].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
# create_clock -name pgpTxClk7 -period 6.400 [get_pins {U_Hardware/U_Pgp/GEN_VEC[3].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/inst/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {pgpRxClk6}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {pgpRxClk7}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {pgpRxClk6}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
# set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {pgpRxClk7}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]

######################
# Area Constraint    #
######################
# create_pblock PGP_WEST_GRP
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_West/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_West/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_West/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_West/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_West/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_West/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_West/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_West/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_West/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_West/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_West/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_West/BUILD_FIFO.U_Rx}]
# resize_pblock [get_pblocks PGP_WEST_GRP] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y4}

# create_pblock PGP_EAST_GRP
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_East/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_East/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_East/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_East/U_PgpMon}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_East/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_East/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_East/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_East/U_Pgp}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[0].U_East/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[1].U_East/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[2].U_East/BUILD_FIFO.U_Rx}]
# add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_Hardware/U_Pgp/GEN_VEC[3].U_East/BUILD_FIFO.U_Rx}]
# resize_pblock [get_pblocks PGP_EAST_GRP] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y4}
