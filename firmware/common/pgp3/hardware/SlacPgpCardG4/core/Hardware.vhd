-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Hardware File
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
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp3Pkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Hardware is
   generic (
      TPD_G             : time             := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      RATE_G            : string           := "10.3125Gbps";  -- or "6.25Gbps" or "3.125Gbps"
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
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- Non-VC Interface (pgpClkOut domain)
      pgpClkOut       : out slv(7 downto 0);
      pgpRstOut       : out slv(7 downto 0);
      pgpRxIn         : in  Pgp3RxInArray(7 downto 0) := (others => PGP3_RX_IN_INIT_C);
      pgpRxOut        : out Pgp3RxOutArray(7 downto 0);
      pgpTxIn         : in  Pgp3TxInArray(7 downto 0) := (others => PGP3_TX_IN_INIT_C);
      pgpTxOut        : out Pgp3TxOutArray(7 downto 0);
      ---------------------
      --  Hardware Ports
      ---------------------
      -- QSFP[0] Ports
      qsfpRefClkP     : in  sl;
      qsfpRefClkN     : in  sl;
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRxP : slv(7 downto 0);
   signal pgpRxN : slv(7 downto 0);
   signal pgpTxP : slv(7 downto 0);
   signal pgpTxN : slv(7 downto 0);

   signal qpllLock   : Slv2Array(7 downto 0);
   signal qpllClk    : Slv2Array(7 downto 0);
   signal qpllRefclk : Slv2Array(7 downto 0);
   signal qpllRst    : Slv2Array(7 downto 0);

   signal refClk : sl;

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   U_QsfpRef0 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => qsfpRefClkP,
         IB    => qsfpRefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => refClk);

   GEN_PLLCLK :
   for i in 1 downto 0 generate

      U_QPLL : entity surf.Pgp3GthUsQpll
         generic map (
            TPD_G  => TPD_G,
            RATE_G => RATE_G)
         port map (
            -- Stable Clock and Reset
            stableClk  => axilClk,
            stableRst  => axilRst,
            -- QPLL Clocking
            pgpRefClk  => refClk,
            qpllLock   => qpllLock((4*i)+3 downto (4*i)),
            qpllClk    => qpllClk((4*i)+3 downto (4*i)),
            qpllRefclk => qpllRefclk((4*i)+3 downto (4*i)),
            qpllRst    => qpllRst((4*i)+3 downto (4*i)));

   end generate GEN_PLLCLK;

   --------------------------------
   -- Mapping QSFP[1:0] to PGP[7:0]
   --------------------------------
   MAP_QSFP : for i in 3 downto 0 generate
      -- QSFP[0] to PGP[3:0]
      pgpRxP(i+0) <= qsfp0RxP(i);
      pgpRxN(i+0) <= qsfp0RxN(i);
      qsfp0TxP(i) <= pgpTxP(i+0);
      qsfp0TxN(i) <= pgpTxN(i+0);
      -- QSFP[1] to PGP[7:4]
      pgpRxP(i+4) <= qsfp1RxP(i);
      pgpRxN(i+4) <= qsfp1RxN(i);
      qsfp1TxP(i) <= pgpTxP(i+4);
      qsfp1TxN(i) <= pgpTxN(i+4);
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
            RATE_G            => RATE_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            LANE_G            => i,
            NUM_VC_G          => 4,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- QPLL Interface
            qpllLock        => qpllLock(i),
            qpllClk         => qpllClk(i),
            qpllRefclk      => qpllRefclk(i),
            qpllRst         => qpllRst(i),
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            -- Non-VC Interface (pgpClkOut domain)
            pgpClkOut       => pgpClkOut(i),
            pgpRstOut       => pgpRstOut(i),
            pgpRxIn         => pgpRxIn(i),
            pgpRxOut        => pgpRxOut(i),
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
