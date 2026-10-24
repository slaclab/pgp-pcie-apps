##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import pyrogue as pr

class SyncTrigger(pr.Device):
    def __init__(self,
            prbsWidth = 512,       # PRBS generator width in bits
            clkFreq   = 250.0E+6,  # Trigger timer clock frequency in Hz (dmaClk)
            **kwargs):
        super().__init__(**kwargs)

        self._prbsByte = prbsWidth >> 3
        self._clkFreq  = clkFreq

        self.add(pr.RemoteVariable(
            name         = 'PacketLength',
            description  = 'Packet length in PRBS width units',
            offset       = 0x0,
            bitSize      = 32,
            mode         = 'RW',
            disp         = '{}',
            hidden       = True,
        ))

        self.add(pr.LinkVariable(
            name         = 'PacketSize',
            mode         = 'RW',
            units        = 'Bytes',
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = lambda: (self.PacketLength.value()+1)*self._prbsByte,
            linkedSet    = lambda value, write: self.PacketLength.set(int(value/self._prbsByte)-1),
            dependencies = [self.PacketLength],
        ))

        self.add(pr.RemoteVariable(
            name         = 'TimerSize',
            description  = 'Timer reload value in clock cycles',
            offset       = 0x4,
            bitSize      = 32,
            mode         = 'RW',
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RunEnable',
            description  = 'Enable trigger generation',
            offset       = 0x8,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.LinkVariable(
            name         = 'Rate',
            mode         = 'RW',
            units        = 'Hz',
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = self._getRate,
            linkedSet    = lambda value, write: self.TimerSize.set(int(self._clkFreq/value)),
            dependencies = [self.TimerSize],
        ))

    def _getRate(self):
        timerSize = self.TimerSize.value()
        return int(self._clkFreq/timerSize) if timerSize != 0 else 0
