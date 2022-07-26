-------------------------------------------------------------------------------
-- File       : XilinxAlveoU200PrbsTester.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: PRBS + DDR Memory Tester Example
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
use axi_pcie_core.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxAlveoU200PrbsTester is
   generic (
      TPD_G             : time                      := 1 ns;
      BUILD_INFO_G      : BuildInfoType;
      TX_EN_G           : boolean                   := true;
      RX_EN_G           : boolean                   := false;
      MIG_EN_G          : boolean                   := false;
      DMA_SIZE_G        : positive                  := 2;
      NUM_VC_G          : positive                  := 8;
      DMA_BURST_BYTES_G : integer range 256 to 4096 := 4096;
      DMA_BYTE_WIDTH_G  : integer range 8 to 64     := 32;
      PRBS_SEED_SIZE_G  : natural range 32 to 512   := 32);
   port (
      ---------------------
      --  Application Ports
      ---------------------
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
end XilinxAlveoU200PrbsTester;

architecture top_level of XilinxAlveoU200PrbsTester is

   constant START_ADDR_C : slv(MEM_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(MEM_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => DMA_BYTE_WIDTH_G, tDestBits => 8, tIdBits => 3);
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);   -- 8  Byte (64-bit)  tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  -- 16 Byte (128-bit) tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  -- 32 Byte (256-bit) tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 64, tDestBits => 8, tIdBits => 3);  -- 64 Byte (512-bit) tData interface

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
   signal dmaObMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

   signal ddrClk          : slv(3 downto 0);
   signal ddrRst          : slv(3 downto 0);
   signal ddrReady        : slv(3 downto 0);
   signal ddrWriteMasters : AxiWriteMasterArray(3 downto 0);
   signal ddrWriteSlaves  : AxiWriteSlaveArray(3 downto 0);
   signal ddrReadMasters  : AxiReadMasterArray(3 downto 0);
   signal ddrReadSlaves   : AxiReadSlaveArray(3 downto 0);

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

   -----------------------
   -- axi-pcie-core module
   -----------------------
   U_Core : entity axi_pcie_core.XilinxAlveoU200Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_BURST_BYTES_G => DMA_BURST_BYTES_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_G)
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
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk          => dmaClk,
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
   GEN_MIG : if (MIG_EN_G) generate
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

      ------------------------
      -- Memory Tester Modules
      ------------------------
      GEN_VEC : for i in 3 downto 0 generate
         U_AxiMemTester : entity surf.AxiMemTester
            generic map (
               TPD_G        => TPD_G,
               START_ADDR_G => START_ADDR_C,
               STOP_ADDR_G  => STOP_ADDR_C,
               AXI_CONFIG_G => MEM_AXI_CONFIG_C)
            port map (
               -- AXI-Lite Interface
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(i),
               axilReadSlave   => axilReadSlaves(i),
               axilWriteMaster => axilWriteMasters(i),
               axilWriteSlave  => axilWriteSlaves(i),
               -- DDR Memory Interface
               axiClk          => ddrClk(i),
               axiRst          => ddrRst(i),
               start           => ddrReady(i),
               axiWriteMaster  => ddrWriteMasters(i),
               axiWriteSlave   => ddrWriteSlaves(i),
               axiReadMaster   => ddrReadMasters(i),
               axiReadSlave    => ddrReadSlaves(i));
      end generate GEN_VEC;
   end generate GEN_MIG;

   ---------------
   -- PRBS Modules
   ---------------
   U_Hardware : entity work.Hardware
      generic map (
         TPD_G                        => TPD_G,
         TX_EN_G                      => TX_EN_G,
         RX_EN_G                      => RX_EN_G,
         DMA_SIZE_G                   => DMA_SIZE_G,
         NUM_VC_G                     => NUM_VC_G,
         PRBS_SEED_SIZE_G             => PRBS_SEED_SIZE_G,
         PRBS_FIFO_INT_WIDTH_SELECT_G => "WIDE",
         DMA_AXIS_CONFIG_G            => DMA_AXIS_CONFIG_C,
         AXI_BASE_ADDR_G              => AXIL_XBAR_CONFIG_C(4).baseAddr)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
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
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves);

end top_level;
