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
import surf.protocols.ssi as ssi

#################################################################

class PrbsLane(pr.Device):
    def __init__(self, numvc, **kwargs):
        super().__init__(**kwargs)

        # Loop through the virtual channels
        for vc in range(numvc):

            # Add the FW PRBS RateGen Module
            self.add(ssi.SsiPrbsRateGen(
                name    = ('FwPrbsRateGen[%d]' % (vc)),
                memBase = kwargs.get("memBase"),
                offset  = kwargs.get("offset")+(0x1000*(2*vc+1)),
                expand  = False,
            ))

            # Add the FW PRBS RX Module
            self.add(ssi.SsiPrbsRx(
                name    = ('FwPrbsRx[%d]' % (vc)),
                memBase = kwargs.get("memBase"),
                offset  = kwargs.get("offset") + (0x1000*(2*vc+2)),
                expand  = False,
            ))

