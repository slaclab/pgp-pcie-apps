-------------------------------------------------------------------------------
-- File       : SlacPgpCardG4PrbsTester.vhd
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

library unisim;
use unisim.vcomponents.all;

entity SlacPgpCardG4PrbsTester is
   generic (
      TPD_G      : time     := 1 ns;
      DMA_SIZE_G : positive := 1;
      NUM_VC_G   : positive := 1;

      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;

      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);  --- 8 Byte (64-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  --- 16 Byte (128-bit) tData interface
      -- DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  --- 32 Byte (256-bit) tData interface

      PRBS_SEED_SIZE_G : natural range 32 to 256 := 256;

      BUILD_INFO_G : BuildInfoType);
   port (
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk      : in    sl;
      pwrScl      : inout sl;
      pwrSda      : inout sl;
      sfpScl      : inout sl;
      sfpSda      : inout sl;
      qsfpScl     : inout slv(1 downto 0);
      qsfpSda     : inout slv(1 downto 0);
      qsfpRstL    : out   slv(1 downto 0);
      qsfpLpMode  : out   slv(1 downto 0);
      qsfpModSelL : out   slv(1 downto 0);
      qsfpModPrsL : in    slv(1 downto 0);
      -- Boot Memory Ports
      flashCsL    : out   sl;
      flashMosi   : out   sl;
      flashMiso   : in    sl;
      flashHoldL  : out   sl;
      flashWp     : out   sl;
      -- PCIe Ports
      pciRstL     : in    sl;
      pciRefClkP  : in    sl;
      pciRefClkN  : in    sl;
      pciRxP      : in    slv(7 downto 0);
      pciRxN      : in    slv(7 downto 0);
      pciTxP      : out   slv(7 downto 0);
      pciTxN      : out   slv(7 downto 0));
end SlacPgpCardG4PrbsTester;

architecture top_level of SlacPgpCardG4PrbsTester is

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(4 downto 0) := (
      0               => (
         baseAddr     => x"0010_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => x"0011_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      2               => (
         baseAddr     => x"0012_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      3               => (
         baseAddr     => x"0013_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      4               => (
         baseAddr     => x"0080_0000",
         addrBits     => 23,
         connectivity => x"FFFF"));

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilReadMasters  : AxiLiteReadMasterArray(4 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(4 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(4 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

begin

   -----------------------
   -- axi-pcie-core module
   -----------------------
   U_Core : entity axi_pcie_core.SlacPgpCardG4Core
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
         appClk          => dmaClk,
         appRst          => dmaRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk          => emcClk,
         pwrScl          => pwrScl,
         pwrSda          => pwrSda,
         sfpScl          => sfpScl,
         sfpSda          => sfpSda,
         qsfpScl         => qsfpScl,
         qsfpSda         => qsfpSda,
         qsfpRstL        => qsfpRstL,
         qsfpLpMode      => qsfpLpMode,
         qsfpModSelL     => qsfpModSelL,
         qsfpModPrsL     => qsfpModPrsL,
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
         axiClk              => dmaClk,
         axiClkRst           => dmaRst,
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
