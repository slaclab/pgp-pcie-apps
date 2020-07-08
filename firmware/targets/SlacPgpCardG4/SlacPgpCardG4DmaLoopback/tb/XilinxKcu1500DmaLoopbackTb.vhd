-------------------------------------------------------------------------------
-- File       : SlacPgpCardG4DmaLoopbackTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SlacPgpCardG4DmaLoopback module
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

entity SlacPgpCardG4DmaLoopbackTb is end SlacPgpCardG4DmaLoopbackTb;

architecture testbed of SlacPgpCardG4DmaLoopbackTb is

   constant TPD_G : time := 1 ns;

   signal userClkP : sl := '0';
   signal userClkN : sl := '1';

begin

   U_ClkPgp : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   U_Fpga : entity work.SlacPgpCardG4DmaLoopback
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => true,
         ROGUE_SIM_PORT_NUM_G => 8000,
         BUILD_INFO_G         => BUILD_INFO_C)
      port map (
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk       => '0',
         -- Boot Memory Ports
         flashCsL     => open,
         flashMosi    => open,
         flashMiso    => '1',
         flashHoldL   => open,
         flashWp      => open,
         -- PCIe Ports
         pciRstL      => '1',
         pciRefClkP   => '0',
         pciRefClkN   => '1',
         pciRxP       => (others => '0'),
         pciRxN       => (others => '1'),
         pciTxP       => open,
         pciTxN       => open);

end testbed;
