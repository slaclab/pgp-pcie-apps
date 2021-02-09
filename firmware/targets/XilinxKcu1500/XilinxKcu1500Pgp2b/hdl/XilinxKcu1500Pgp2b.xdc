##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Hardware/U_Pgp/U_DRP_CLK/O]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk0]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk1]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk2]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk3]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk4]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk5]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk6]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpRxClk7]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk0]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk1]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk2]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk3]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk4]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk5]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk6]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks pgpTxClk7]
