##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Pgp/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3GtyUsIpWrapper_1/GEN_15G.U_Pgp3GtyUsIp/inst/gen_gtwizard_gtye4_top.Pgp3GtyUsIp15G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[29].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_Pgp/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3GtyUsIpWrapper_1/GEN_15G.U_Pgp3GtyUsIp/inst/gen_gtwizard_gtye4_top.Pgp3GtyUsIp15G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[29].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Pgp/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3GtyUsIpWrapper_1/GEN_15G.U_Pgp3GtyUsIp/inst/gen_gtwizard_gtye4_top.Pgp3GtyUsIp15G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[29].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_Pgp/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3GtyUsIpWrapper_1/GEN_15G.U_Pgp3GtyUsIp/inst/gen_gtwizard_gtye4_top.Pgp3GtyUsIp15G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[29].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/U_Mig0/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG1.U_Mig1/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG2.U_Mig2/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG3.U_Mig3/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
