-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the FPGA module
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

entity XilinxVariumC1100DmaLoopbackTb is end XilinxVariumC1100DmaLoopbackTb;

architecture testbed of XilinxVariumC1100DmaLoopbackTb is

   constant TPD_G : time := 1 ns;

   signal userClkP : sl := '0';
   signal userClkN : sl := '1';

begin

   U_ClkPgp : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10 ns,    -- 100 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   U_Fpga : entity work.XilinxVariumC1100DmaLoopback
      generic map (
         TPD_G          => TPD_G,
         ROGUE_SIM_EN_G => true,
         BUILD_INFO_G   => BUILD_INFO_C)
      port map (
         ---------------------
         --  Application Ports
         ---------------------
         -- QSFP[0] Ports
         qsfp0RefClkP => '0',
         qsfp0RefClkN => '1',
         qsfp0RxP     => (others => '0'),
         qsfp0RxN     => (others => '1'),
         qsfp0TxP     => open,
         qsfp0TxN     => open,
         -- QSFP[1] Ports
         qsfp1RefClkP => '0',
         qsfp1RefClkN => '1',
         qsfp1RxP     => (others => '0'),
         qsfp1RxN     => (others => '1'),
         qsfp1TxP     => open,
         qsfp1TxN     => open,
         -- HBM Ports
         hbmCatTrip   => open,
         --------------
         --  Core Ports
         --------------
         -- Card Management Solution (CMS) Interface
         cmsUartRxd   => '1',
         cmsUartTxd   => open,
         cmsGpio      => (others => '0'),
         -- System Ports
         userClkP     => userClkP,
         userClkN     => userClkN,
         hbmRefClkP   => userClkP,
         hbmRefClkN   => userClkN,
         -- SI5394 Ports
         si5394Scl    => open,
         si5394Sda    => open,
         si5394IrqL   => '1',
         si5394LolL   => '1',
         si5394LosL   => '1',
         si5394RstL   => open,
         -- PCIe Ports
         pciRstL      => '1',
         pciRefClkP   => (others => '0'),
         pciRefClkN   => (others => '1'),
         pciRxP       => (others => '0'),
         pciRxN       => (others => '1'),
         pciTxP       => open,
         pciTxN       => open);

end testbed;
