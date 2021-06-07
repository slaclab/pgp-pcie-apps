-------------------------------------------------------------------------------
-- File       : Hardware.vhd
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

library unisim;
use unisim.vcomponents.all;

entity Hardware is
   generic (
      TPD_G             : time             := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0) := x"0080_0000");
   port (
      ------------------------
      --  Top Level Interfaces
      ------------------------
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(3 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(3 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(3 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(3 downto 0);
      -- PGP GT Serial Ports
      pgpRefClkP      : in  sl;
      pgpRefClkN      : in  sl;
      pgpRxP          : in  slv(3 downto 0);
      pgpRxN          : in  slv(3 downto 0);
      pgpTxP          : out slv(3 downto 0);
      pgpTxN          : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   constant NUM_AXIL_MASTERS_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 20, 18);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal pgpRefClk : sl;

begin

   ------------------------
   -- GT Clocking
   ------------------------
   U_IBUFDS : IBUFDS_GTE2
      port map (
         I     => pgpRefClkP,
         IB    => pgpRefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => pgpRefClk);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
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

   --------------
   -- PGP Modules
   --------------
   U_PgpQuadA : entity work.PgpQuadWrapper
      generic map (
         TPD_G             => TPD_G,
         LANE_OFFSET_G     => 0,
         NUM_PGP_LANES_G   => 4,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXI_BASE_ADDR_G   => AXI_BASE_ADDR_G)
      port map (
         -- PGP GT Serial Ports
         pgpRefClk       => pgpRefClk,
         pgpRxP          => pgpRxP,
         pgpRxN          => pgpRxN,
         pgpTxP          => pgpTxP,
         pgpTxN          => pgpTxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

end mapping;
