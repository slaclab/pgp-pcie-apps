
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

class SyncTrigger(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.prbsByte = args.prbsWidth>>3

        self.add(pr.RemoteVariable(
            name         = "PacketLength",
            description  = "",
            offset       =  0x0,
            bitSize      =  32,
            mode         = "RW",
            disp         = '{}',
            hidden       = True,
        ))

        self.add(pr.LinkVariable(
            name         = 'PacketSize',
            mode         = "RW",
            units         = "Bytes",
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = lambda: (self.PacketLength.value()+1)*self.prbsByte,
            linkedSet    = lambda value, write: self.PacketLength.set( int(value/self.prbsByte)-1 ),
            dependencies = [self.PacketLength],
        ))

        self.add(pr.RemoteVariable(
            name         = "TimerSize",
            description  = "",
            offset       =  0x4,
            bitSize      =  32,
            mode         = "RW",
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = "RunEnable",
            description  = "",
            offset       =  0x8,
            bitSize      =  1,
            mode         = "RW",
        ))

        self.add(pr.LinkVariable(
            name         = 'Rate',
            mode         = "RW",
            units         = "Hz",
            disp         = '{}',
            typeStr      = 'UInt32',
            linkedGet    = lambda: int(156.25E+6/float(self.TimerSize.value())),
            linkedSet    = lambda value, write: self.TimerSize.set( int(156.25E+6/value) ),
            dependencies = [self.TimerSize],
        ))
