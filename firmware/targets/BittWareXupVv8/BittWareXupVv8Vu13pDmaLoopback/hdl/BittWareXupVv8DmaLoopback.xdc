##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

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





set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Core}]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_axilClk}]
#set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_UnusedQsfp}]
