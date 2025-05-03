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
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.HtspPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Hardware is
   generic (
      TPD_G                 : time             := 1 ns;
      AXIL_BASE_ADDR_G      : slv(31 downto 0) := x"0080_0000";
      AXIL_CLK_FREQ_G       : real             := 156.25E+6;
      NUM_VC_G              : positive         := 4;
      TX_MAX_PAYLOAD_SIZE_G : positive         := 8192);
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
      dmaObMasters    : in  AxiStreamMasterArray(1 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(1 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(1 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(1 downto 0);
      -- Non-VC Interface (htspClkOut domain)
      htspClkOut      : out slv(1 downto 0);
      htspTxIn        : in  HtspTxInArray(1 downto 0);
      ---------------------
      --  Hardware Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(1 downto 0);
      qsfp0RefClkN    : in  slv(1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  slv(1 downto 0);
      qsfp1RefClkN    : in  slv(1 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   constant NUM_AXIL_MASTERS_C : natural := 2;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 18, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal axilReset : sl;
   signal dmaReset  : sl;

   signal dummy : slv(1 downto 0);

   attribute dont_touch          : string;
   attribute dont_touch of dummy : signal is "TRUE";

begin

   U_axilRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => axilRst,
         rstOut => axilReset);

   U_dmaRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => dmaClk,
         rstIn  => dmaRst,
         rstOut => dmaReset);

   U_UnusedRef_0 : IBUFDS_GTE4
      port map (
         I   => qsfp0RefClkP(1),
         IB  => qsfp0RefClkN(1),
         CEB => '0',
         O   => dummy(0));

   U_UnusedRef_1 : IBUFDS_GTE4
      port map (
         I   => qsfp1RefClkP(1),
         IB  => qsfp1RefClkN(1),
         CEB => '0',
         O   => dummy(1));

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilReset,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ------------------
   -- QSFP[0] Modules
   ------------------
   U_QSFP0 : entity work.HtspWrapper
      generic map (
         TPD_G                 => TPD_G,
         AXIL_BASE_ADDR_G      => AXIL_CONFIG_C(0).baseAddr,
         AXIL_CLK_FREQ_G       => AXIL_CLK_FREQ_G,
         NUM_VC_G              => NUM_VC_G,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_G)
      port map (
         -- QSFP Ports
         qsfpRefClkP     => qsfp0RefClkP(0),
         qsfpRefClkN     => qsfp0RefClkN(0),
         qsfpRxP         => qsfp0RxP,
         qsfpRxN         => qsfp0RxN,
         qsfpTxP         => qsfp0TxP,
         qsfpTxN         => qsfp0TxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaReset,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMaster     => dmaObMasters(0),
         dmaObSlave      => dmaObSlaves(0),
         dmaIbMaster     => dmaIbMasters(0),
         dmaIbSlave      => dmaIbSlaves(0),
         -- Non-VC Interface (htspClkOut domain)
         htspClkOut      => htspClkOut(0),
         htspTxIn        => htspTxIn(0),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilReset,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   ------------------
   -- QSFP[1] Modules
   ------------------
   U_QSFP1 : entity work.HtspWrapper
      generic map (
         TPD_G                 => TPD_G,
         AXIL_BASE_ADDR_G      => AXIL_CONFIG_C(1).baseAddr,
         AXIL_CLK_FREQ_G       => AXIL_CLK_FREQ_G,
         NUM_VC_G              => NUM_VC_G,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_G)
      port map (
         -- QSFP Ports
         qsfpRefClkP     => qsfp1RefClkP(0),
         qsfpRefClkN     => qsfp1RefClkN(0),
         qsfpRxP         => qsfp1RxP,
         qsfpRxN         => qsfp1RxN,
         qsfpTxP         => qsfp1TxP,
         qsfpTxN         => qsfp1TxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaReset,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMaster     => dmaObMasters(1),
         dmaObSlave      => dmaObSlaves(1),
         dmaIbMaster     => dmaIbMasters(1),
         dmaIbSlave      => dmaIbSlaves(1),
         -- Non-VC Interface (htspClkOut domain)
         htspClkOut      => htspClkOut(1),
         htspTxIn        => htspTxIn(1),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilReset,
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1));

end mapping;
