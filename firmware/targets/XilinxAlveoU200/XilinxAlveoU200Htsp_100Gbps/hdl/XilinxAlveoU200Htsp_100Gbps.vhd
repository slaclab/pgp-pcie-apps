-------------------------------------------------------------------------------
-- File       : XilinxAlveoU200Htsp_100Gbps.vhd
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
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.HtspPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

entity XilinxAlveoU200Htsp_100Gbps is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      BUILD_INFO_G         : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP  : in  slv(1 downto 0);
      qsfp0RefClkN  : in  slv(1 downto 0);
      qsfp0RxP      : in  slv(3 downto 0);
      qsfp0RxN      : in  slv(3 downto 0);
      qsfp0TxP      : out slv(3 downto 0);
      qsfp0TxN      : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP  : in  slv(1 downto 0);
      qsfp1RefClkN  : in  slv(1 downto 0);
      qsfp1RxP      : in  slv(3 downto 0);
      qsfp1RxN      : in  slv(3 downto 0);
      qsfp1TxP      : out slv(3 downto 0);
      qsfp1TxN      : out slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      userClkP      : in  sl;
      userClkN      : in  sl;
      -- QSFP[1:0] Ports
      qsfpFs        : out Slv2Array(1 downto 0);
      qsfpRefClkRst : out slv(1 downto 0);
      qsfpRstL      : out slv(1 downto 0);
      qsfpLpMode    : out slv(1 downto 0);
      qsfpModSelL   : out slv(1 downto 0);
      qsfpModPrsL   : in  slv(1 downto 0);
      -- PCIe Ports
      pciRstL       : in  sl;
      pciRefClkP    : in  sl;
      pciRefClkN    : in  sl;
      pciRxP        : in  slv(15 downto 0);
      pciRxN        : in  slv(15 downto 0);
      pciTxP        : out slv(15 downto 0);
      pciTxN        : out slv(15 downto 0));
end XilinxAlveoU200Htsp_100Gbps;

architecture top_level of XilinxAlveoU200Htsp_100Gbps is

   -- constant TX_MAX_PAYLOAD_SIZE_C : positive := 1024;
   -- constant TX_MAX_PAYLOAD_SIZE_C : positive := 2048;
   -- constant TX_MAX_PAYLOAD_SIZE_C : positive := 4096;
   constant TX_MAX_PAYLOAD_SIZE_C : positive := 8192;

   constant AXIL_CLK_FREQ_C : real := 156.25E+6;  -- units of Hz

   signal userClk156      : sl;
   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(1 downto 0);

begin

   U_axilClk : entity surf.ClockManagerUltraScale
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

   U_Core : entity axi_pcie_core.XilinxAlveoU200Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => HTSP_AXIS_CONFIG_C,
         DMA_BURST_BYTES_G    => 4096,
         DMA_SIZE_G           => 2)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         userClk156      => userClk156,
         -- DMA Interfaces
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface
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
         userClkP        => userClkP,
         userClkN        => userClkN,
         -- QSFP[1:0] Ports
         qsfpFs          => qsfpFs,
         qsfpRefClkRst   => qsfpRefClkRst,
         qsfpRstL        => qsfpRstL,
         qsfpLpMode      => qsfpLpMode,
         qsfpModSelL     => qsfpModSelL,
         qsfpModPrsL     => qsfpModPrsL,
         -- PCIe Ports
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   U_Hardware : entity work.Hardware
      generic map (
         TPD_G                 => TPD_G,
         AXIL_CLK_FREQ_G       => AXIL_CLK_FREQ_C,
         TX_MAX_PAYLOAD_SIZE_G => TX_MAX_PAYLOAD_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         ------------------
         --  Hardware Ports
         ------------------
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
