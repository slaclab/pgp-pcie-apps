-------------------------------------------------------------------------------
-- File       : XilinxKcu1500DmaLoopbackBifurcatedPcie.vhd
-- Company    : SLAC National Accelerator Laboratory
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxKcu1500DmaLoopbackBifurcatedPcie is
   generic (
      TPD_G             : time                := 1 ns;
      ROGUE_SIM_EN_G    : boolean             := false;
      DMA_SIZE_G        : positive            := 8;

      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);  --- 8 Byte (64-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  --- 16 Byte (128-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  --- 32 Byte (256-bit) tData interface

      BUILD_INFO_G      : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP  : in  slv(1 downto 0);
      qsfp0RefClkN  : in  slv(1 downto 0);
      qsfp0RxP      : in  slv(3 downto 0);
      qsfp0RxN      : in  slv(3 downto 0);
      qsfp0TxP      : out slv(3 downto 0);
      qsfp0TxN      : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP  : in  slv(1 downto 0);
      qsfp1RefClkN  : in  slv(1 downto 0);
      qsfp1RxP      : in  slv(3 downto 0);
      qsfp1RxN      : in  slv(3 downto 0);
      qsfp1TxP      : out slv(3 downto 0);
      qsfp1TxN      : out slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk        : in  sl;
      userClkP      : in  sl;
      userClkN      : in  sl;
      -- QSFP[0] Ports
      qsfp0RstL     : out sl;
      qsfp0LpMode   : out sl;
      qsfp0ModSelL  : out sl;
      qsfp0ModPrsL  : in  sl;
      -- QSFP[1] Ports
      qsfp1RstL     : out sl;
      qsfp1LpMode   : out sl;
      qsfp1ModSelL  : out sl;
      qsfp1ModPrsL  : in  sl;
      -- Boot Memory Ports
      flashCsL      : out sl;
      flashMosi     : out sl;
      flashMiso     : in  sl;
      flashHoldL    : out sl;
      flashWp       : out sl;
      -- PCIe Ports
      pciRstL       : in  sl;
      pciRefClkP    : in  sl;
      pciRefClkN    : in  sl;
      pciRxP        : in  slv(7 downto 0);
      pciRxN        : in  slv(7 downto 0);
      pciTxP        : out slv(7 downto 0);
      pciTxN        : out slv(7 downto 0);
      -- Extended PCIe Ports
      pciExtRefClkP : in  sl;
      pciExtRefClkN : in  sl;
      pciExtRxP     : in  slv(7 downto 0);
      pciExtRxN     : in  slv(7 downto 0);
      pciExtTxP     : out slv(7 downto 0);
      pciExtTxN     : out slv(7 downto 0));
end XilinxKcu1500DmaLoopbackBifurcatedPcie;

architecture top_level of XilinxKcu1500DmaLoopbackBifurcatedPcie is

   signal dmaPriClk     : sl;
   signal dmaPriRst     : sl;
   signal dmaPriMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaPriSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

   signal dmaSecClk     : sl;
   signal dmaSecRst     : sl;
   signal dmaSecMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaSecSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

begin

   U_Core : entity axi_pcie_core.XilinxKcu1500Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G        => DMA_SIZE_G)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DMA Interfaces
         dmaClk       => dmaPriClk,
         dmaRst       => dmaPriRst,
         dmaObMasters => dmaPriMasters,
         dmaObSlaves  => dmaPriSlaves,
         dmaIbMasters => dmaPriMasters,
         dmaIbSlaves  => dmaPriSlaves,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk       => emcClk,
         userClkP     => userClkP,
         userClkN     => userClkN,
         -- QSFP[0] Ports
         qsfp0RstL    => qsfp0RstL,
         qsfp0LpMode  => qsfp0LpMode,
         qsfp0ModSelL => qsfp0ModSelL,
         qsfp0ModPrsL => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL    => qsfp1RstL,
         qsfp1LpMode  => qsfp1LpMode,
         qsfp1ModSelL => qsfp1ModSelL,
         qsfp1ModPrsL => qsfp1ModPrsL,
         -- Boot Memory Ports
         flashCsL     => flashCsL,
         flashMosi    => flashMosi,
         flashMiso    => flashMiso,
         flashHoldL   => flashHoldL,
         flashWp      => flashWp,
         -- PCIe Ports
         pciRstL      => pciRstL,
         pciRefClkP   => pciRefClkP,
         pciRefClkN   => pciRefClkN,
         pciRxP       => pciRxP,
         pciRxN       => pciRxN,
         pciTxP       => pciTxP,
         pciTxN       => pciTxN);

   U_ExtendedCore : entity axi_pcie_core.XilinxKcu1500PcieExtendedCore
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G        => DMA_SIZE_G)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DMA Interfaces
         dmaClk        => dmaSecClk,
         dmaRst        => dmaSecRst,
         dmaObMasters  => dmaSecMasters,
         dmaObSlaves   => dmaSecSlaves,
         dmaIbMasters  => dmaSecMasters,
         dmaIbSlaves   => dmaSecSlaves,
         --------------
         --  Core Ports
         --------------
         -- Extended PCIe Ports
         pciRstL       => pciRstL,
         pciExtRefClkP => pciExtRefClkP,
         pciExtRefClkN => pciExtRefClkN,
         pciExtRxP     => pciExtRxP,
         pciExtRxN     => pciExtRxN,
         pciExtTxP     => pciExtTxP,
         pciExtTxN     => pciExtTxN);

   -------------------------
   -- Unused QSFP interfaces
   -------------------------
   U_UnusedQsfp : entity axi_pcie_core.TerminateQsfp
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk      => dmaPriClk,
         axilRst      => dmaPriRst,
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
