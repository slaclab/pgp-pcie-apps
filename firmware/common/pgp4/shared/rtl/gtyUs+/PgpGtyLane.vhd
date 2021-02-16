-------------------------------------------------------------------------------
-- File       : PgpGtyLane.vhd
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
use surf.Pgp4Pkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

entity PgpGtyLane is
   generic (
      TPD_G             : time             := 1 ns;
      LANE_G            : natural          := 0;
      NUM_VC_G          : positive         := 4;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      RATE_G            : string           := "10.3125Gbps";  -- or "6.25Gbps" or "3.125Gbps"
      AXI_BASE_ADDR_G   : slv(31 downto 0) := (others => '0'));
   port (
      -- QPLL Interface
      qpllLock        : in  slv(1 downto 0);
      qpllClk         : in  slv(1 downto 0);
      qpllRefclk      : in  slv(1 downto 0);
      qpllRst         : out slv(1 downto 0);
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
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
end PgpGtyLane;

architecture mapping of PgpGtyLane is

   constant AXIS_CLK_FREQ_C : real :=
      ite(RATE_G = "10.3125Gbps", 10.3125E+9/66.0,
          ite(RATE_G = "6.25Gbps", 6.25E+9/66.0,
              ite(RATE_G = "3.125Gbps", 3.125E+9/66.0,
                  156.25E+6)));

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

   signal pgpTxOut     : Pgp4TxOutType;
   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal pgpRxOut     : Pgp4RxOutType;
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_G-1 downto 0);

begin

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
   U_Pgp : entity surf.Pgp4GtyUs
      generic map (
         TPD_G            => TPD_G,
         RATE_G           => RATE_G,
         EN_DRP_G         => false,
         EN_PGP_MON_G     => true,
         NUM_VC_G         => NUM_VC_G,
         AXIL_CLK_FREQ_G  => 156.25E+6,
         AXIL_BASE_ADDR_G => AXI_BASE_ADDR_G)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- QPLL Interface
         qpllLock        => qpllLock,
         qpllClk         => qpllClk,
         qpllRefclk      => qpllRefclk,
         qpllRst         => qpllRst,
         -- Gt Serial IO
         pgpGtTxP        => pgpTxP,
         pgpGtTxN        => pgpTxN,
         pgpGtRxP        => pgpRxP,
         pgpGtRxN        => pgpRxN,
         -- Clocking
         pgpClk          => pgpClk,
         pgpClkRst       => pgpRst,
         -- Non VC Rx Signals
         pgpRxIn         => PGP4_RX_IN_INIT_C,
         pgpRxOut        => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn         => PGP4_TX_IN_INIT_C,
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
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         LANE_G            => LANE_G,
         NUM_VC_G          => NUM_VC_G)
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
         AXIS_CONFIG_G    => PGP4_AXIS_CONFIG_C)
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
         AXIS_CONFIG_G    => PGP4_AXIS_CONFIG_C)
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
