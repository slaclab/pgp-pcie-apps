
#-----------------------------------------------------------------------------
# Description:
#
#-----------------------------------------------------------------------------
# This file is part of the 'SLAC Firmware Standard Library'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'SLAC Firmware Standard Library', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr
import pgp_pcie_apps.PrbsTester as test


#################################################################

class Hardware(pr.Device):
    def __init__(self,
                 numLanes,
                 VCs,
                 no_tx=False,
                 no_rx=False,
                 prbsWidth=32,                 
                 syncTrig=False,
                 **kwargs):
        
        super().__init__(**kwargs)

        # Generate lanes
        for lane in range(numLanes):
            self.add(test.PrbsLane(
                numvc = VCs,
                no_tx=no_tx,
                no_rx=no_rx,
                name    =(f"Lane[{lane}]"),
                offset =  (0x10000*lane),
                expand = False,
            ))

        if syncTrig:
            self.add(test.SyncTrigger(
                offset  = 0x10000*8,
                expand  = True,
                prbsWidth = prbsWidth
            ))   



