-------------------------------------------------------------------------------
-- File       : PgpLaneWrapper.vhd
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

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G             : time             := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0) := (others => '0'));
   port (
      -- PGP GT Serial Ports
      pgpRefClkP      : in  sl;
      pgpRefClkN      : in  sl;
      pgpRxP          : in  slv(7 downto 0);
      pgpRxN          : in  slv(7 downto 0);
      pgpTxP          : out slv(7 downto 0);
      pgpTxN          : out slv(7 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant WEST_C : natural := 0;
   constant EAST_C : natural := 4;

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRefClk      : sl;
   signal qPllRefClk     : Slv2Array(1 downto 0);
   signal qPllClk        : Slv2Array(1 downto 0);
   signal qPllLock       : Slv2Array(1 downto 0);
   signal qPllRefClkLost : Slv2Array(1 downto 0);
   signal gtQPllReset    : Slv2Array(7 downto 0);

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

   ------------------------
   -- Common CLink Clocking
   ------------------------
   U_IBUFDS : IBUFDS_GTE2
      port map (
         I     => pgpRefClkP,
         IB    => pgpRefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => pgpRefClk);

   U_QPLL_WEST : entity work.PgpQpll
      generic map (
         TPD_G => TPD_G)
      port map (
         pgpRefClk      => pgpRefClk,
         qPllRefClk     => qPllRefClk(0),
         qPllClk        => qPllClk(0),
         qPllLock       => qPllLock(0),
         qPllRefClkLost => qPllRefClkLost(0),
         gtQPllReset    => gtQPllReset(3 downto 0),
         sysClk         => axilClk,
         sysRst         => axilRst);

   U_QPLL_EAST : entity work.PgpQpll
      generic map (
         TPD_G => TPD_G)
      port map (
         pgpRefClk      => pgpRefClk,
         qPllRefClk     => qPllRefClk(1),
         qPllClk        => qPllClk(1),
         qPllLock       => qPllLock(1),
         qPllRefClkLost => qPllRefClkLost(1),
         gtQPllReset    => gtQPllReset(7 downto 4),
         sysClk         => axilClk,
         sysRst         => axilRst);

   ------------
   -- PGP Lanes
   ------------
   GEN_VEC :
   for i in 3 downto 0 generate

      U_West : entity work.PgpLane
         generic map (
            TPD_G             => TPD_G,
            LANE_G            => (i+WEST_C),
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i+WEST_C).baseAddr)
         port map (
            -- QPLL Clocking
            gtQPllOutRefClk  => qPllRefClk(0),
            gtQPllOutClk     => qPllClk(0),
            gtQPllLock       => qPllLock(0),
            gtQPllRefClkLost => qPllRefClkLost(0),
            gtQPllReset      => gtQPllReset(i+WEST_C),
            -- PGP Serial Ports
            pgpRxP           => pgpRxP(i+WEST_C),
            pgpRxN           => pgpRxN(i+WEST_C),
            pgpTxP           => pgpTxP(i+WEST_C),
            pgpTxN           => pgpTxN(i+WEST_C),
            -- DMA Interfaces (dmaClk domain)
            dmaClk           => dmaClk,
            dmaRst           => dmaRst,
            dmaBuffGrpPause  => dmaBuffGrpPause,
            dmaObMaster      => dmaObMasters(i+WEST_C),
            dmaObSlave       => dmaObSlaves(i+WEST_C),
            dmaIbMaster      => dmaIbMasters(i+WEST_C),
            dmaIbSlave       => dmaIbSlaves(i+WEST_C),
            -- AXI-Lite Interface (axilClk domain)
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => axilReadMasters(i+WEST_C),
            axilReadSlave    => axilReadSlaves(i+WEST_C),
            axilWriteMaster  => axilWriteMasters(i+WEST_C),
            axilWriteSlave   => axilWriteSlaves(i+WEST_C));

      U_East : entity work.PgpLane
         generic map (
            TPD_G             => TPD_G,
            LANE_G            => (i+EAST_C),
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i+EAST_C).baseAddr)
         port map (
            -- QPLL Clocking
            gtQPllOutRefClk  => qPllRefClk(1),
            gtQPllOutClk     => qPllClk(1),
            gtQPllLock       => qPllLock(1),
            gtQPllRefClkLost => qPllRefClkLost(1),
            gtQPllReset      => gtQPllReset(i+EAST_C),
            -- PGP Serial Ports
            pgpRxP           => pgpRxP(i+EAST_C),
            pgpRxN           => pgpRxN(i+EAST_C),
            pgpTxP           => pgpTxP(i+EAST_C),
            pgpTxN           => pgpTxN(i+EAST_C),
            -- DMA Interfaces (dmaClk domain)
            dmaClk           => dmaClk,
            dmaRst           => dmaRst,
            dmaBuffGrpPause  => dmaBuffGrpPause,
            dmaObMaster      => dmaObMasters(i+EAST_C),
            dmaObSlave       => dmaObSlaves(i+EAST_C),
            dmaIbMaster      => dmaIbMasters(i+EAST_C),
            dmaIbSlave       => dmaIbSlaves(i+EAST_C),
            -- AXI-Lite Interface (axilClk domain)
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => axilReadMasters(i+EAST_C),
            axilReadSlave    => axilReadSlaves(i+EAST_C),
            axilWriteMaster  => axilWriteMasters(i+EAST_C),
            axilWriteSlave   => axilWriteSlaves(i+EAST_C));

   end generate GEN_VEC;

end mapping;
