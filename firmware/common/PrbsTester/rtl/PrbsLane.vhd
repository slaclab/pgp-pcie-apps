-------------------------------------------------------------------------------
-- File       : PrbsLane.vhd
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

entity PrbsLane is
   generic (
      TPD_G                        : time                      := 1 ns;
      COMMON_CLOCK_G               : boolean                   := false;
      TX_EN_G                      : boolean                   := true;
      RX_EN_G                      : boolean                   := true;
      NUM_VC_G                     : positive range 1 to 16    := 4;  -- Will overflow axi-lite address space if larger
      PRBS_FIFO_INT_WIDTH_SELECT_G : string                    := "WIDE";
      PRBS_SEED_SIZE_G             : natural range 32 to 512   := 32;
      DMA_AXIS_CONFIG_G            : AxiStreamConfigType;
      DMA_BURST_BYTES_G            : integer range 256 to 4096 := 4096;
      AXI_BASE_ADDR_G              : slv(31 downto 0)          := (others => '0'));
   port (
      -- External Trigger Interface (axilClk domain)
      trig            : in  sl;
      packetLength    : in  slv(31 downto 0);
      busy            : out sl;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
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

   constant ILEAVE_REARB_C    : positive := DMA_BURST_BYTES_G / DMA_AXIS_CONFIG_G.TDATA_BYTES_C;
   constant FIFO_ADDR_WIDTH_C : integer  := bitSize(ILEAVE_REARB_C);

   constant NUM_AXI_MASTERS_C : natural := 2*NUM_VC_G+2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 10);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal dmaIbMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal pipeObMaster : AxiStreamMasterType;
   signal pipeObSlave  : AxiStreamSlaveType;

   signal disableSel : slv(NUM_VC_G-1 downto 0);
   signal busyVec    : slv(NUM_VC_G-1 downto 0);

