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

create_clock -name pgpRxClk0 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk1 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk2 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk3 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk4 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk5 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk6 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[6].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk7 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[7].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]

create_clock -name pgpTxClk0 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk1 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk2 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk3 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk4 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk5 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk6 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[6].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk7 -period 4.000 [get_pins {U_Hardware/U_Pgp/GEN_LANE[7].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP1}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP1}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {pgpRxClk6}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {pgpRxClk7}] -group [get_clocks {dmaClk}] -group [get_clocks {drpClk}] -group [get_clocks {axilClk}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {pgpRxClk6}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {pgpRxClk7}] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
