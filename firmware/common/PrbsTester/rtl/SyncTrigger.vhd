-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity SyncTrigger is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- External Trigger Interface
      trig            : out sl;
      packetLength    : out slv(31 downto 0);
      busy            : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end SyncTrigger;

architecture rtl of SyncTrigger is

   type RegType is record
      trig           : sl;
      runEnable      : sl;
      packetLength   : slv(31 downto 0);
      timerSize      : slv(31 downto 0);
      timer          : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      trig           => '0',
      runEnable      => '1',
      packetLength   => x"00000FFF",
      timerSize      => x"00FFFFFF",
      timer          => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, busy, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.trig := '0';

      ------------------------
      -- AXI-Lite Transactions
      ------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, x"0", 0, v.packetLength);
      axiSlaveRegister(axilEp, x"4", 0, v.timerSize);
      axiSlaveRegister(axilEp, x"8", 0, v.runEnable);

      -- Close the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ---------------------------------
      -- Timer
      ---------------------------------
      if (r.timer /= 0) then

         -- Decrement the Counter
         v.timer := r.timer - 1;

      elsif (busy = '0') and (r.runEnable = '1') then

         -- Set the flag
         v.trig := '1';

         -- Set the timer
         v.timer := r.timerSize;

      end if;
      
      -- Prevent the zero case
      if (v.timerSize = 0) then
         v.timerSize := r.timerSize;
      end if;      

      -- Check for change in timer config
      if (r.timerSize /= v.timerSize) then
         v.timer := (others => '0');
      end if;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;
      trig           <= r.trig;
      packetLength   <= r.packetLength;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
