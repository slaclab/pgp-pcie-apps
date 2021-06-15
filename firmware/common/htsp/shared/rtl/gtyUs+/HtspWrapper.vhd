-------------------------------------------------------------------------------
-- File       : HtspWrapper.vhd
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
use surf.HtspPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity HtspWrapper is
   generic (
      TPD_G                 : time             := 1 ns;
      AXIL_BASE_ADDR_G      : slv(31 downto 0) := x"0080_0000";
      AXIL_CLK_FREQ_G       : real             := 156.25E+6;
      NUM_VC_G              : positive         := 4;
      TX_MAX_PAYLOAD_SIZE_G : positive         := 8192);
   port (
      -- QSFP Ports
      qsfpRefClkP     : in  sl;
      qsfpRefClkN     : in  sl;
      qsfpRxP         : in  slv(3 downto 0);
      qsfpRxN         : in  slv(3 downto 0);
      qsfpTxP         : out slv(3 downto 0);
      qsfpTxN         : out slv(3 downto 0);
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
end HtspWrapper;

architecture mapping of HtspWrapper is

   constant NUM_AXIL_MASTERS_C : natural := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal htspTxIn  : HtspTxInType := HTSP_TX_IN_INIT_C;
   signal htspTxOut : HtspTxOutType;

   signal htspRxIn  : HtspRxInType := HTSP_RX_IN_INIT_C;
   signal htspRxOut : HtspRxOutType;

   signal htspTxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal htspTxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal htspRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal htspRxCtrl    : AxiStreamCtrlArray(NUM_VC_G-1 downto 0);

   signal htspClk : sl;
   signal htspRst : sl;

   signal axilReset : sl;
   signal htspReset : sl;
   signal dmaReset  : sl;

begin

   U_axilRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => axilRst,
         rstOut => axilReset);

   U_htspRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => htspClk,
         rstIn  => htspRst,
         rstOut => htspReset);

   U_dmaRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => dmaClk,
         rstIn  => dmaRst,
         rstOut => dmaReset);

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
         axiClkRst           => axilReset,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------
   -- HTSP Core
   -----------
   U_Htsp : entity surf.HtspCaui4Gty
      generic map (
         TPD_G                 => TPD_G,
         -- HTSP Settings
         NUM_VC_G              => NUM_VC_G,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_G,
         -- AXI-Lite Settings
         AXIL_WRITE_EN_G       => true,
         AXIL_BASE_ADDR_G      => AXIL_CONFIG_C(0).baseAddr,
         AXIL_CLK_FREQ_G       => AXIL_CLK_FREQ_G)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilReset,
         -- HTSP Clock and Reset
         htspClk         => htspClk,
         htspRst         => htspRst,
         -- Non VC Rx Signals
         htspRxIn        => htspRxIn,
         htspRxOut       => htspRxOut,
         -- Non VC Tx Signals
         htspTxIn        => htspTxIn,
         htspTxOut       => htspTxOut,
         -- Frame Transmit Interface
         htspTxMasters   => htspTxMasters,
         htspTxSlaves    => htspTxSlaves,
         -- Frame Receive Interface
         htspRxMasters   => htspRxMasters,
         htspRxCtrl      => htspRxCtrl,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilReset,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0),
         -- GT Ports
         gtRefClkP       => qsfpRefClkP,
         gtRefClkN       => qsfpRefClkN,
         gtRxP           => qsfpRxP,
         gtRxN           => qsfpRxN,
         gtTxP           => qsfpTxP,
         gtTxN           => qsfpTxN);

   -------------------------
   -- Monitor the TX streams
   -------------------------
   U_AXIS_TX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => HTSP_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => NUM_VC_G,
         AXIS_CONFIG_G    => HTSP_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => htspClk,
         axisRst          => htspReset,
         axisMasters      => htspTxMasters,
         axisSlaves       => htspTxSlaves,
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilReset,
         sAxilWriteMaster => axilWriteMasters(1),
         sAxilWriteSlave  => axilWriteSlaves(1),
         sAxilReadMaster  => axilReadMasters(1),
         sAxilReadSlave   => axilReadSlaves(1));

   -------------------------
   -- Monitor the RX streams
   -------------------------
   U_AXIS_RX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => HTSP_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => NUM_VC_G,
         AXIS_CONFIG_G    => HTSP_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => htspClk,
         axisRst          => htspReset,
         axisMasters      => htspRxMasters,
         axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- SLAVE_READY_EN_G=false
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilReset,
         sAxilWriteMaster => axilWriteMasters(2),
         sAxilWriteSlave  => axilWriteSlaves(2),
         sAxilReadMaster  => axilReadMasters(2),
         sAxilReadSlave   => axilReadSlaves(2));

   ----------
   -- TX Path
   ----------
   U_Tx : entity work.HtspTxFifo
      generic map (
         TPD_G                 => TPD_G,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_G,
         NUM_VC_G              => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk        => dmaClk,
         dmaRst        => dmaReset,
         dmaObMaster   => dmaObMaster,
         dmaObSlave    => dmaObSlave,
         -- HTSP Interface (htspClk)
         htspClk       => htspClk,
         htspRst       => htspReset,
         rxlinkReady   => htspRxOut.linkReady,
         txlinkReady   => htspTxOut.linkReady,
         htspTxMasters => htspTxMasters,
         htspTxSlaves  => htspTxSlaves);

   ----------
   -- RX Path
   ----------
   U_Rx : entity work.HtspRxFifo
      generic map (
         TPD_G                 => TPD_G,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_G,
         NUM_VC_G              => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaReset,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaIbMaster     => dmaIbMaster,
         dmaIbSlave      => dmaIbSlave,
         -- HTSP Interface (htspClk)
         htspClk         => htspClk,
         htspRst         => htspReset,
         rxlinkReady     => htspRxOut.linkReady,
         htspRxMasters   => htspRxMasters,
         htspRxCtrl      => htspRxCtrl);

end mapping;
