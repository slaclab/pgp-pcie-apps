-------------------------------------------------------------------------------
-- File       : SlacPgpCardG4Pgp3_10Gbps.vhd
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

entity SlacPgpCardG4Pgp3_10Gbps is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      DMA_AXIS_CONFIG_G    : AxiStreamConfigType         := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);  --- 8 Byte (64-bit) tData interface
      BUILD_INFO_G         : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[1:0] Ports
      qsfpRefClkP : in    sl;
      qsfpRefClkN : in    sl;
      qsfp0RxP    : in    slv(3 downto 0);
      qsfp0RxN    : in    slv(3 downto 0);
      qsfp0TxP    : out   slv(3 downto 0);
      qsfp0TxN    : out   slv(3 downto 0);
      qsfp1RxP    : in    slv(3 downto 0);
      qsfp1RxN    : in    slv(3 downto 0);
      qsfp1TxP    : out   slv(3 downto 0);
      qsfp1TxN    : out   slv(3 downto 0);
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
end SlacPgpCardG4Pgp3_10Gbps;

architecture top_level of SlacPgpCardG4Pgp3_10Gbps is

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(7 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(7 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(7 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(7 downto 0);

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
         CLKIN_PERIOD_G    => 4.0,      -- 250 MHz
         CLKFBOUT_MULT_G   => 5,        -- 1.25GHz = 5 x 250 MHz
         CLKOUT0_DIVIDE_G  => 8)        -- 156.25MHz = 1.25GHz/8
      port map(
         -- Clock Input
         clkIn     => dmaClk,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   U_Core : entity axi_pcie_core.SlacPgpCardG4Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
         DMA_SIZE_G           => 8)
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

   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         RATE_G            => "10.3125Gbps",
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
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
         -- QSFP[1:0] Ports
         qsfpRefClkP     => qsfpRefClkP,
         qsfpRefClkN     => qsfpRefClkN,
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN);

end top_level;
