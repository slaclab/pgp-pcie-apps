-------------------------------------------------------------------------------
-- File       : HtspTxFifo.vhd
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
use surf.AxiStreamPkg.all;
use surf.HtspPkg.all;

entity HtspTxFifo is
   generic (
      TPD_G                 : time     := 1 ns;
      TX_MAX_PAYLOAD_SIZE_G : positive := 8192;
      NUM_VC_G              : positive);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk        : in  sl;
      dmaRst        : in  sl;
      dmaObMaster   : in  AxiStreamMasterType;
      dmaObSlave    : out AxiStreamSlaveType;
      -- HTSP Interface (htspClk domain)
      htspClk       : in  sl;
      htspRst       : in  sl;
      rxlinkReady   : in  sl;
      txlinkReady   : in  sl;
      htspTxMasters : out AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      htspTxSlaves  : in  AxiStreamSlaveArray(NUM_VC_G-1 downto 0));
end HtspTxFifo;

architecture mapping of HtspTxFifo is

   signal dmaMaster : AxiStreamMasterType;
   signal dmaCtrl   : AxiStreamCtrlType;

   signal txMaster : AxiStreamMasterType;
   signal txSlave  : AxiStreamSlaveType;

   signal txMasterSof : AxiStreamMasterType;
   signal txSlaveSof  : AxiStreamSlaveType;

   signal linkReady : sl;
   signal flushEn   : sl;

   signal htspReset : sl;
   signal dmaReset  : sl;

begin

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

   linkReady <= txlinkReady and rxlinkReady;

   U_FlushSync : entity surf.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '0')
      port map (
         clk     => dmaClk,
         rst     => dmaReset,
         dataIn  => linkReady,
         dataOut => flushEn);

   U_Flush : entity surf.AxiStreamFlush
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => HTSP_AXIS_CONFIG_C,
         SSI_EN_G      => true)
      port map (
         axisClk     => dmaClk,
         axisRst     => dmaReset,
         flushEn     => flushEn,
         sAxisMaster => dmaObMaster,
         sAxisSlave  => dmaObSlave,
         mAxisMaster => dmaMaster,
         mAxisCtrl   => dmaCtrl);

   U_RESIZE : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => (TX_MAX_PAYLOAD_SIZE_G/64),
         VALID_BURST_MODE_G  => true,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 256,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => HTSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => HTSP_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => dmaClk,
         sAxisRst    => dmaReset,
         sAxisMaster => dmaMaster,
         sAxisCtrl   => dmaCtrl,
         -- Master Port
         mAxisClk    => htspClk,
         mAxisRst    => htspReset,
         mAxisMaster => txMaster,
         mAxisSlave  => txSlave);

   U_SOF : entity surf.SsiInsertSof
      generic map (
         TPD_G               => TPD_G,
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => HTSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => HTSP_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => htspClk,
         sAxisRst    => htspReset,
         sAxisMaster => txMaster,
         sAxisSlave  => txSlave,
         -- Master Port
         mAxisClk    => htspClk,
         mAxisRst    => htspReset,
         mAxisMaster => txMasterSof,
         mAxisSlave  => txSlaveSof);

   U_DeMux : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => NUM_VC_G,
         MODE_G        => "INDEXED",
         PIPE_STAGES_G => 1,
         TDEST_HIGH_G  => bitSize(NUM_VC_G)-1,
         TDEST_LOW_G   => 0)
      port map (
         -- Clock and reset
         axisClk      => htspClk,
         axisRst      => htspReset,
         -- Slave
         sAxisMaster  => txMasterSof,
         sAxisSlave   => txSlaveSof,
         -- Masters
         mAxisMasters => htspTxMasters,
         mAxisSlaves  => htspTxSlaves);

end mapping;
