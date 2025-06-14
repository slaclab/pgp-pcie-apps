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
use surf.Pgp4Pkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxVariumC1100Pgp4_12Gbps is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      DMA_AXIS_CONFIG_G    : AxiStreamConfigType         := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  --- 16 Byte (128-bit) tData interface
      BUILD_INFO_G         : BuildInfoType);
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
      pciRefClkP   : in    slv(0 downto 0);
      pciRefClkN   : in    slv(0 downto 0);
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end XilinxVariumC1100Pgp4_12Gbps;

architecture top_level of XilinxVariumC1100Pgp4_12Gbps is

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

   signal axilClk         : sl;
   signal axilRst         : sl;
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
   signal dmaObMasters    : AxiStreamMasterArray(7 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(7 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(7 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(7 downto 0);
   signal buffIbMasters   : AxiStreamMasterArray(7 downto 0);
   signal buffIbSlaves    : AxiStreamSlaveArray(7 downto 0);

   signal hbmRefClk : sl;
   signal userClk   : sl;

   signal eventTrigMsgCtrl : AxiStreamCtrlArray(7 downto 0) := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal pgpClkOut        : slv(7 downto 0);
   signal pgpTxIn          : Pgp4TxInArray(7 downto 0)      := (others => PGP4_TX_IN_INIT_C);

   signal cmsHbmCatTrip : sl                    := '0';
   signal cmsHbmTemp    : Slv7Array(1 downto 0) := (others => b"0000000");

begin

   U_axilClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => true,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 10.0,    -- 100MHz
         DIVCLK_DIVIDE_G    => 8,       -- 12.5MHz = 100MHz/8
         CLKFBOUT_MULT_F_G  => 96.875,  -- 1210.9375MHz = 96.875 x 12.5MHz
         CLKOUT0_DIVIDE_F_G => 7.75)    -- 156.25MHz = 1210.9375MHz/7.75
      port map(
         -- Clock Input
         clkIn     => userClk,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   U_Core : entity axi_pcie_core.XilinxVariumC1100Core
      generic map (
         TPD_G                => TPD_G,
         QSFP_CDR_DISABLE_G   => false,  -- FALSE: 25.78125Gbps/12.5Gbps = 2.0625 = 2 + 1/16
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G           => 8)
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
         appClk          => axilClk,
         appRst          => axilRst,
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
         axiClk              => axilClk,
         axiClkRst           => axilRst,
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
   U_HbmDmaBuffer : entity axi_pcie_core.HbmDmaBuffer
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => 8,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         CLKFBOUT_MULT_G   => 10,       -- 1.0GHz = 10 x 100 MHz
         CLKOUT0_DIVIDE_G  => 4,        -- 250MHz = 1.0GHz/4
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
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(0),
         axilReadSlave    => axilReadSlaves(0),
         axilWriteMaster  => axilWriteMasters(0),
         axilWriteSlave   => axilWriteSlaves(0),
         -- Trigger Event streams (eventClk domain)
         eventClk         => pgpClkOut,
         eventTrigMsgCtrl => eventTrigMsgCtrl,
         -- AXI Stream Interface (axisClk domain)
         axisClk          => (others => dmaClk),
         axisRst          => (others => dmaRst),
         sAxisMasters     => buffIbMasters,
         sAxisSlaves      => buffIbSlaves,
         mAxisMasters     => dmaIbMasters,
         mAxisSlaves      => dmaIbSlaves);

   GEN_LANE : for i in 7 downto 0 generate
      pgpTxIn(i).locData(0) <= eventTrigMsgCtrl(i).pause;
   end generate;

   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         RATE_G            => "12.5Gbps",
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(4),
         axilReadSlave   => axilReadSlaves(4),
         axilWriteMaster => axilWriteMasters(4),
         axilWriteSlave  => axilWriteSlaves(4),
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => buffIbMasters,
         dmaIbSlaves     => buffIbSlaves,
         -- Non-VC Interface (pgpClkOut domain)
         pgpClkOut       => pgpClkOut,
         pgpTxIn         => pgpTxIn,
         ------------------
         --  Hardware Ports
         ------------------
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP,
         qsfp0RefClkN    => qsfp0RefClkN,
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP    => qsfp1RefClkP,
         qsfp1RefClkN    => qsfp1RefClkN,
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN);

end top_level;
