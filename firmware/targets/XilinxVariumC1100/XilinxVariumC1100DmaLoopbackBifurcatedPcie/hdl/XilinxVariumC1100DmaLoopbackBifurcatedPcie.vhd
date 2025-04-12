-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simple DMA loopback Example
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

entity XilinxVariumC1100DmaLoopbackBifurcatedPcie is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in    sl;
      qsfp0RefClkN : in    sl;
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in    sl;
      qsfp1RefClkN : in    sl;
      qsfp1RxP     : in    slv(3 downto 0);
      qsfp1RxN     : in    slv(3 downto 0);
      qsfp1TxP     : out   slv(3 downto 0);
      qsfp1TxN     : out   slv(3 downto 0);
      -- HBM Ports
      hbmCatTrip   : out   sl := '0';  -- HBM Catastrophic Over temperature Output signal to Satellite Controller: active HIGH indicator to Satellite controller to indicate the HBM has exceeds its maximum allowable temperature
      --------------
      --  Core Ports
      --------------
      -- Card Management Solution (CMS) Interface
      cmsUartRxd   : in    sl;
      cmsUartTxd   : out   sl;
      cmsGpio      : in    slv(3 downto 0);
      -- System Ports
      userClkP     : in    sl;
      userClkN     : in    sl;
      hbmRefClkP   : in    sl;
      hbmRefClkN   : in    sl;
      -- SI5394 Ports
      si5394Scl    : inout sl;
      si5394Sda    : inout sl;
      si5394IrqL   : in    sl;
      si5394LolL   : in    sl;
      si5394LosL   : in    sl;
      si5394RstL   : out   sl;
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    slv(1 downto 0);
      pciRefClkN   : in    slv(1 downto 0);
      pciRxP       : in    slv(15 downto 0);
      pciRxN       : in    slv(15 downto 0);
      pciTxP       : out   slv(15 downto 0);
      pciTxN       : out   slv(15 downto 0));
end XilinxVariumC1100DmaLoopbackBifurcatedPcie;

architecture top_level of XilinxVariumC1100DmaLoopbackBifurcatedPcie is

   constant DMA_SIZE_C : positive := 1;

   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);   -- 8  Byte (64-bit)  tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  -- 16 Byte (128-bit) tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  -- 32 Byte (256-bit) tData interface
   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 64, tDestBits => 8, tIdBits => 3);  -- 64 Byte (512-bit) tData interface

   signal dmaPriClk     : sl;
   signal dmaPriRst     : sl;
   signal dmaPriMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaPriSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal dmaSecClk     : sl;
   signal dmaSecRst     : sl;
   signal dmaSecMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaSecSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal cmsHbmCatTrip : sl                    := '0';
   signal cmsHbmTemp    : Slv7Array(1 downto 0) := (others => b"0000000");

begin

   U_Core : entity axi_pcie_core.XilinxVariumC1100Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DMA Interfaces
         dmaClk        => dmaPriClk,
         dmaRst        => dmaPriRst,
         dmaObMasters  => dmaPriMasters,
         dmaObSlaves   => dmaPriSlaves,
         dmaIbMasters  => dmaPriMasters,
         dmaIbSlaves   => dmaPriSlaves,
         --------------
         --  Core Ports
         --------------
         -- Card Management Solution (CMS) Interface
         cmsHbmCatTrip => cmsHbmCatTrip,
         cmsHbmTemp    => cmsHbmTemp,
         cmsUartRxd    => cmsUartRxd,
         cmsUartTxd    => cmsUartTxd,
         cmsGpio       => cmsGpio,
         -- System Ports
         userClkP      => userClkP,
         userClkN      => userClkN,
         hbmRefClkP    => hbmRefClkP,
         hbmRefClkN    => hbmRefClkN,
         -- SI5394 Ports
         si5394Scl     => si5394Scl,
         si5394Sda     => si5394Sda,
         si5394IrqL    => si5394IrqL,
         si5394LolL    => si5394LolL,
         si5394LosL    => si5394LosL,
         si5394RstL    => si5394RstL,
         -- PCIe Ports
         pciRstL       => pciRstL,
         pciRefClkP(0) => pciRefClkP(0),
         pciRefClkN(0) => pciRefClkN(0),
         pciRxP        => pciRxP(7 downto 0),
         pciRxN        => pciRxN(7 downto 0),
         pciTxP        => pciTxP(7 downto 0),
         pciTxN        => pciTxN(7 downto 0));

   U_ExtendedCore : entity axi_pcie_core.XilinxVariumC1100PcieExtendedCore
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
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
         pciRefClkP(0) => pciRefClkP(1),
         pciRefClkN(0) => pciRefClkN(1),
         pciRxP        => pciRxP(15 downto 8),
         pciRxN        => pciRxN(15 downto 8),
         pciTxP        => pciTxP(15 downto 8),
         pciTxN        => pciTxN(15 downto 8));

   U_UnusedQsfp : entity axi_pcie_core.TerminateQsfp
      generic map (
         TPD_G           => TPD_G,
         AXIL_CLK_FREQ_G => 250.0E+6)
      port map (
         -- AXI-Lite Interface
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
