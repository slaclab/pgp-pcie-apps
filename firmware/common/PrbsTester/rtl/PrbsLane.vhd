-------------------------------------------------------------------------------
-- File       : PrbsLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-10-15
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.AxiPciePkg.all;
use work.SsiPkg.all;

entity PrbsLane is
   generic (
      TPD_G             : time                    := 1 ns;
      LANE_G            : natural                 := 0;
      NUM_VC_G          : positive                := 4;
      PRBS_SEED_SIZE_G  : natural range 32 to 256 := 32;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0)        := (others => '0'));
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PrbsLane;

architecture mapping of PrbsLane is

   function TdestRoutes return Slv8Array is
      variable retConf : Slv8Array(NUM_VC_G-1 downto 0);
   begin
      for i in NUM_VC_G-1 downto 0 loop
         retConf(i) := toSlv((32*LANE_G)+i, 8);
      end loop;
      return retConf;
   end function;

   constant NUM_AXI_MASTERS_C : natural := 2*NUM_VC_G;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal dmaIbMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
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

   ---------------
   -- PRBS Modules
   ---------------
   GEN_VC :
   for i in NUM_VC_G-1 downto 0 generate

      U_SsiPrbsTx : entity work.SsiPrbsTx
         generic map (
            TPD_G                      => TPD_G,
            PRBS_SEED_SIZE_G           => PRBS_SEED_SIZE_G,
            VALID_THOLD_G              => 256,  -- Hold until enough to burst into the interleaving MUX
            VALID_BURST_MODE_G         => true,
            MASTER_AXI_PIPE_STAGES_G   => 1,
            MASTER_AXI_STREAM_CONFIG_G => DMA_AXIS_CONFIG_G)
         port map (
            -- Master Port (mAxisClk)
            mAxisClk        => dmaClk,
            mAxisRst        => dmaRst,
            mAxisMaster     => dmaIbMasters(i),
            mAxisSlave      => dmaIbSlaves(i),
            -- Trigger Signal (locClk domain)
            locClk          => axilClk,
            locRst          => axilRst,
            -- Optional: Axi-Lite Register Interface (locClk domain)
            axilReadMaster  => axilReadMasters(2*i+0),
            axilReadSlave   => axilReadSlaves(2*i+0),
            axilWriteMaster => axilWriteMasters(2*i+0),
            axilWriteSlave  => axilWriteSlaves(2*i+0));

      U_SsiPrbsRx : entity work.SsiPrbsRx
         generic map (
            TPD_G                     => TPD_G,
            PRBS_SEED_SIZE_G          => PRBS_SEED_SIZE_G,
            SLAVE_AXI_PIPE_STAGES_G   => 1,
            SLAVE_AXI_STREAM_CONFIG_G => DMA_AXIS_CONFIG_G)
         port map (
            sAxisClk       => dmaClk,
            sAxisRst       => dmaRst,
            sAxisMaster    => dmaObMasters(i),
            sAxisSlave     => dmaObSlaves(i),
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(2*i+1),
            axiReadSlave   => axilReadSlaves(2*i+1),
            axiWriteMaster => axilWriteMasters(2*i+1),
            axiWriteSlave  => axilWriteSlaves(2*i+1));

   end generate GEN_VC;

   U_DeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G          => TPD_G,
         NUM_MASTERS_G  => NUM_VC_G,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => TdestRoutes,
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk      => dmaClk,
         axisRst      => dmaRst,
         -- Slave
         sAxisMaster  => dmaObMaster,
         sAxisSlave   => dmaObSlave,
         -- Masters
         mAxisMasters => dmaObMasters,
         mAxisSlaves  => dmaObSlaves);

   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_VC_G,
         MODE_G               => "ROUTED",
         TDEST_ROUTES_G       => TdestRoutes,
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => dmaClk,
         axisRst      => dmaRst,
         -- Slaves
         sAxisMasters => dmaIbMasters,
         sAxisSlaves  => dmaIbSlaves,
         -- Master
         mAxisMaster  => dmaIbMaster,
         mAxisSlave   => dmaIbSlave);

end mapping;
