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
import surf.axi as axi

#################################################################

class PrbsLane(pr.Device):
    def __init__(self, numvc, **kwargs):
        super().__init__(**kwargs)

        # Loop through the virtual channels
        for vc in range(numvc):

            # Add the FW PRBS RateGen Module
            self.add(ssi.SsiPrbsTx(
                name    = f'PrbsTx[{vc}]',
                offset  = (0x1000*(2*vc+0)),
                clock_freq = 250.0e6,
                expand  = False,
            ))

        for vc in range(numvc):            
            # Add the FW PRBS RX Module
            self.add(ssi.SsiPrbsRx(
                name    = f'PrbsRx[{vc}]',
                offset  = (0x1000*(2*vc+1)),
                rxClkPeriod = 250.0e6,
                expand  = False,
            ))

        self.add(axi.AxiStreamMonAxiL(
            name = f'TxMon',
            offset = 0x1000*2*numvc,
            numberLanes = numvc,
            ))

        self.add(axi.AxiStreamMonAxiL(
            name = f'RxMon',
            offset = 0x1000*((2*numvc)+1),
            numberLanes = numvc,
            ))
        
