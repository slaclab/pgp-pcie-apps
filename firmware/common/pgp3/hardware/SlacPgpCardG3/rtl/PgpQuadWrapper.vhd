-------------------------------------------------------------------------------
-- File       : PgpQuadWrapper.vhd
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

entity PgpQuadWrapper is
   generic (
      TPD_G             : time                 := 1 ns;
      NUM_PGP_LANES_G   : integer range 1 to 4 := 4;
      LANE_OFFSET_G     : natural range 0 to 4 := 0;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := (others => '0'));
   port (
      -- PGP GT Serial Ports
      pgpRefClk       : in  sl;
      pgpRxP          : in  slv(3 downto 0);
      pgpRxN          : in  slv(3 downto 0);
      pgpTxP          : out slv(3 downto 0);
      pgpTxN          : out slv(3 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(NUM_PGP_LANES_G-1 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(NUM_PGP_LANES_G-1 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(NUM_PGP_LANES_G-1 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(NUM_PGP_LANES_G-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpQuadWrapper;

architecture mapping of PgpQuadWrapper is

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_PGP_LANES_G-1 downto 0) := genAxiLiteConfig(NUM_PGP_LANES_G, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_PGP_LANES_G-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_PGP_LANES_G-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_PGP_LANES_G-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_PGP_LANES_G-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal qPllOutClk     : Slv2Array(3 downto 0) := (others => "00");
   signal qPllOutRefClk  : Slv2Array(3 downto 0) := (others => "00");
   signal qPllLock       : Slv2Array(3 downto 0) := (others => "00");
   signal qPllRefClkLost : Slv2Array(3 downto 0) := (others => "00");
   signal qpllRst        : Slv2Array(3 downto 0) := (others => "00");

   signal gtTxOutClk     : slv(3 downto 0) := (others => '0');
   signal gtTxPllRst     : slv(3 downto 0) := (others => '0');
   signal gtTxPllLock    : slv(3 downto 0) := (others => '0');
   signal pllOut         : slv(2 downto 0) := (others => '0');
   signal txPllClk       : slv(2 downto 0) := (others => '0');
   signal txPllRst       : slv(2 downto 0) := (others => '0');
   signal lockedStrobe   : slv(3 downto 0) := (others => '0');
   signal pllLock        : sl;
   signal clkFb          : sl;
   signal gtTxOutClkBufg : sl;

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_PGP_LANES_G,
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
   U_QPLL : entity surf.Pgp3Gtp7Qpll  -- Same IP core for both PGPv3 and PGPv4
      generic map (
         TPD_G         => TPD_G,
         EN_DRP_G      => false,
         REFCLK_FREQ_G => 250.0E+6,
         RATE_G        => "6.25Gbps")
      port map (
         -- Stable Clock and Reset
         stableClk      => axilClk,
         stableRst      => axilRst,
         -- QPLL Interface
         pgpRefClk      => pgpRefClk,
         qPllOutClk     => qPllOutClk,
         qPllOutRefClk  => qPllOutRefClk,
         qPllLock       => qPllLock,
         qpllRefClkLost => qpllRefClkLost,
         qpllRst        => qpllRst,
         -- AXI-Lite Interface
         axilClk        => axilClk,
         axilRst        => axilRst);

   --------------
   -- PGP Modules
   --------------
   GEN_LANE :
   for i in NUM_PGP_LANES_G-1 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G             => TPD_G,
            LANE_G            => i+LANE_OFFSET_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            -- QPLL Interface
            qPllOutClk      => qPllOutClk(i),
            qPllOutRefClk   => qPllOutRefClk(i),
            qPllLock        => qPllLock(i),
            qpllRefClkLost  => qpllRefClkLost(i),
            qpllRst         => qpllRst(i),
            -- TX PLL Interface
            gtTxOutClk      => gtTxOutClk(i),
            gtTxPllRst      => gtTxPllRst(i),
            txPllClk        => txPllClk,
            txPllRst        => txPllRst,
            gtTxPllLock     => gtTxPllLock(i),
            -- DMA Interfaces (dmaClk domain)
            dmaClk          => dmaClk,
            dmaRst          => dmaRst,
            dmaBuffGrpPause => dmaBuffGrpPause,
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

      MASTER_LOCK : if (i = 0) generate
         gtTxPllLock(0) <= pllLock;
      end generate;

      SLAVE_LOCK : if (i /= 0) generate
         -- Prevent the gtTxPllRst of this lane disrupting the other lanes in the QUAD
         U_PwrUpRst : entity surf.PwrUpRst
            generic map (
               TPD_G      => TPD_G,
               DURATION_G => 125)
            port map (
               arst   => gtTxPllRst(i),
               clk    => axilClk,
               rstOut => lockedStrobe(i));
         -- Trick the GT state machine of lock transition
         gtTxPllLock(i) <= pllLock and not(lockedStrobe(i));
      end generate;

   end generate GEN_LANE;

   U_Bufg : BUFH
      port map (
         I => gtTxOutClk(0),
         O => gtTxOutClkBufg);

   U_TX_PLL : PLLE2_ADV
      generic map (
         BANDWIDTH      => "HIGH",
         CLKIN1_PERIOD  => 2.56,
         DIVCLK_DIVIDE  => 1,
         CLKFBOUT_MULT  => 4,
         CLKOUT0_DIVIDE => 16,
         CLKOUT1_DIVIDE => 4,
         CLKOUT2_DIVIDE => 8)
      port map (
         DCLK     => axilClk,
         DRDY     => open,
         DEN      => '0',
         DWE      => '0',
         DADDR    => (others => '0'),
         DI       => (others => '0'),
         DO       => open,
         PWRDWN   => '0',
         RST      => gtTxPllRst(0),
         CLKIN1   => gtTxOutClkBufg,
         CLKIN2   => '0',
         CLKINSEL => '1',
         CLKFBOUT => clkFb,
         CLKFBIN  => clkFb,
         LOCKED   => pllLock,
         CLKOUT0  => pllOut(0),
         CLKOUT1  => pllOut(1),
         CLKOUT2  => pllOut(2));

   U_txPllClk0 : BUFG
      port map (
         I => pllOut(0),
         O => txPllClk(0));

   U_txPllClk1 : BUFG
      port map (
         I => pllOut(1),
         O => txPllClk(1));

   U_txPllClk2 : BUFG
      port map (
         I => pllOut(2),
         O => txPllClk(2));

   GEN_RST : for i in 2 downto 0 generate
      U_RstSync : entity surf.RstSync
         generic map (
            TPD_G          => TPD_G,
            IN_POLARITY_G  => '0',
            OUT_POLARITY_G => '1')
         port map (
            clk      => txPllClk(i),
            asyncRst => pllLock,
            syncRst  => txPllRst(i));
   end generate;

   GEN_DUMMY : if (NUM_PGP_LANES_G < 4) generate
      U_TermGtp : entity surf.Gtpe2ChannelDummy
         generic map (
            TPD_G      => TPD_G,
            EXT_QPLL_G => true,
            WIDTH_G    => 4-NUM_PGP_LANES_G)
         port map (
            refClk           => axilClk,
            qPllOutClkExt    => qPllOutClk(NUM_PGP_LANES_G-1),
            qPllOutRefClkExt => qPllOutRefClk(NUM_PGP_LANES_G-1),
            gtRxP            => pgpRxP(3 downto NUM_PGP_LANES_G),
            gtRxN            => pgpRxN(3 downto NUM_PGP_LANES_G),
            gtTxP            => pgpTxP(3 downto NUM_PGP_LANES_G),
            gtTxN            => pgpTxN(3 downto NUM_PGP_LANES_G));
   end generate GEN_DUMMY;

end mapping;
