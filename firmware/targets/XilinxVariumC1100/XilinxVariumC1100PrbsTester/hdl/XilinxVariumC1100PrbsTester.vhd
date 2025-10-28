-------------------------------------------------------------------------------
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

entity XilinxVariumC1100PrbsTester is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- HBM Ports
      hbmCatTrip : out   sl;  -- HBM Catastrophic Over temperature Output signal to Satellite Controller: active HIGH indicator to Satellite controller to indicate the HBM has exceeds its maximum allowable temperature
      --------------
      --  Core Ports
      --------------
      -- Card Management Solution (CMS) Interface
      cmsUartRxd : in    sl;
      cmsUartTxd : out   sl;
      cmsGpio    : in    slv(3 downto 0);
      -- System Ports
      userClkP   : in    sl;
      userClkN   : in    sl;
      hbmRefClkP : in    sl;
      hbmRefClkN : in    sl;
      -- SI5394 Ports
      si5394Scl  : inout sl;
      si5394Sda  : inout sl;
      si5394IrqL : in    sl;
      si5394LolL : in    sl;
      si5394LosL : in    sl;
      si5394RstL : out   sl;
      -- PCIe Ports
      pciRstL    : in    sl;
      pciRefClkP : in    slv(0 downto 0);
      pciRefClkN : in    slv(0 downto 0);
      pciRxP     : in    slv(7 downto 0);
      pciRxN     : in    slv(7 downto 0);
      pciTxP     : out   slv(7 downto 0);
      pciTxN     : out   slv(7 downto 0));
end XilinxVariumC1100PrbsTester;

architecture top_level of XilinxVariumC1100PrbsTester is

   constant DMA_SIZE_C : positive := 1;

   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);  -- 8  Byte (64-bit)  tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  -- 16 Byte (128-bit) tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  -- 32 Byte (256-bit) tData interface
   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 64, tDestBits => 8, tIdBits => 3);  -- 64 Byte (512-bit) tData interface

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(4 downto 0) := (
      0               => (
         baseAddr     => x"0010_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => x"0020_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      2               => (
         baseAddr     => x"0030_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      3               => (
         baseAddr     => x"0040_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      4               => (
         baseAddr     => x"0080_0000",
         addrBits     => 23,
         connectivity => x"FFFF"));

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilReadMasters  : AxiLiteReadMasterArray(4 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(4 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(4 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);
   signal buffIbMasters   : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal buffIbSlaves    : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal hbmRefClk : sl;
   signal userClk   : sl;

   signal cmsHbmCatTrip : sl                    := '0';
   signal cmsHbmTemp    : Slv7Array(1 downto 0) := (others => b"0000000");

begin

   U_Core : entity axi_pcie_core.XilinxVariumC1100Core
      generic map (
         TPD_G              => TPD_G,
         QSFP_CDR_DISABLE_G => true,
         BUILD_INFO_G       => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G  => DMA_AXIS_CONFIG_C,
         DMA_BURST_BYTES_G  => 4096,
         DMA_SIZE_G         => DMA_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         userClk         => userClk,
         hbmRefClk       => hbmRefClk,
         -- DMA Interfaces
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk          => dmaClk,
         appRst          => dmaRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- Card Management Solution (CMS) Interface
         cmsHbmCatTrip   => cmsHbmCatTrip,
         cmsHbmTemp      => cmsHbmTemp,
         cmsUartRxd      => cmsUartRxd,
         cmsUartTxd      => cmsUartTxd,
         cmsGpio         => cmsGpio,
         -- System Ports
         userClkP        => userClkP,
         userClkN        => userClkN,
         hbmRefClkP      => hbmRefClkP,
         hbmRefClkN      => hbmRefClkN,
         -- SI5394 Ports
         si5394Scl       => si5394Scl,
         si5394Sda       => si5394Sda,
         si5394IrqL      => si5394IrqL,
         si5394LolL      => si5394LolL,
         si5394LosL      => si5394LosL,
         si5394RstL      => si5394RstL,
         -- PCIe Ports
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 5,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         axiClk              => dmaClk,
         axiClkRst           => dmaRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ----------------------------
   -- DMA Inbound Large Buffer
   ----------------------------
   U_HbmDmaBuffer : entity axi_pcie_core.HbmDmaBufferV2
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_C,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(0).baseAddr)
      port map (
         -- Card Management Solution (CMS) Interface
         cmsHbmCatTrip    => cmsHbmCatTrip,
         cmsHbmTemp       => cmsHbmTemp,
         -- HBM Interface
         userClk          => userClk,
         hbmRefClk        => hbmRefClk,
         hbmCatTrip       => hbmCatTrip,
         -- AXI-Lite Interface (axilClk domain)
         axilClk          => dmaClk,
         axilRst          => dmaRst,
         axilReadMaster   => axilReadMasters(0),
         axilReadSlave    => axilReadSlaves(0),
         axilWriteMaster  => axilWriteMasters(0),
         axilWriteSlave   => axilWriteSlaves(0),
         -- Trigger Event streams (eventClk domain)
         eventClk         => (others => dmaClk),
         eventTrigMsgCtrl => open,
         -- Inbound AXIS Interface (sAxisClk domain)
         sAxisClk         => (others => dmaClk),
         sAxisRst         => (others => dmaRst),
         sAxisMasters     => buffIbMasters,
         sAxisSlaves      => buffIbSlaves,
         -- Outbound AXIS Interface (sAxisClk domain)
         mAxisClk         => (others => dmaClk),
         mAxisRst         => (others => dmaRst),
         mAxisMasters     => dmaIbMasters,
         mAxisSlaves      => dmaIbSlaves);

   ---------------
   -- PRBS Modules
   ---------------
   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_C,
         NUM_VC_G          => 1,
         PRBS_SEED_SIZE_G  => 8*DMA_AXIS_CONFIG_C.TDATA_BYTES_C,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- AXI-Lite Interface
         axilReadMaster  => axilReadMasters(4),
         axilReadSlave   => axilReadSlaves(4),
         axilWriteMaster => axilWriteMasters(4),
         axilWriteSlave  => axilWriteSlaves(4),
         -- DMA Interface
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => buffIbMasters,
         dmaIbSlaves     => buffIbSlaves);

end top_level;
