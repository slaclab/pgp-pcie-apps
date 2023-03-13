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
    def __init__(self, numvc, no_rx=False, no_tx=False, clock_freq=156.25e6, **kwargs):
        super().__init__(**kwargs)

        # Loop through the virtual channels
        for vc in range(numvc):

            # Add the FW PRBS RateGen Module
            if no_tx is not True:
                self.add(ssi.SsiPrbsTx(
                    name    = f'PrbsTx[{vc}]',
                    offset  = (0x400*(2*vc+0)),
                    clock_freq = clock_freq,
                    expand  = False,
                ))

        for vc in range(numvc):            
            # Add the FW PRBS RX Module
            if no_rx is not True:
                self.add(ssi.SsiPrbsRx(
                    name    = f'PrbsRx[{vc}]',
                    offset  = (0x400*(2*vc+1)),
                    rxClkPeriod = clock_freq,
                    expand  = False,
                ))

        if no_tx is not True:
            self.add(axi.AxiStreamMonAxiL(
                name = f'TxMon',
                offset = 0x400*2*numvc,
                numberLanes = numvc,
            ))

        if no_rx is not True:
            self.add(axi.AxiStreamMonAxiL(
                name = f'RxMon',
                offset = 0x400*((2*numvc)+1),
                numberLanes = numvc,
            ))
        
