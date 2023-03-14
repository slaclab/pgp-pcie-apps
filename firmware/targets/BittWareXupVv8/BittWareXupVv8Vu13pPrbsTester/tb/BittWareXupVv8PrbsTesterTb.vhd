-------------------------------------------------------------------------------
-- Title      : Testbench for design "BittWareXupVv8PrbsTester"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of PGP PCIE Apps. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of PGP PCIe Apps, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;
use axi_pcie_core.MigPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

----------------------------------------------------------------------------------------------------

entity BittWareXupVv8PrbsTesterTb is

end entity BittWareXupVv8PrbsTesterTb;

----------------------------------------------------------------------------------------------------

architecture sim of BittWareXupVv8PrbsTesterTb is

   -- component generics
   constant TPD_G                : time                        := 1 ns;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant TX_EN_G              : boolean                     := true;
   constant RX_EN_G              : boolean                     := true;
   constant NUM_DIMM_G           : natural range 0 to 4        := 0;
   constant DMA_SIZE_G           : positive                    := 8;
   constant NUM_VC_G             : positive                    := 16;
   constant DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
   constant DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 8;
   constant PRBS_SEED_SIZE_G     : natural range 32 to 512     := 32;

   -- component ports
   signal ddrClkP        : slv(3 downto 0);            -- [in]
   signal ddrClkN        : slv(3 downto 0);            -- [in]
   signal ddrOut         : DdrOutArray(3 downto 0);    -- [out]
   signal ddrInOut       : DdrInOutArray(3 downto 0);  -- [inout]
   signal qsfpRefClkP    : slv(7 downto 0);                       -- [in]
   signal qsfpRefClkN    : slv(7 downto 0);                       -- [in]
   signal qsfpRxP        : slv(31 downto 0);                      -- [in]
   signal qsfpRxN        : slv(31 downto 0);                      -- [in]
   signal qsfpTxP        : slv(31 downto 0);                      -- [out]
   signal qsfpTxN        : slv(31 downto 0);                      -- [out]
   signal fpgaI2cMasterL : sl;                                    -- [out]
   signal userClkP       : sl;                                    -- [in]
   signal userClkN       : sl;                                    -- [in]
   signal pciRstL        : sl;                                    -- [in]
   signal pciRefClkP     : sl;                                    -- [in]
   signal pciRefClkN     : sl;                                    -- [in]
   signal pciRxP         : slv(15 downto 0);                      -- [in]
   signal pciRxN         : slv(15 downto 0);                      -- [in]
   signal pciTxP         : slv(15 downto 0);                      -- [out]
   signal pciTxN         : slv(15 downto 0);                      -- [out]

begin

   -- component instantiation
   U_BittWareXupVv8PrbsTester : entity work.BittWareXupVv8PrbsTester
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         TX_EN_G              => TX_EN_G,
         RX_EN_G              => RX_EN_G,
         NUM_DIMM_G           => NUM_DIMM_G,
         DMA_SIZE_G           => DMA_SIZE_G,
         NUM_VC_G             => NUM_VC_G,
         DMA_BURST_BYTES_G    => DMA_BURST_BYTES_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         PRBS_SEED_SIZE_G     => PRBS_SEED_SIZE_G)
      port map (
         ddrClkP        => ddrClkP,         -- [in]
         ddrClkN        => ddrClkN,         -- [in]
         ddrOut         => ddrOut,          -- [out]
         ddrInOut       => ddrInOut,        -- [inout]
         qsfpRefClkP    => qsfpRefClkP,     -- [in]
         qsfpRefClkN    => qsfpRefClkN,     -- [in]
         qsfpRxP        => qsfpRxP,         -- [in]
         qsfpRxN        => qsfpRxN,         -- [in]
         qsfpTxP        => qsfpTxP,         -- [out]
         qsfpTxN        => qsfpTxN,         -- [out]
         fpgaI2cMasterL => fpgaI2cMasterL,  -- [out]
         userClkP       => userClkP,        -- [in]
         userClkN       => userClkN,        -- [in]
         pciRstL        => pciRstL,         -- [in]
         pciRefClkP     => pciRefClkP,      -- [in]
         pciRefClkN     => pciRefClkN,      -- [in]
         pciRxP         => pciRxP,          -- [in]
         pciRxN         => pciRxN,          -- [in]
         pciTxP         => pciTxP,          -- [out]
         pciTxN         => pciTxN);         -- [out]


   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => pciRefClkP,
         clkN => pciRefClkN,
         rst  => open,
         rstL => open);

   CLK_GEN_DDR: for i in 3 downto 0 generate
   ddrClkP(i) <= pciRefClkP;
   ddrClkN(i) <= pciRefClkN;
   end generate CLK_GEN_DDR;
   
   userClkP <= pciRefClkP;
   userClkN <= pciRefClkN;

   U_ClkRst_2 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 3.1 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => qsfpRefClkP(0),
         clkN => qsfpRefClkN(0),
         rst  => open,
         rstL => open);

   CLK_GEN_QSFP : for i in 7 downto 1 generate
      qsfpRefClkP(i) <= qsfpRefClkP(0);
      qsfpRefClkN(i) <= qsfpRefClkN(0);
   end generate CLK_GEN_QSFP;

end architecture sim;

----------------------------------------------------------------------------------------------------
