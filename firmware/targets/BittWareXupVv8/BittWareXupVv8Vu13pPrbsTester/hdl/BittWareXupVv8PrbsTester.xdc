##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]

create_generated_clock -name axilClk [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT0}]

create_clock -name qsfpRefClk0 -period 3.1 [get_ports {qsfpRefClkP[0]}]
create_clock -name qsfpRefClk1 -period 3.1 [get_ports {qsfpRefClkP[1]}]
create_clock -name qsfpRefClk2 -period 3.1 [get_ports {qsfpRefClkP[2]}]
create_clock -name qsfpRefClk3 -period 3.1 [get_ports {qsfpRefClkP[3]}]
create_clock -name qsfpRefClk4 -period 3.1 [get_ports {qsfpRefClkP[4]}]
create_clock -name qsfpRefClk5 -period 3.1 [get_ports {qsfpRefClkP[5]}]
create_clock -name qsfpRefClk6 -period 3.1 [get_ports {qsfpRefClkP[6]}]
create_clock -name qsfpRefClk7 -period 3.1 [get_ports {qsfpRefClkP[7]}]


set_clock_groups -asynchronous \
    -group [get_clocks axilClk] \
    -group [get_clocks dmaClk] \
    -group [get_clocks qsfpRefClk0] \
    -group [get_clocks qsfpRefClk1] \
    -group [get_clocks qsfpRefClk2] \
    -group [get_clocks qsfpRefClk3] \
    -group [get_clocks qsfpRefClk4] \
    -group [get_clocks qsfpRefClk5] \
    -group [get_clocks qsfpRefClk6] \
    -group [get_clocks qsfpRefClk7] 


# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/U_Mig0/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG1.U_Mig1/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG2.U_Mig2/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Mig/GEN_MIG3.U_Mig3/U_MIG/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]


set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Core}]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_axilClk}]


# set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_Hardware/GEN_VEC[0]*}]
# set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_Hardware/GEN_VEC[1]*}]
# set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_Hardware/GEN_VEC[2]*}]
# set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_Hardware/GEN_VEC[3]*}]
# set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {U_Hardware/GEN_VEC[4]*}]
# set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {U_Hardware/GEN_VEC[5]*}]
# set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {U_Hardware/GEN_VEC[6]*}]
# set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {U_Hardware/GEN_VEC[7]*}]

add_cells_to_pblock SLR1_GRP [get_cells {U_Core}]

add_cells_to_pblock SLR0_GRP [get_cells [list {U_Hardware/GEN_VEC[0].U_PrbsLane}]]
add_cells_to_pblock SLR0_GRP [get_cells [list {U_Hardware/GEN_VEC[1].U_PrbsLane}]]
add_cells_to_pblock SLR0_GRP [get_cells [list {U_Hardware/GEN_VEC[2].U_PrbsLane}]]
add_cells_to_pblock SLR0_GRP [get_cells [list {U_Hardware/GEN_VEC[3].U_PrbsLane}]]
add_cells_to_pblock SLR2_GRP [get_cells [list {U_Hardware/GEN_VEC[4].U_PrbsLane}]]
add_cells_to_pblock SLR2_GRP [get_cells [list {U_Hardware/GEN_VEC[5].U_PrbsLane}]]
add_cells_to_pblock SLR2_GRP [get_cells [list {U_Hardware/GEN_VEC[6].U_PrbsLane}]]
add_cells_to_pblock SLR2_GRP [get_cells [list {U_Hardware/GEN_VEC[7].U_PrbsLane}]]


