-------------------------------------------------------------------------------
-- File       : XilinxAlveoU280DmaLoopback.vhd
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

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxAlveoU280DmaLoopback is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP   : in  slv(1 downto 0);
      qsfp0RefClkN   : in  slv(1 downto 0);
      qsfp0RxP       : in  slv(3 downto 0);
      qsfp0RxN       : in  slv(3 downto 0);
      qsfp0TxP       : out slv(3 downto 0);
      qsfp0TxN       : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP   : in  slv(1 downto 0);
      qsfp1RefClkN   : in  slv(1 downto 0);
      qsfp1RxP       : in  slv(3 downto 0);
      qsfp1RxN       : in  slv(3 downto 0);
      qsfp1TxP       : out slv(3 downto 0);
      qsfp1TxN       : out slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      userClkP       : in  sl;
      userClkN       : in  sl;
      -- QSFP[1:0] Ports
      qsfpRstL      : out slv(1 downto 0);
      qsfpLpMode    : out slv(1 downto 0);
      qsfpModSelL   : out slv(1 downto 0);
      qsfpModPrsL   : in  slv(1 downto 0);
      -- PCIe Ports
      pciRstL        : in  sl;
      pciRefClkP     : in  slv(1 downto 0);
      pciRefClkN     : in  slv(1 downto 0);
      pciRxP         : in  slv(15 downto 0);
      pciRxN         : in  slv(15 downto 0);
      pciTxP         : out slv(15 downto 0);
      pciTxN         : out slv(15 downto 0));
end XilinxAlveoU280DmaLoopback;

architecture top_level of XilinxAlveoU280DmaLoopback is

   constant DMA_SIZE_C : positive := 1;

   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8);  -- 8  Byte (64-bit)  tData interface      
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(16);  -- 16 Byte (128-bit) tData interface      
   -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(32);  -- 32 Byte (256-bit) tData interface      
   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(64);  -- 64 Byte (512-bit) tData interface      

   signal dmaClk     : sl;
   signal dmaRst     : sl;
   signal dmaMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal userClk156      : sl;
   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

begin

   U_axilClk : entity work.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => true,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 6.4,      -- 156.25 MHz
         CLKFBOUT_MULT_G   => 8,        -- 1.25GHz = 8 x 156.25 MHz
         CLKOUT0_DIVIDE_G  => 8)        -- 156.25MHz = 1.25GHz/8
      port map(
         -- Clock Input
         clkIn     => userClk156,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   U_Core : entity work.XilinxAlveoU280Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------          
         userClk156     => userClk156,
         -- DMA Interfaces
         dmaClk         => dmaClk,
         dmaRst         => dmaRst,
         dmaObMasters   => dmaMasters,
         dmaObSlaves    => dmaSlaves,
         dmaIbMasters   => dmaMasters,
         dmaIbSlaves    => dmaSlaves,
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
         --------------
         --  Core Ports
         --------------   
         -- System Ports
         userClkP       => userClkP,
         userClkN       => userClkN,
         -- QSFP[1:0] Ports
         qsfpRstL      => qsfpRstL,
         qsfpLpMode    => qsfpLpMode,
         qsfpModSelL   => qsfpModSelL,
         qsfpModPrsL   => qsfpModPrsL,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

   U_UnusedQsfp : entity work.TerminateQsfp
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         ---------------------
         --  Application Ports
         ---------------------         
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP,
         qsfp0RefClkN    => qsfp0RefClkN,
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP    => qsfp1RefClkP,
         qsfp1RefClkN    => qsfp1RefClkN,
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN);

end top_level;
