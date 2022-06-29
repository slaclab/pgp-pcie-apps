##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

# Timing Constraints

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/U_phyClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/U_phyClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4/inst/Caui4GtyIpCore161MHz_gt_i/inst/gen_gtwizard_gtye4_top.Caui4GtyIpCore161MHz_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

# Placement Constraints

set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {U_Hardware}]

create_pblock CMACE4_GRP
add_cells_to_pblock [get_pblocks CMACE4_GRP] [get_cells [list U_Hardware/U_QSFP0/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4]]
add_cells_to_pblock [get_pblocks CMACE4_GRP] [get_cells [list U_Hardware/U_QSFP1/U_Htsp/REAL_HTSP.U_IP/USE_REFCLK161MHz.U_CAUI4]]
resize_pblock [get_pblocks CMACE4_GRP] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
