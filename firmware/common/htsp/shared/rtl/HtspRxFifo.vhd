-------------------------------------------------------------------------------
-- File       : HtspRxFifo.vhd
-- Company    : SLAC National Accelerator Laboratory
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

entity HtspRxFifo is
   generic (
      TPD_G                 : time     := 1 ns;
      CASCADE_SIZE_G        : positive := 1;
      FIFO_ADDR_WIDTH_G     : positive := 12;
      FIFO_PAUSE_THRESH_G   : positive := 256;
      INT_WIDTH_SELECT_G    : string   := "WIDE";
      INT_DATA_WIDTH_G      : positive := 64;
      TX_MAX_PAYLOAD_SIZE_G : positive := 8192;
      NUM_VC_G              : positive);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- HTSP Interface (htspClk domain)
      htspClk         : in  sl;
      htspRst         : in  sl;
      rxlinkReady     : in  sl;
      htspRxMasters   : in  AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      htspRxCtrl      : out AxiStreamCtrlArray(NUM_VC_G-1 downto 0));
end HtspRxFifo;

architecture mapping of HtspRxFifo is

   signal htspMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxMasters   : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxSlaves    : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);
   signal disableSel  : slv(NUM_VC_G-1 downto 0);

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;

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

   BLOWOFF_FILTER : process (htspRxMasters, rxlinkReady) is
      variable tmp : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      variable i   : natural;
   begin
      tmp := htspRxMasters;
      for i in NUM_VC_G-1 downto 0 loop
         if (rxlinkReady = '0') then
            tmp(i).tValid := '0';
         end if;
      end loop;
      htspMasters <= tmp;
   end process;

   GEN_VEC :
   for i in NUM_VC_G-1 downto 0 generate

      U_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => false,
            VALID_THOLD_G       => (TX_MAX_PAYLOAD_SIZE_G/64),  -- Hold until enough to burst into the interleaving MUX
            VALID_BURST_MODE_G  => true,
            -- FIFO configurations
            SYNTH_MODE_G        => "xpm",
            MEMORY_TYPE_G       => "uram",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => FIFO_ADDR_WIDTH_G,
            FIFO_PAUSE_THRESH_G => FIFO_PAUSE_THRESH_G,
            CASCADE_SIZE_G      => CASCADE_SIZE_G,
            INT_WIDTH_SELECT_G  => INT_WIDTH_SELECT_G,
            INT_DATA_WIDTH_G    => INT_DATA_WIDTH_G,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => HTSP_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => HTSP_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => htspClk,
            sAxisRst    => htspReset,
            sAxisMaster => htspMasters(i),
            sAxisCtrl   => htspRxCtrl(i),
            -- Master Port
            mAxisClk    => htspClk,
            mAxisRst    => htspReset,
            mAxisMaster => rxMasters(i),
            mAxisSlave  => rxSlaves(i));

   end generate GEN_VEC;

   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_VC_G,
         MODE_G               => "INDEXED",
         TID_MODE_G           => "INDEXED",
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => (TX_MAX_PAYLOAD_SIZE_G/64),  -- Hold until enough to burst into the interleaving MUX
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => htspClk,
         axisRst      => htspReset,
         -- Slaves
         disableSel   => disableSel,
         sAxisMasters => rxMasters,
         sAxisSlaves  => rxSlaves,
         -- Master
         mAxisMaster  => rxMaster,
         mAxisSlave   => rxSlave);

   U_disableSel : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => NUM_VC_G)
      port map (
         clk     => htspClk,
         dataIn  => dmaBuffGrpPause(NUM_VC_G-1 downto 0),
         dataOut => disableSel);

   ASYNC_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => HTSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => HTSP_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => htspClk,
         sAxisRst    => htspReset,
         sAxisMaster => rxMaster,
         sAxisSlave  => rxSlave,
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaReset,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

end mapping;
