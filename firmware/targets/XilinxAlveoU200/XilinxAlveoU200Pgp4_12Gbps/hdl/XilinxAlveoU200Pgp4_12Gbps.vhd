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
use axi_pcie_core.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxAlveoU200Pgp4_12Gbps is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      DMA_AXIS_CONFIG_G    : AxiStreamConfigType         := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  --- 32 Byte (256-bit) tData interface
      BUILD_INFO_G         : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP  : in    slv(1 downto 0);
      qsfp0RefClkN  : in    slv(1 downto 0);
      qsfp0RxP      : in    slv(3 downto 0);
      qsfp0RxN      : in    slv(3 downto 0);
      qsfp0TxP      : out   slv(3 downto 0);
      qsfp0TxN      : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP  : in    slv(1 downto 0);
      qsfp1RefClkN  : in    slv(1 downto 0);
      qsfp1RxP      : in    slv(3 downto 0);
      qsfp1RxN      : in    slv(3 downto 0);
      qsfp1TxP      : out   slv(3 downto 0);
      qsfp1TxN      : out   slv(3 downto 0);
      -- DDR Ports
      ddrClkP       : in    slv(3 downto 0);
      ddrClkN       : in    slv(3 downto 0);
      ddrOut        : out   DdrOutArray(3 downto 0);
      ddrInOut      : inout DdrInOutArray(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      userClkP      : in    sl;
      userClkN      : in    sl;
      i2cRstL       : out   sl;
      i2cScl        : inout sl;
      i2cSda        : inout sl;
      -- QSFP[1:0] Ports
      qsfpFs        : out   Slv2Array(1 downto 0);
      qsfpRefClkRst : out   slv(1 downto 0);
      qsfpRstL      : out   slv(1 downto 0);
      qsfpLpMode    : out   slv(1 downto 0);
      qsfpModSelL   : out   slv(1 downto 0);
      qsfpModPrsL   : in    slv(1 downto 0);
      -- PCIe Ports
      pciRstL       : in    sl;
      pciRefClkP    : in    sl;
      pciRefClkN    : in    sl;
      pciRxP        : in    slv(15 downto 0);
      pciRxN        : in    slv(15 downto 0);
      pciTxP        : out   slv(15 downto 0);
      pciTxN        : out   slv(15 downto 0));
end XilinxAlveoU200Pgp4_12Gbps;

architecture top_level of XilinxAlveoU200Pgp4_12Gbps is

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

   signal userClk156      : sl;
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

   signal ddrClk          : slv(3 downto 0);
   signal ddrRst          : slv(3 downto 0);
   signal ddrReady        : slv(3 downto 0);
   signal ddrWriteMasters : AxiWriteMasterArray(3 downto 0);
   signal ddrWriteSlaves  : AxiWriteSlaveArray(3 downto 0);
   signal ddrReadMasters  : AxiReadMasterArray(3 downto 0);
   signal ddrReadSlaves   : AxiReadSlaveArray(3 downto 0);

   signal eventTrigMsgCtrl : AxiStreamCtrlArray(7 downto 0) := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal pgpClkOut        : slv(7 downto 0);
   signal pgpTxIn          : Pgp4TxInArray(7 downto 0)      := (others => PGP4_TX_IN_INIT_C);

begin

   U_axilClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => true,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 6.4,      -- 156.25 MHz
         CLKFBOUT_MULT_G   => 8,        -- 1.25GHz = 8 x 156.25 MHz
         CLKOUT0_DIVIDE_G  => 8)        -- 156.25MHz = 1.25GHz/8
      port map(
         -- Clock Input
         clkIn     => userClk156,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   U_Core : entity axi_pcie_core.XilinxAlveoU200Core
      generic map (
         TPD_G                => TPD_G,
         QSFP_CDR_DISABLE_G   => true,  -- < 25Gb/s/lane
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G           => 8)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         userClk156      => userClk156,
         -- DMA Interfaces
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk          => axilClk,
         appRst          => axilRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         userClkP        => userClkP,
         userClkN        => userClkN,
         i2cRstL         => i2cRstL,
         i2cScl          => i2cScl,
         i2cSda          => i2cSda,
         -- QSFP[1:0] Ports
         qsfpFs          => qsfpFs,
         qsfpRefClkRst   => qsfpRefClkRst,
         qsfpRstL        => qsfpRstL,
         qsfpLpMode      => qsfpLpMode,
         qsfpModSelL     => qsfpModSelL,
         qsfpModPrsL     => qsfpModPrsL,
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

   --------------------
   -- MIG[3:0] IP Cores
   --------------------
   U_Mig : entity axi_pcie_core.MigAll
      generic map (
         TPD_G => TPD_G)
      port map (
         extRst          => dmaRst,
         -- AXI MEM Interface
         axiClk          => ddrClk,
         axiRst          => ddrRst,
         axiReady        => ddrReady,
         axiWriteMasters => ddrWriteMasters,
         axiWriteSlaves  => ddrWriteSlaves,
         axiReadMasters  => ddrReadMasters,
         axiReadSlaves   => ddrReadSlaves,
         -- DDR Ports
         ddrClkP         => ddrClkP,
         ddrClkN         => ddrClkN,
         ddrOut          => ddrOut,
         ddrInOut        => ddrInOut);

   ----------------------------
   -- DMA Inbound Large Buffer
   ----------------------------
   U_MigDmaBuffer : entity axi_pcie_core.MigDmaBuffer
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => 8,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(0).baseAddr)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(0),
         axilReadSlave    => axilReadSlaves(0),
         axilWriteMaster  => axilWriteMasters(0),
         axilWriteSlave   => axilWriteSlaves(0),
         -- Trigger Event streams (eventClk domain)
         eventClk         => axilClk,
         eventTrigMsgCtrl => eventTrigMsgCtrl,
         -- AXI Stream Interface (axisClk domain)
         axisClk          => dmaClk,
         axisRst          => dmaRst,
         sAxisMasters     => buffIbMasters,
         sAxisSlaves      => buffIbSlaves,
         mAxisMasters     => dmaIbMasters,
         mAxisSlaves      => dmaIbSlaves,
         -- DDR AXI MEM Interface
         ddrClk           => ddrClk,
         ddrRst           => ddrRst,
         ddrReady         => ddrReady,
         ddrWriteMasters  => ddrWriteMasters,
         ddrWriteSlaves   => ddrWriteSlaves,
         ddrReadMasters   => ddrReadMasters,
         ddrReadSlaves    => ddrReadSlaves);

   GEN_LANE : for i in 7 downto 0 generate
      U_remoteDmaPause : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => pgpClkOut(i),
            dataIn  => eventTrigMsgCtrl(i).pause,
            dataOut => pgpTxIn(i).locData(0));
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
