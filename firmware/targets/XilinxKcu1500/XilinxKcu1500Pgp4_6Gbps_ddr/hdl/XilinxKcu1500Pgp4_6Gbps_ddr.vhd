-------------------------------------------------------------------------------
-- File       : XilinxKcu1500Pgp4_6Gbps_ddr.vhd
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
use surf.Pgp4Pkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;
use axi_pcie_core.MigPkg.all;

library daq_stream_cache;

library unisim;
use unisim.vcomponents.all;

entity XilinxKcu1500Pgp4_6Gbps_ddr is
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
      i2cRstL      : out   sl;
      i2cScl       : inout sl;
      i2cSda       : inout sl;
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
      ddrClkP      : in    slv          (1 downto 0);
      ddrClkN      : in    slv          (1 downto 0);
      ddrOut       : out   DdrOutArray  (1 downto 0);
      ddrInOut     : inout DdrInOutArray(1 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end XilinxKcu1500Pgp4_6Gbps_ddr;

architecture top_level of XilinxKcu1500Pgp4_6Gbps_ddr is

   signal userClk156      : sl;
   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   constant NUM_AXIL_MASTERS_C : positive := 2;
   constant HW_INDEX_C : natural := 0;
   constant SC_INDEX_C : natural := 1;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
     HW_INDEX_C => ( baseAddr     => x"0080_0000",
                     addrBits     => 23,
                     connectivity => x"FFFF"),
     SC_INDEX_C => ( baseAddr     => x"0010_0000",
                     addrBits     => 20,
                     connectivity => x"FFFF"));

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0) := (others=>'0');
   signal dmaObMasters    : AxiStreamMasterArray(8 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves     : AxiStreamSlaveArray(8 downto 0)  := (others=>AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters    : AxiStreamMasterArray(8 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves     : AxiStreamSlaveArray(8 downto 0)  := (others=>AXI_STREAM_SLAVE_FORCE_C);

   signal axisClk          : sl;
   signal axisRst          : sl;
   signal axisClkV         : slv(7 downto 0);
   signal axisRstV         : slv(7 downto 0);
   signal axisObMasters    : AxiStreamMasterArray(7 downto 0);
   signal axisObSlaves     : AxiStreamSlaveArray(7 downto 0);
   signal axisIbMasters    : AxiStreamMasterArray(7 downto 0);
   signal axisIbSlaves     : AxiStreamSlaveArray(7 downto 0);
   
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

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
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

   U_Core : entity axi_pcie_core.XilinxKcu1500Core
      generic map (
         TPD_G                => TPD_G,
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
--         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters(7 downto 0),
         dmaObSlaves     => dmaObSlaves (7 downto 0),
         dmaIbMasters    => dmaIbMasters(7 downto 0),
         dmaIbSlaves     => dmaIbSlaves (7 downto 0),
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
         emcClk          => emcClk,
         userClkP        => userClkP,
         userClkN        => userClkN,
         i2cRstL         => i2cRstL,
         i2cScl          => i2cScl,
         i2cSda          => i2cSda,
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
         -- PCIe Ports
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   axisClkV <= (others=>axilClk);
   axisRstV <= (others=>axilRst);
   
   U_DmaCache : entity daq_stream_cache.StreamCache
     generic map (
       TPD_G             => TPD_G,
       AXI_BASE_ADDR_G   => AXIL_CONFIG_C(SC_INDEX_C).baseAddr,
       APP_AXIS_CONFIG_G => PGP4_AXIS_CONFIG_C,
       DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
       NUM_LANES_G       => 8 )
     port map (
       -- AXI-Lite Interface
       axilClk               => axilClk,
       axilRst               => axilRst,
       axilReadMaster        => axilReadMasters (SC_INDEX_C),
       axilReadSlave         => axilReadSlaves  (SC_INDEX_C),
       axilWriteMaster       => axilWriteMasters(SC_INDEX_C),
       axilWriteSlave        => axilWriteSlaves (SC_INDEX_C),
       -- PGP Streams (axilClk domain)
       appClk                => axisClkV,
       appRst                => axisRstV,
       appIbMasters          => axisIbMasters,
       appIbSlaves           => axisIbSlaves,
       appObMasters          => axisObMasters,
       appObSlaves           => axisObSlaves,
       -- DMA Interface (dmaClk domain)
       dmaClk                => dmaClk,
       dmaRst                => dmaRst,
       dmaIbMasters          => dmaIbMasters,
       dmaIbSlaves           => dmaIbSlaves,
       dmaObMasters          => dmaObMasters,
       dmaObSlaves           => dmaObSlaves,
       -- DDR Ports
       ddrClkP               => ddrClkP,
       ddrClkN               => ddrClkN,
       ddrOut                => ddrOut,
       ddrInOut              => ddrInOut );

   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         RATE_G            => "6.25Gbps",
         DMA_AXIS_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (HW_INDEX_C),
         axilReadSlave   => axilReadSlaves  (HW_INDEX_C),
         axilWriteMaster => axilWriteMasters(HW_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (HW_INDEX_C),
         -- DMA Interface (dmaClk domain)
         dmaClk          => axilClk,
         dmaRst          => axilRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => axisObMasters,
         dmaObSlaves     => axisObSlaves,
         dmaIbMasters    => axisIbMasters,
         dmaIbSlaves     => axisIbSlaves,
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
