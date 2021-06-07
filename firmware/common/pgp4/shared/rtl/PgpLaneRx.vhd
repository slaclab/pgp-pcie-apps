-------------------------------------------------------------------------------
-- File       : PgpLaneRx.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- This file is part of 'ATLAS RD53 DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'ATLAS RD53 DEV', including this file,
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
use surf.Pgp4Pkg.all;

entity PgpLaneRx is
   generic (
      TPD_G               : time     := 1 ns;
      DMA_AXIS_CONFIG_G   : AxiStreamConfigType;
      FIFO_ADDR_WIDTH_G   : positive := 12;
      FIFO_PAUSE_THRESH_G : positive := 512;
      INT_WIDTH_SELECT_G  : string   := "WIDE";
      INT_DATA_WIDTH_G    : positive := 8;
      LANE_G              : natural;
      NUM_VC_G            : positive);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- PGP Interface (pgpClk domain)
      pgpClk          : in  sl;
      pgpRst          : in  sl;
      rxlinkReady     : in  sl;
      pgpRxMasters    : in  AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      pgpRxCtrl       : out AxiStreamCtrlArray(NUM_VC_G-1 downto 0));
end PgpLaneRx;

architecture mapping of PgpLaneRx is

   signal pgpMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxMasters  : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxSlaves   : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);
   signal disableSel : slv(NUM_VC_G-1 downto 0);

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;

begin

   BLOWOFF_FILTER : process (pgpRxMasters, rxlinkReady) is
      variable tmp : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      variable i   : natural;
   begin
      tmp := pgpRxMasters;
      for i in NUM_VC_G-1 downto 0 loop
         if (rxlinkReady = '0') then
            tmp(i).tValid := '0';
         end if;
      end loop;
      pgpMasters <= tmp;
   end process;

   GEN_VEC :
   for i in NUM_VC_G-1 downto 0 generate

      PGP_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => false,
            VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
            VALID_BURST_MODE_G  => true,
            -- FIFO configurations
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => FIFO_ADDR_WIDTH_G,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => FIFO_PAUSE_THRESH_G,
            INT_WIDTH_SELECT_G  => INT_WIDTH_SELECT_G,
            INT_DATA_WIDTH_G    => INT_DATA_WIDTH_G,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => PGP4_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
         port map (
            -- Slave Port
            sAxisClk    => pgpClk,
            sAxisRst    => pgpRst,
            sAxisMaster => pgpMasters(i),
            sAxisCtrl   => pgpRxCtrl(i),
            -- Master Port
            mAxisClk    => pgpClk,
            mAxisRst    => pgpRst,
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
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => pgpClk,
         axisRst      => pgpRst,
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
         clk     => pgpClk,
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
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => pgpClk,
         sAxisRst    => pgpRst,
         sAxisMaster => rxMaster,
         sAxisSlave  => rxSlave,
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

end mapping;
