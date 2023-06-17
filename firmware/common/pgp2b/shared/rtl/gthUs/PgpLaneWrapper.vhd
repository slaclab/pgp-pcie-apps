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
use surf.Pgp2bPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G             : time             := 1 ns;
      REFCLK_WIDTH_G    : positive         := 2;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0) := (others => '0'));
   port (
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp0RefClkN    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp1RefClkN    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- Non-VC Interface (pgpClkOut domain)
      pgpRxClkOut     : out slv(7 downto 0);
      pgpRxRstOut     : out slv(7 downto 0);
      pgpRxIn         : in  Pgp2bRxInArray(7 downto 0) := (others => PGP2B_RX_IN_INIT_C);
      pgpRxOut        : out Pgp2bRxOutArray(7 downto 0);
      pgpTxClkOut     : out slv(7 downto 0);
      pgpTxRstOut     : out slv(7 downto 0);
      pgpTxIn         : in  Pgp2bTxInArray(7 downto 0) := (others => PGP2B_TX_IN_INIT_C);
      pgpTxOut        : out Pgp2bTxOutArray(7 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRefClk : slv(7 downto 0);
   signal pgpRxP    : slv(7 downto 0);
   signal pgpRxN    : slv(7 downto 0);
   signal pgpTxP    : slv(7 downto 0);
   signal pgpTxN    : slv(7 downto 0);

   signal drpClk   : sl;
   signal drpReset : sl;
   signal drpRst   : sl;

   signal refClk : slv((2*REFCLK_WIDTH_G)-1 downto 0);

   attribute dont_touch           : string;
   attribute dont_touch of refClk : signal is "TRUE";

begin

   U_DRP_CLK : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 8)
      port map (
         I   => dmaClk,
         CE  => '1',
         CLR => '0',
         O   => drpClk);

   U_RstSync : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => drpClk,
         asyncRst => dmaRst,
         syncRst  => drpReset);

   U_RstPipe : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => drpClk,
         rstIn  => drpReset,
         rstOut => drpRst);

   ------------------------
   -- Common PGP Clocking
   ------------------------
   GEN_REFCLK :
   for i in REFCLK_WIDTH_G-1 downto 0 generate

      U_QsfpRef0 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp0RefClkP(i),
            IB    => qsfp0RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+0));

      U_QsfpRef1 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp1RefClkP(i),
            IB    => qsfp1RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+1));
   end generate GEN_REFCLK;

   --------------------------------
   -- Mapping QSFP[1:0] to PGP[7:0]
   --------------------------------
   MAP_QSFP : for i in 3 downto 0 generate
      -- QSFP[0] to PGP[3:0]
      pgpRefClk(i+0) <= refClk(0);
      pgpRxP(i+0)    <= qsfp0RxP(i);
      pgpRxN(i+0)    <= qsfp0RxN(i);
      qsfp0TxP(i)    <= pgpTxP(i+0);
      qsfp0TxN(i)    <= pgpTxN(i+0);
      -- QSFP[1] to PGP[7:4]
      pgpRefClk(i+4) <= refClk(1);
      pgpRxP(i+4)    <= qsfp1RxP(i);
      pgpRxN(i+4)    <= qsfp1RxN(i);
      qsfp1TxP(i)    <= pgpTxP(i+4);
      qsfp1TxN(i)    <= pgpTxN(i+4);
   end generate MAP_QSFP;

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

   ------------
   -- PGP Lanes
   ------------
   GEN_LANE : for i in 7 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G             => TPD_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            LANE_G            => i,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- DRP Clock and Reset
            drpClk          => drpClk,
            drpRst          => drpRst,
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            pgpRefClk       => pgpRefClk(i),
            -- Non-VC Interface (pgpClkOut domain)
            pgpRxClkOut     => pgpRxClkOut(i),
            pgpRxRstOut     => pgpRxRstOut(i),
            pgpRxIn         => pgpRxIn(i),
            pgpRxOut        => pgpRxOut(i),
            pgpTxClkOut     => pgpTxClkOut(i),
            pgpTxRstOut     => pgpTxRstOut(i),
            pgpTxIn         => pgpTxIn(i),
            pgpTxOut        => pgpTxOut(i),
            -- DMA Interface (dmaClk domain)
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

   end generate GEN_LANE;

end mapping;
