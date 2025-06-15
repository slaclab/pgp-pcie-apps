-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simple DMA loopback Example
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

entity XilinxAlveoV80DmaLoopback is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- -- QSFP[0] Ports
      -- qsfp0RefClkP : in  slv(1 downto 0);
      -- qsfp0RefClkN : in  slv(1 downto 0);
      -- qsfp0RxP     : in  slv(3 downto 0);
      -- qsfp0RxN     : in  slv(3 downto 0);
      -- qsfp0TxP     : out slv(3 downto 0);
      -- qsfp0TxN     : out slv(3 downto 0);
      -- -- QSFP[1] Ports
      -- qsfp1RefClkP : in  slv(1 downto 0);
      -- qsfp1RefClkN : in  slv(1 downto 0);
      -- qsfp1RxP     : in  slv(3 downto 0);
      -- qsfp1RxN     : in  slv(3 downto 0);
      -- qsfp1TxP     : out slv(3 downto 0);
      -- qsfp1TxN     : out slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- PS DDR Ports
      psDdrDq     : inout slv(71 downto 0);
      psDdrDqsT   : inout slv(8 downto 0);
      psDdrDqsC   : inout slv(8 downto 0);
      psDdrAdr    : out   slv(16 downto 0);
      psDdrBa     : out   slv(1 downto 0);
      psDdrBg     : out   slv(0 to 0);
      psDdrActN   : out   slv(0 to 0);
      psDdrResetN : out   slv(0 to 0);
      psDdrCkT    : out   slv(0 to 0);
      psDdrCkC    : out   slv(0 to 0);
      psDdrCke    : out   slv(0 to 0);
      psDdrCsN    : out   slv(0 to 0);
      psDdrDmN    : inout slv(8 downto 0);
      psDdrOdt    : out   slv(0 to 0);
      psDdrClkP   : in    slv(0 to 0);
      psDdrClkN   : in    slv(0 to 0);
      -- PCIe Ports
      pciRefClkP  : in    sl;
      pciRefClkN  : in    sl;
      pciRxP      : in    slv(7 downto 0);
      pciRxN      : in    slv(7 downto 0);
      pciTxP      : out   slv(7 downto 0);
      pciTxN      : out   slv(7 downto 0));
end XilinxAlveoV80DmaLoopback;

architecture top_level of XilinxAlveoV80DmaLoopback is

   constant DMA_SIZE_C : positive := 1;

   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);   -- 8  Byte (64-bit)  tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 8, tIdBits => 3);  -- 16 Byte (128-bit) tData interface
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 8, tIdBits => 3);  -- 32 Byte (256-bit) tData interface
   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 64, tDestBits => 8, tIdBits => 3);  -- 64 Byte (512-bit) tData interface

   signal dmaClk     : sl;
   signal dmaRst     : sl;
   signal dmaMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_OK_C;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

begin

   U_Core : entity axi_pcie_core.XilinxAlveoV80Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DMA Interfaces
         dmaClk         => dmaClk,
         dmaRst         => dmaRst,
         dmaObMasters   => dmaMasters,
         dmaObSlaves    => dmaSlaves,
         dmaIbMasters   => dmaMasters,
         dmaIbSlaves    => dmaSlaves,
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk         => dmaClk,
         appRst         => dmaRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- PS DDR Ports
         psDdrDq        => psDdrDq,
         psDdrDqsT      => psDdrDqsT,
         psDdrDqsC      => psDdrDqsC,
         psDdrAdr       => psDdrAdr,
         psDdrBa        => psDdrBa,
         psDdrBg        => psDdrBg,
         psDdrActN      => psDdrActN,
         psDdrResetN    => psDdrResetN,
         psDdrCkT       => psDdrCkT,
         psDdrCkC       => psDdrCkC,
         psDdrCke       => psDdrCke,
         psDdrCsN       => psDdrCsN,
         psDdrDmN       => psDdrDmN,
         psDdrOdt       => psDdrOdt,
         psDdrClkP      => psDdrClkP,
         psDdrClkN      => psDdrClkN,
         -- PCIe Ports
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

   -- U_UnusedQsfp : entity axi_pcie_core.TerminateQsfp
   -- generic map (
   -- TPD_G => TPD_G)
   -- port map (
   -- -- AXI-Lite Interface
   -- axilClk         => axilClk,
   -- axilRst         => axilRst,
   -- axilReadMaster  => axilReadMaster,
   -- axilReadSlave   => axilReadSlave,
   -- axilWriteMaster => axilWriteMaster,
   -- axilWriteSlave  => axilWriteSlave,
   -- ---------------------
   -- --  Application Ports
   -- ---------------------
   -- -- QSFP[0] Ports
   -- qsfp0RefClkP    => qsfp0RefClkP,
   -- qsfp0RefClkN    => qsfp0RefClkN,
   -- qsfp0RxP        => qsfp0RxP,
   -- qsfp0RxN        => qsfp0RxN,
   -- qsfp0TxP        => qsfp0TxP,
   -- qsfp0TxN        => qsfp0TxN,
   -- -- QSFP[1] Ports
   -- qsfp1RefClkP    => qsfp1RefClkP,
   -- qsfp1RefClkN    => qsfp1RefClkN,
   -- qsfp1RxP        => qsfp1RxP,
   -- qsfp1RxN        => qsfp1RxN,
   -- qsfp1TxP        => qsfp1TxP,
   -- qsfp1TxN        => qsfp1TxN);

end top_level;
