##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'PGP PCIe APP DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]] -group [get_clocks -of_objects [get_pins {U_Hardware/U_PgpQuadA/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3Gtp7IpWrapper/U_RX_PLL/CLKOUT1}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_PgpQuadA/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3Gtp7IpWrapper/U_RX_PLL/CLKOUT2}]] -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]] -group [get_clocks {U_Hardware/U_PgpQuadA/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3Gtp7IpWrapper/GEN_6G.U_Pgp3Gtp7Ip6G/U0/Pgp3Gtp7Ip6G_i/gt0_Pgp3Gtp7Ip6G_i/gtpe2_i/RXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_PgpQuadA/GEN_LANE[*].U_Lane/U_Pgp/U_Pgp3Gtp7IpWrapper/U_RX_PLL/CLKOUT2}]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT2]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Hardware/U_PgpQuadA/U_TX_PLL/CLKOUT2]]
