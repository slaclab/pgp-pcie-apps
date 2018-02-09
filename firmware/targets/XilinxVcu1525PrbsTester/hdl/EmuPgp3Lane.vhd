-------------------------------------------------------------------------------
-- File       : EmuPgp3Lane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2017-11-16
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
use work.Pgp3Pkg.all;

entity EmuPgp3Lane is
   generic (
      TPD_G            : time             := 1 ns;
      LANE_G           : natural          := 0;
      NUM_VC_G         : positive         := 16;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- Reference Clock and reset
      pgpClk          : in  sl;
      pgpRst          : in  sl;
      -- DMA Interface
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- AXI-Stream Monitor (axilClk domain)
      monReadMaster   : in  AxiLiteReadMasterType;
      monReadSlave    : out AxiLiteReadSlaveType;
      monWriteMaster  : in  AxiLiteWriteMasterType;
      monWriteSlave   : out AxiLiteWriteSlaveType);
end EmuPgp3Lane;

architecture mapping of EmuPgp3Lane is

   constant NUM_AXI_MASTERS_C : natural := NUM_VC_G;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpRxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

begin

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
   GEN_VEC :
   for i in NUM_VC_G-1 downto 0 generate
      U_PRBS : entity work.SsiPrbsTx
         generic map(
            TPD_G                      => TPD_G,
            CASCADE_SIZE_G             => 1,
            FIFO_ADDR_WIDTH_G          => 9,
            FIFO_PAUSE_THRESH_G        => 2**8,
            -- PRBS_SEED_SIZE_G           => 64,
            PRBS_SEED_SIZE_G           => 128,
            PRBS_TAPS_G                => (0 => 31, 1 => 6, 2 => 2, 3 => 1),
            MASTER_AXI_STREAM_CONFIG_G => PGP3_AXIS_CONFIG_C,
            MASTER_AXI_PIPE_STAGES_G   => 1)
         port map(
            -- Master Port (mAxisClk)
            mAxisClk        => pgpClk,
            mAxisRst        => pgpRst,
            mAxisMaster     => pgpRxMasters(i),
            mAxisSlave      => pgpRxSlaves(i),
            -- Trigger Signal (locClk domain)
            locClk          => axilClk,
            locRst          => axilRst,
            trig            => '0',
            packetLength    => x"0000FFFF",
            tDest           => toSlv(i, 8),
            tId             => x"00",
            -- Optional: Axi-Lite Register Interface (locClk domain)
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));
   end generate GEN_VEC;

   -------------
   -- EMU PGP RX
   -------------
   U_PgpRx : entity work.EmuPgpLaneRx
      generic map(
         TPD_G    => TPD_G,
         LANE_G   => LANE_G,
         NUM_VC_G => NUM_VC_G)
      port map(
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaIbMaster  => dmaIbMaster,
         dmaIbSlave   => dmaIbSlave,
         -- PGP Interface (pgpClk domain)
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         pgpRxMasters => pgpRxMasters,
         pgpRxSlaves  => pgpRxSlaves);

   ----------------------------------------
   -- Monitor the final combined DMA stream
   ----------------------------------------
   VC_MON : entity work.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,      -- true if axisClk = statusClk
         AXIS_CLK_FREQ_G  => 156.25E+6,  -- units of Hz
         AXIS_NUM_SLOTS_G => NUM_VC_G,
         AXIS_CONFIG_G    => PGP3_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => pgpClk,
         axisRst          => pgpRst,
         axisMaster       => pgpRxMasters,
         axisSlave        => pgpRxSlaves,
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => monWriteMaster,
         sAxilWriteSlave  => monWriteSlave,
         sAxilReadMaster  => monReadMaster,
         sAxilReadSlave   => monReadSlave);

end mapping;
