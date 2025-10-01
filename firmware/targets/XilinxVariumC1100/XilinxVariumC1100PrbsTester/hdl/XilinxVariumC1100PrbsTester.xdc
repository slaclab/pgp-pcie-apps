##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

#set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Hardware}]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_HbmDmaBuffer}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_HbmDmaBuffer/U_hbmClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_HbmDmaBuffer/U_hbmClk/PllGen.U_Pll/CLKOUT1]]