begin

   -- Help with timing
   process(axilClk)
   begin
      if rising_edge(axilClk) then
         busy <= uOr(busyVec) after TPD_G;
      end if;
   end process;

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

   ---------------
   -- PRBS Modules
   ---------------
   GEN_VC : for i in NUM_VC_G-1 downto 0 generate
      GEN_TX : if (TX_EN_G) generate

         U_SsiPrbsTx : entity surf.SsiPrbsTx
            generic map (
               TPD_G                      => TPD_G,
               GEN_SYNC_FIFO_G            => COMMON_CLOCK_G,
               SYNTH_MODE_G               => "xpm",
               MEMORY_TYPE_G              => "block",
               FIFO_ADDR_WIDTH_G          => FIFO_ADDR_WIDTH_C,
               PRBS_SEED_SIZE_G           => PRBS_SEED_SIZE_G,
               VALID_THOLD_G              => ILEAVE_REARB_C,  -- Hold until enough to burst into the interleaving MUX
               VALID_BURST_MODE_G         => ite(NUM_VC_G = 1, false, true),
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
               trig            => trig,
               packetLength    => packetLength,
               busy            => busyVec(i),
               -- Optional: Axi-Lite Register Interface (locClk domain)
               axilReadMaster  => axilReadMasters(2*i+0),
               axilReadSlave   => axilReadSlaves(2*i+0),
               axilWriteMaster => axilWriteMasters(2*i+0),
               axilWriteSlave  => axilWriteSlaves(2*i+0));

      end generate GEN_TX;

      GEN_RX : if (RX_EN_G) generate
         U_SsiPrbsRx : entity surf.SsiPrbsRx
            generic map (
               TPD_G                     => TPD_G,
               GEN_SYNC_FIFO_G           => COMMON_CLOCK_G,
               FIFO_INT_WIDTH_SELECT_G   => PRBS_FIFO_INT_WIDTH_SELECT_G,
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
      end generate GEN_RX;
   end generate GEN_VC;

   GEN_TX : if (TX_EN_G) generate
      U_AxiStreamMonAxiL_1 : entity surf.AxiStreamMonAxiL
         generic map (
            TPD_G            => TPD_G,
            COMMON_CLK_G     => COMMON_CLOCK_G,
            AXIS_CLK_FREQ_G  => 250.0e6,
            AXIS_NUM_SLOTS_G => NUM_VC_G,
            AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G)
         port map (
            axisClk          => dmaClk,                        -- [in]
            axisRst          => dmaRst,                        -- [in]
            axisMasters      => dmaIbMasters,                  -- [in]
            axisSlaves       => dmaIbSlaves,                   -- [in]
            axilClk          => axilClk,                       -- [in]
            axilRst          => axilRst,                       -- [in]
            sAxilWriteMaster => axilWriteMasters(2*NUM_VC_G),  -- [in]
            sAxilWriteSlave  => axilWriteSlaves(2*NUM_VC_G),   -- [out]
            sAxilReadMaster  => axilReadMasters(2*NUM_VC_G),   -- [in]
            sAxilReadSlave   => axilReadSlaves(2*NUM_VC_G));   -- [out]
   end generate GEN_TX;

   GEN_RX : if (RX_EN_G) generate
      U_AxiStreamMonAxiL_2 : entity surf.AxiStreamMonAxiL
         generic map (
            TPD_G            => TPD_G,
            COMMON_CLK_G     => COMMON_CLOCK_G,
            AXIS_CLK_FREQ_G  => 250.0e6,
            AXIS_NUM_SLOTS_G => NUM_VC_G,
            AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G)
         port map (
            axisClk          => dmaClk,                          -- [in]
            axisRst          => dmaRst,                          -- [in]
            axisMasters      => dmaObMasters,                    -- [in]
            axisSlaves       => dmaObSlaves,                     -- [in]
            axilClk          => axilClk,                         -- [in]
            axilRst          => axilRst,                         -- [in]
            sAxilWriteMaster => axilWriteMasters(2*NUM_VC_G+1),  -- [in]
            sAxilWriteSlave  => axilWriteSlaves(2*NUM_VC_G+1),   -- [out]
            sAxilReadMaster  => axilReadMasters(2*NUM_VC_G+1),   -- [in]
            sAxilReadSlave   => axilReadSlaves(2*NUM_VC_G+1));   -- [out]

   end generate GEN_RX;

   BYP_MUX : if (NUM_VC_G = 1) generate

      dmaObMasters(0) <= dmaObMaster;
      dmaObSlave      <= dmaObSlaves(0);

      dmaIbMaster    <= dmaIbMasters(0);
      dmaIbSlaves(0) <= dmaIbSlave;

   end generate;

   DISABLE_SEL_GEN : for i in NUM_VC_G-1 downto 0 generate
      disableSel(i) <= dmaBuffGrpPause(i mod 8);
   end generate DISABLE_SEL_GEN;


   GEN_MUX : if (NUM_VC_G /= 1) generate

      -- Demux input pipe stage
      U_Pipeline : entity surf.AxiStreamPipeline
         generic map (
            TPD_G         => TPD_G,
            PIPE_STAGES_G => 1)
         port map (
            axisClk     => dmaClk,
            axisRst     => dmaRst,
            sAxisMaster => dmaObMaster,
            sAxisSlave  => dmaObSlave,
            mAxisMaster => pipeObMaster,
            mAxisSlave  => pipeObSlave);

      U_DeMux : entity surf.AxiStreamDeMux
         generic map (
            TPD_G         => TPD_G,
            NUM_MASTERS_G => NUM_VC_G,
            PIPE_STAGES_G => 1)
         port map (
            -- Clock and reset
            axisClk      => dmaClk,
            axisRst      => dmaRst,
            -- Slave
            sAxisMaster  => pipeObMaster,
            sAxisSlave   => pipeObSlave,
            -- Masters
            mAxisMasters => dmaObMasters,
            mAxisSlaves  => dmaObSlaves);

      U_Mux : entity surf.AxiStreamMux
         generic map (
            TPD_G                => TPD_G,
            NUM_SLAVES_G         => NUM_VC_G,
            MODE_G               => "INDEXED",
            TID_MODE_G           => "INDEXED",
            ILEAVE_EN_G          => true,
            ILEAVE_ON_NOTVALID_G => true,
            ILEAVE_REARB_G       => ILEAVE_REARB_C,
            PIPE_STAGES_G        => 1)
         port map (
            -- Clock and reset
            axisClk      => dmaClk,
            axisRst      => dmaRst,
            -- Slaves
            disableSel   => disableSel,  --dmaBuffGrpPause(NUM_VC_G-1 downto 0),
            sAxisMasters => dmaIbMasters,
            sAxisSlaves  => dmaIbSlaves,
            -- Master
            mAxisMaster  => dmaIbMaster,
            mAxisSlave   => dmaIbSlave);

   end generate;

end mapping;
