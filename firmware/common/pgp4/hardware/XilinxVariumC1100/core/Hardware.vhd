-------------------------------------------------------------------------------
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
      ---------------------
      --  Hardware Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  sl;
      qsfp0RefClkN    : in  sl;
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  sl;
      qsfp1RefClkN    : in  sl;
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   signal qsfp0RefClk    : sl;
   signal qsfp0RefClkBuf : sl;
   signal gtRefClk       : sl;

begin

   U_IBUFDS : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => qsfp0RefClkP,
         IB    => qsfp0RefClkN,
         CEB   => '0',
         ODIV2 => qsfp0RefClk,
         O     => open);

   U_BUFG_GT : BUFG_GT
      port map (
         I       => qsfp0RefClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",
         O       => qsfp0RefClkBuf);

   U_gtRefClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 6.206,   -- 161.1328125MHz
         DIVCLK_DIVIDE_G    => 11,      -- 14.6484375MHz = 161.1328125MHz/11
         CLKFBOUT_MULT_F_G  => 80.0,    -- 1171.875MHz = 80 x 14.6484375MHz
         CLKOUT0_DIVIDE_F_G => 7.5)     -- 156.25MHz = 1171.875MHz/7.5
      port map(
         -- Clock Input
         clkIn     => qsfp0RefClkBuf,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => gtRefClk);

   --------------
   -- PGP Modules
   --------------
   U_Pgp : entity work.PgpGtyLaneWrapper
      generic map (
         TPD_G             => TPD_G,
         USE_GTREFCLK_G    => true, -- TRUE: gtRefClk
         RATE_G            => RATE_G,
         REFCLK_WIDTH_G    => 1,
         NUM_VC_G          => 4,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXI_BASE_ADDR_G   => AXI_BASE_ADDR_G)
      port map (
         gtRefClk        => gtRefClk,
         -- QSFP[0] Ports
         qsfp0RefClkP(0) => '0',
         qsfp0RefClkN(0) => '1',
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP(0) => '0',
         qsfp1RefClkN(0) => '1',
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end mapping;
