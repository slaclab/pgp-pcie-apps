-------------------------------------------------------------------------------
-- File       : PrbsLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-02-09
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
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
      TPD_G            : time             := 1 ns;
      LANE_G           : natural          := 0;
      NUM_VC_G         : positive         := 4;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
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

   constant NUM_AXI_MASTERS_C : natural := NUM_VC_G;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal dmaIbMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal txMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal txSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal rxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal dmaReset  : slv(NUM_VC_G-1 downto 0);
   signal axilRseet : slv(NUM_VC_G-1 downto 0);

begin

   dmaObSlave <= AXI_STREAM_SLAVE_FORCE_C;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
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
   GEN_TX :
   for i in NUM_VC_G-1 downto 0 generate

      U_SsiPrbsTx : entity work.SsiPrbsTx
         generic map (
            TPD_G                      => TPD_G,
            MASTER_AXI_PIPE_STAGES_G   => 1,
            MASTER_AXI_STREAM_CONFIG_G => ssiAxiStreamConfig(4))
         port map (
            -- Master Port (mAxisClk)
            mAxisClk        => dmaClk,
            mAxisRst        => dmaReset(i),
            mAxisMaster     => txMasters(i),
            mAxisSlave      => txSlaves(i),
            -- Trigger Signal (locClk domain)
            locClk          => axilClk,
            locRst          => axilRseet(i),
            trig            => '0',
            packetLength    => x"00000FFF",
            tDest           => x"00",
            tId             => x"00",
            -- Optional: Axi-Lite Register Interface (locClk domain)
            axilReadMaster  => axilReadMasters(i+0),
            axilReadSlave   => axilReadSlaves(i+0),
            axilWriteMaster => axilWriteMasters(i+0),
            axilWriteSlave  => axilWriteSlaves(i+0));

      TX_FIFO : entity work.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
            VALID_BURST_MODE_G  => true,
            -- FIFO configurations
            BRAM_EN_G           => true,
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 10,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 512,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(4),
            MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => dmaClk,
            sAxisRst    => dmaReset(i),
            sAxisMaster => txMasters(i),
            sAxisSlave  => txSlaves(i),
            -- Master Port
            mAxisClk    => dmaClk,
            mAxisRst    => dmaReset(i),
            mAxisMaster => dmaIbMasters(i),
            mAxisSlave  => dmaIbSlaves(i));


      U_dmaRst : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => dmaClk,
            rstIn  => dmaRst,
            rstOut => dmaReset(i));

      U_axilRst : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => axilClk,
            rstIn  => axilRst,
            rstOut => axilRseet(i));

   end generate GEN_TX;

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
