-------------------------------------------------------------------------------
-- File       : PgpLane.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp3Pkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLane is
   generic (
      TPD_G             : time                 := 1 ns;
      LANE_G            : natural range 0 to 7 := 0;
      NUM_VC_G          : positive             := 4;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := (others => '0'));
   port (
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      -- QPLL Interface
      qPllOutClk      : in  slv(1 downto 0);
      qPllOutRefClk   : in  slv(1 downto 0);
      qPllLock        : in  slv(1 downto 0);
      qPllRefClkLost  : in  slv(1 downto 0);
      qpllRst         : out slv(1 downto 0);
      -- TX PLL Interface
      gtTxOutClk      : out sl;
      gtTxPllRst      : out sl;
      txPllClk        : in  slv(2 downto 0);
      txPllRst        : in  slv(2 downto 0);
      gtTxPllLock     : in  sl;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLane;

architecture mapping of PgpLane is

   constant AXIS_CLK_FREQ_C : real := (6.25E+9/66.0);

   constant NUM_AXI_MASTERS_C : natural := 5;

   constant GT_INDEX_C     : natural := 0;
   constant MON_INDEX_C    : natural := 1;
   constant CTRL_INDEX_C   : natural := 2;
   constant TX_MON_INDEX_C : natural := 3;
   constant RX_MON_INDEX_C : natural := 4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_OK_C);

   signal pgpClk : sl;
   signal pgpRst : sl;
   signal wdtRst : sl;

   signal pgpTxIn      : Pgp3TxInType := PGP3_TX_IN_INIT_C;
   signal pgpTxOut     : Pgp3TxOutType;
   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal pgpRxIn      : Pgp3RxInType := PGP3_RX_IN_INIT_C;
   signal pgpRxOut     : Pgp3RxOutType;
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_G-1 downto 0);

begin

   U_Wtd : entity surf.WatchDogRst
      generic map(
         TPD_G      => TPD_G,
         DURATION_G => getTimeRatio(DMA_CLK_FREQ_C, 0.2))  -- 5 s timeout
      port map (
         clk    => axilClk,
         monIn  => pgpRxOut.remRxLinkReady,
         rstOut => wdtRst);

   U_PwrUpRst : entity surf.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => getTimeRatio(DMA_CLK_FREQ_C, 10.0))  -- 100 ms reset pulse
      port map (
         clk    => axilClk,
         arst   => wdtRst,
         rstOut => pgpRxIn.resetRx);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
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

   -----------
   -- PGP Core
   -----------
   U_Pgp : entity surf.Pgp3Gtp7
      generic map (
         TPD_G              => TPD_G,
         RATE_G             => "6.25Gbps",
         EN_PGP_MON_G       => true,
         CLKIN_PERIOD_G     => 2.56,
         BANDWIDTH_G        => "HIGH",
         CLKFBOUT_MULT_G    => 4,
         CLKOUT0_DIVIDE_G   => 16,
         CLKOUT1_DIVIDE_G   => 4,
         CLKOUT2_DIVIDE_G   => 8,
         NUM_VC_G           => NUM_VC_G,
         STATUS_CNT_WIDTH_G => 12,
         ERROR_CNT_WIDTH_G  => 8,
         AXIL_CLK_FREQ_G    => DMA_CLK_FREQ_C,
         AXIL_BASE_ADDR_G   => AXI_CONFIG_C(0).baseAddr)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- QPLL Interface
         qPllOutClk      => qPllOutClk,
         qPllOutRefClk   => qPllOutRefClk,
         qPllLock        => qPllLock,
         qpllRefClkLost  => qpllRefClkLost,
         qpllRst         => qpllRst,
         -- TX PLL Interface
         gtTxOutClk      => gtTxOutClk,
         gtTxPllRst      => gtTxPllRst,
         txPllClk        => txPllClk,
         txPllRst        => txPllRst,
         gtTxPllLock     => gtTxPllLock,
         -- Gt Serial IO
         pgpGtTxP        => pgpTxP,
         pgpGtTxN        => pgpTxN,
         pgpGtRxP        => pgpRxP,
         pgpGtRxN        => pgpRxN,
         -- Clocking
         pgpClk          => pgpClk,
         pgpClkRst       => pgpRst,
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         -- Frame Transmit Interface
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   --------------
   -- PGP TX Path
   --------------
   U_Tx : entity work.PgpLaneTx
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         NUM_VC_G          => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaObMaster  => dmaObMaster,
         dmaObSlave   => dmaObSlave,
         -- PGP Interface
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         rxlinkReady  => pgpRxOut.linkReady,
         txlinkReady  => pgpTxOut.linkReady,
         pgpTxMasters => pgpTxMasters,
         pgpTxSlaves  => pgpTxSlaves);

   --------------
   -- PGP RX Path
   --------------
   U_Rx : entity work.PgpLaneRx
      generic map (
         TPD_G               => TPD_G,
         DMA_AXIS_CONFIG_G   => DMA_AXIS_CONFIG_G,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_PAUSE_THRESH_G => 256,
         INT_WIDTH_SELECT_G  => "CUSTOM",
         INT_DATA_WIDTH_G    => 8,
         LANE_G              => LANE_G,
         NUM_VC_G            => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaIbMaster     => dmaIbMaster,
         dmaIbSlave      => dmaIbSlave,
         -- PGP RX Interface (pgpRxClk domain)
         pgpClk          => pgpClk,
         pgpRst          => pgpRst,
         rxlinkReady     => pgpRxOut.linkReady,
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl);

   -----------------------------
   -- Monitor the PGP TX streams
   -----------------------------
   U_AXIS_TX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => AXIS_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => NUM_VC_G,
         AXIS_CONFIG_G    => PGP3_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => pgpClk,
         axisRst          => pgpRst,
         axisMasters      => pgpTxMasters,
         axisSlaves       => pgpTxSlaves,
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(TX_MON_INDEX_C),
         sAxilWriteSlave  => axilWriteSlaves(TX_MON_INDEX_C),
         sAxilReadMaster  => axilReadMasters(TX_MON_INDEX_C),
         sAxilReadSlave   => axilReadSlaves(TX_MON_INDEX_C));

   -----------------------------
   -- Monitor the PGP RX streams
   -----------------------------
   U_AXIS_RX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => AXIS_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => NUM_VC_G,
         AXIS_CONFIG_G    => PGP3_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => pgpClk,
         axisRst          => pgpRst,
         axisMasters      => pgpRxMasters,
         axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- SLAVE_READY_EN_G=false
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(RX_MON_INDEX_C),
         sAxilWriteSlave  => axilWriteSlaves(RX_MON_INDEX_C),
         sAxilReadMaster  => axilReadMasters(RX_MON_INDEX_C),
         sAxilReadSlave   => axilReadSlaves(RX_MON_INDEX_C));

end mapping;
