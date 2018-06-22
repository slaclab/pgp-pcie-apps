-------------------------------------------------------------------------------
-- File       : XilinxKcu1500DmaLoopback.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-05-26
-------------------------------------------------------------------------------
-- Description: 
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

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxKcu1500DmaLoopback is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in    slv(1 downto 0);
      qsfp0RefClkN : in    slv(1 downto 0);
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in    slv(1 downto 0);
      qsfp1RefClkN : in    slv(1 downto 0);
      qsfp1RxP     : in    slv(3 downto 0);
      qsfp1RxN     : in    slv(3 downto 0);
      qsfp1TxP     : out   slv(3 downto 0);
      qsfp1TxN     : out   slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      swDip        : in    slv(3 downto 0);
      led          : out   slv(7 downto 0);
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out   sl;
      qsfp1LpMode  : out   sl;
      qsfp1ModSelL : out   sl;
      qsfp1ModPrsL : in    sl;
      -- Boot Memory Ports 
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   sl;
      -- DDR Ports
      ddrClkP      : in    slv(3 downto 0);
      ddrClkN      : in    slv(3 downto 0);
      ddrOut       : out   DdrOutArray(3 downto 0);
      ddrInOut     : inout DdrInOutArray(3 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end XilinxKcu1500DmaLoopback;

architecture top_level of XilinxKcu1500DmaLoopback is

   signal axilClk : sl;
   signal axilRst : sl;

   signal dmaClk     : sl;
   signal dmaRst     : sl;
   signal dmaMasters : AxiStreamMasterArray(7 downto 0);
   signal dmaSlaves  : AxiStreamSlaveArray(7 downto 0);

   signal memReady        : slv(3 downto 0);
   signal memWriteMasters : AxiWriteMasterArray(15 downto 0);
   signal memWriteSlaves  : AxiWriteSlaveArray(15 downto 0);
   signal memReadMasters  : AxiReadMasterArray(15 downto 0);
   signal memReadSlaves   : AxiReadSlaveArray(15 downto 0);

begin

   U_axilClk : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I   => dmaClk,
         CE  => '1',
         CLR => '0',
         O   => axilClk);

   U_axilRst : entity work.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => axilClk,
         asyncRst => dmaRst,
         syncRst  => axilRst);

   U_Core : entity work.XilinxKcu1500Core
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         DMA_SIZE_G   => 8)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------        
         -- System Clock and Reset
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         -- DMA Interfaces
         dmaObMasters    => dmaMasters,
         dmaObSlaves     => dmaSlaves,
         dmaIbMasters    => dmaMasters,
         dmaIbSlaves     => dmaSlaves,
         -- AXI-Lite Interface
         appClk          => axilClk,
         appRst          => axilRst,
         appReadMaster   => open,
         appReadSlave    => AXI_LITE_READ_SLAVE_EMPTY_OK_C,
         appWriteMaster  => open,
         appWriteSlave   => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C,
         -- Memory bus (sysClk domain)
         memReady        => memReady,
         memWriteMasters => memWriteMasters,
         memWriteSlaves  => memWriteSlaves,
         memReadMasters  => memReadMasters,
         memReadSlaves   => memReadSlaves,
         --------------
         --  Core Ports
         --------------   
         -- System Ports
         emcClk          => emcClk,
         userClkP        => userClkP,
         userClkN        => userClkN,
         swDip           => swDip,
         led             => led,
         -- QSFP[0] Ports
         qsfp0RstL       => qsfp0RstL,
         qsfp0LpMode     => qsfp0LpMode,
         qsfp0ModSelL    => qsfp0ModSelL,
         qsfp0ModPrsL    => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL       => qsfp1RstL,
         qsfp1LpMode     => qsfp1LpMode,
         qsfp1ModSelL    => qsfp1ModSelL,
         qsfp1ModPrsL    => qsfp1ModPrsL,
         -- Boot Memory Ports 
         flashCsL        => flashCsL,
         flashMosi       => flashMosi,
         flashMiso       => flashMiso,
         flashHoldL      => flashHoldL,
         flashWp         => flashWp,
         -- DDR Ports
         ddrClkP         => ddrClkP,
         ddrClkN         => ddrClkN,
         ddrOut          => ddrOut,
         ddrInOut        => ddrInOut,
         -- PCIe Ports 
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   -- Unused memory signals
   memWriteMasters <= (others => AXI_WRITE_MASTER_INIT_C);
   memReadMasters  <= (others => AXI_READ_MASTER_INIT_C);

   -------------------------
   -- Unused QSFP interfaces
   -------------------------
   U_UnusedQsfp : entity work.TerminateQsfp
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk      => axilClk,
         axilRst      => axilRst,
         ---------------------
         --  Application Ports
         ---------------------         
         -- QSFP[0] Ports
         qsfp0RefClkP => qsfp0RefClkP,
         qsfp0RefClkN => qsfp0RefClkN,
         qsfp0RxP     => qsfp0RxP,
         qsfp0RxN     => qsfp0RxN,
         qsfp0TxP     => qsfp0TxP,
         qsfp0TxN     => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP => qsfp1RefClkP,
         qsfp1RefClkN => qsfp1RefClkN,
         qsfp1RxP     => qsfp1RxP,
         qsfp1RxN     => qsfp1RxN,
         qsfp1TxP     => qsfp1TxP,
         qsfp1TxN     => qsfp1TxN);

end top_level;
