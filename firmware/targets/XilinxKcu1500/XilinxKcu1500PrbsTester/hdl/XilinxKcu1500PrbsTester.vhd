-------------------------------------------------------------------------------
-- File       : XilinxKcu1500PrbsTester.vhd
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;
-- use axi_pcie_core.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxKcu1500PrbsTester is
   generic (
      TPD_G      : time     := 1 ns;
      DMA_SIZE_G : positive := 2;
      NUM_VC_G   : positive := 8;       -- Testing all 8 dmaBuffGrpPause paths

      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;

      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(8, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  --- 8 Byte (64-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  --- 16 Byte (128-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(32, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  --- 32 Byte (256-bit) tData interface

      PRBS_SEED_SIZE_G : natural range 32 to 256 := 32;

      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in  slv(1 downto 0);
      qsfp0RefClkN : in  slv(1 downto 0);
      qsfp0RxP     : in  slv(3 downto 0);
      qsfp0RxN     : in  slv(3 downto 0);
      qsfp0TxP     : out slv(3 downto 0);
      qsfp0TxN     : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in  slv(1 downto 0);
      qsfp1RefClkN : in  slv(1 downto 0);
      qsfp1RxP     : in  slv(3 downto 0);
      qsfp1RxN     : in  slv(3 downto 0);
      qsfp1TxP     : out slv(3 downto 0);
      qsfp1TxN     : out slv(3 downto 0);
      -- -- DDR Ports
      -- ddrClkP      : in    slv(3 downto 0);
      -- ddrClkN      : in    slv(3 downto 0);
      -- ddrOut       : out   DdrOutArray(3 downto 0);
      -- ddrInOut     : inout DdrInOutArray(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in  sl;
      userClkP     : in  sl;
      userClkN     : in  sl;
      -- QSFP[0] Ports
      qsfp0RstL    : out sl;
      qsfp0LpMode  : out sl;
      qsfp0ModSelL : out sl;
      qsfp0ModPrsL : in  sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out sl;
      qsfp1LpMode  : out sl;
      qsfp1ModSelL : out sl;
      qsfp1ModPrsL : in  sl;
      -- Boot Memory Ports
      flashCsL     : out sl;
      flashMosi    : out sl;
      flashMiso    : in  sl;
      flashHoldL   : out sl;
      flashWp      : out sl;
      -- PCIe Ports
      pciRstL      : in  sl;
      pciRefClkP   : in  sl;
      pciRefClkN   : in  sl;
      pciRxP       : in  slv(7 downto 0);
      pciRxN       : in  slv(7 downto 0);
      pciTxP       : out slv(7 downto 0);
      pciTxN       : out slv(7 downto 0));
end XilinxKcu1500PrbsTester;

architecture top_level of XilinxKcu1500PrbsTester is

   -- constant START_ADDR_C : slv(MEM_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   -- constant STOP_ADDR_C  : slv(MEM_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(4 downto 0) := (
      0               => (
         baseAddr     => x"0008_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => x"0009_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      2               => (
         baseAddr     => x"000A_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      3               => (
         baseAddr     => x"000B_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      4               => (
         baseAddr     => x"0080_0000",
         addrBits     => 23,
         connectivity => x"FFFF"));

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilReadMasters  : AxiLiteReadMasterArray(4 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(4 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_OK_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(4 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

   signal ddrClk          : slv(3 downto 0);
   signal ddrRst          : slv(3 downto 0);
   signal ddrReady        : slv(3 downto 0);
   signal ddrWriteMasters : AxiWriteMasterArray(3 downto 0);
   signal ddrWriteSlaves  : AxiWriteSlaveArray(3 downto 0);
   signal ddrReadMasters  : AxiReadMasterArray(3 downto 0);
   signal ddrReadSlaves   : AxiReadSlaveArray(3 downto 0);

begin

   U_axilClk : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I   => dmaClk,                 -- 250 MHz
         CE  => '1',
         CLR => '0',
         O   => axilClk);               -- 125 MHz

   U_axilRst : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => axilClk,
         asyncRst => dmaRst,
         syncRst  => axilRst);

   -----------------------
   -- axi-pcie-core module
   -----------------------
   U_Core : entity axi_pcie_core.XilinxKcu1500Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G           => DMA_SIZE_G)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DMA Interfaces
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk          => axilClk,
         appRst          => axilRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk          => emcClk,
         userClkP        => userClkP,
         userClkN        => userClkN,
         -- QSFP[0] Ports
         qsfp0RstL       => qsfp0RstL,
         qsfp0LpMode     => qsfp0LpMode,
         qsfp0ModSelL    => qsfp0ModSelL,
         qsfp0ModPrsL    => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL       => qsfp1RstL,
         qsfp1LpMode     => qsfp1LpMode,
         qsfp1ModSelL    => qsfp1ModSelL,
         qsfp1ModPrsL    => qsfp1ModPrsL,
         -- Boot Memory Ports
         flashCsL        => flashCsL,
         flashMosi       => flashMosi,
         flashMiso       => flashMiso,
         flashHoldL      => flashHoldL,
         flashWp         => flashWp,
         -- PCIe Ports
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   -------------------------
   -- Unused QSFP interfaces
   -------------------------
   U_UnusedQsfp : entity axi_pcie_core.TerminateQsfp
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk      => axilClk,
         axilRst      => axilRst,
         ---------------------
         --  Application Ports
         ---------------------
         -- QSFP[0] Ports
         qsfp0RefClkP => qsfp0RefClkP,
         qsfp0RefClkN => qsfp0RefClkN,
         qsfp0RxP     => qsfp0RxP,
         qsfp0RxN     => qsfp0RxN,
         qsfp0TxP     => qsfp0TxP,
         qsfp0TxN     => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP => qsfp1RefClkP,
         qsfp1RefClkN => qsfp1RefClkN,
         qsfp1RxP     => qsfp1RxP,
         qsfp1RxN     => qsfp1RxN,
         qsfp1TxP     => qsfp1TxP,
         qsfp1TxN     => qsfp1TxN);

   -- --------------------
   -- -- MIG[3:0] IP Cores
   -- --------------------
   -- U_Mig : entity axi_pcie_core.MigAll
   -- generic map (
   -- TPD_G => TPD_G)
   -- port map (
   -- extRst          => dmaRst,
   -- -- AXI MEM Interface
   -- axiClk          => ddrClk,
   -- axiRst          => ddrRst,
   -- axiReady        => ddrReady,
   -- axiWriteMasters => ddrWriteMasters,
   -- axiWriteSlaves  => ddrWriteSlaves,
   -- axiReadMasters  => ddrReadMasters,
   -- axiReadSlaves   => ddrReadSlaves,
   -- -- DDR Ports
   -- ddrClkP         => ddrClkP,
   -- ddrClkN         => ddrClkN,
   -- ddrOut          => ddrOut,
   -- ddrInOut        => ddrInOut);

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 5,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
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

   -- ------------------------
   -- -- Memory Tester Modules
   -- ------------------------
   -- GEN_VEC : for i in 3 downto 0 generate
   -- U_AxiMemTester : entity surf.AxiMemTester
   -- generic map (
   -- TPD_G        => TPD_G,
   -- START_ADDR_G => START_ADDR_C,
   -- STOP_ADDR_G  => STOP_ADDR_C,
   -- AXI_CONFIG_G => MEM_AXI_CONFIG_C)
   -- port map (
   -- -- AXI-Lite Interface
   -- axilClk         => axilClk,
   -- axilRst         => axilRst,
   -- axilReadMaster  => axilReadMasters(i),
   -- axilReadSlave   => axilReadSlaves(i),
   -- axilWriteMaster => axilWriteMasters(i),
   -- axilWriteSlave  => axilWriteSlaves(i),
   -- -- DDR Memory Interface
   -- axiClk          => ddrClk(i),
   -- axiRst          => ddrRst(i),
   -- start           => ddrReady(i),
   -- axiWriteMaster  => ddrWriteMasters(i),
   -- axiWriteSlave   => ddrWriteSlaves(i),
   -- axiReadMaster   => ddrReadMasters(i),
   -- axiReadSlave    => ddrReadSlaves(i));
   -- end generate GEN_VEC;

   ---------------
   -- PRBS Modules
   ---------------
   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_G,
         NUM_VC_G          => NUM_VC_G,
         PRBS_SEED_SIZE_G  => PRBS_SEED_SIZE_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXI_BASE_ADDR_G   => AXIL_XBAR_CONFIG_C(4).baseAddr)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(4),
         axilReadSlave   => axilReadSlaves(4),
         axilWriteMaster => axilWriteMasters(4),
         axilWriteSlave  => axilWriteSlaves(4),
         -- DMA Interface
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves);

end top_level;
