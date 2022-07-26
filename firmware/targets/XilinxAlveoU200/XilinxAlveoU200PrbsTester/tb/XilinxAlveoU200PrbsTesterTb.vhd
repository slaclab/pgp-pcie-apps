-------------------------------------------------------------------------------
-- Title      : Testbench for design "XilinxAlveoU200PrbsTester"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of . It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of , including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;
----------------------------------------------------------------------------------------------------

entity XilinxAlveoU200PrbsTesterTb is

end entity XilinxAlveoU200PrbsTesterTb;

----------------------------------------------------------------------------------------------------

architecture sim of XilinxAlveoU200PrbsTesterTb is

   -- component generics
   constant TPD_G                : time                        := 0.2 ns;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant TX_EN_G              : boolean                     := true;
   constant RX_EN_G              : boolean                     := true;
   constant MIG_EN_G             : boolean                     := false;
   constant DMA_SIZE_G           : positive                    := 2;
   constant NUM_VC_G             : positive                    := 8;
   constant DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
   constant DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 32;
   constant PRBS_SEED_SIZE_G     : natural range 32 to 512     := 32;

   -- component ports
   signal ddrClkP       : slv(3 downto 0)       := (others => '0');              -- [in]
   signal ddrClkN       : slv(3 downto 0)       := (others => '0');              -- [in]
--   signal ddrOut        : DdrOutArray(3 downto 0);                               -- [out]
--   signal ddrInOut      : DdrInOutArray(3 downto 0);                             -- [inout]
   signal userClkP      : sl                    := '0';                          -- [in]
   signal userClkN      : sl                    := '0';                          -- [in]
   signal qsfpFs        : Slv2Array(1 downto 0) := (others => (others => '0'));  -- [out]
   signal qsfpRefClkRst : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpRstL      : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpLpMode    : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpModSelL   : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpModPrsL   : slv(1 downto 0)       := (others => '0');              -- [in]
   signal pciRstL       : sl                    := '0';                          -- [in]
   signal pciRefClkP    : sl                    := '0';                          -- [in]
   signal pciRefClkN    : sl                    := '0';                          -- [in]
   signal pciRxP        : slv(15 downto 0)      := (others => '0');              -- [in]
   signal pciRxN        : slv(15 downto 0)      := (others => '0');              -- [in]
   signal pciTxP        : slv(15 downto 0)      := (others => '0');              -- [out]
   signal pciTxN        : slv(15 downto 0)      := (others => '0');              -- [out]

begin

   -- component instantiation
   U_XilinxAlveoU200PrbsTester : entity work.XilinxAlveoU200PrbsTester
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         TX_EN_G              => TX_EN_G,
         RX_EN_G              => RX_EN_G,
         MIG_EN_G             => MIG_EN_G,
         DMA_SIZE_G           => DMA_SIZE_G,
         NUM_VC_G             => NUM_VC_G,
         DMA_BURST_BYTES_G    => DMA_BURST_BYTES_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         PRBS_SEED_SIZE_G     => PRBS_SEED_SIZE_G)
      port map (
         ddrClkP       => ddrClkP,        -- [in]
         ddrClkN       => ddrClkN,        -- [in]
         ddrOut        => open,           -- [out]
         ddrInOut      => open,           -- [inout]
         userClkP      => userClkP,       -- [in]
         userClkN      => userClkN,       -- [in]
         qsfpFs        => qsfpFs,         -- [out]
         qsfpRefClkRst => qsfpRefClkRst,  -- [out]
         qsfpRstL      => qsfpRstL,       -- [out]
         qsfpLpMode    => qsfpLpMode,     -- [out]
         qsfpModSelL   => qsfpModSelL,    -- [out]
         qsfpModPrsL   => qsfpModPrsL,    -- [in]
         pciRstL       => pciRstL,        -- [in]
         pciRefClkP    => pciRefClkP,     -- [in]
         pciRefClkN    => pciRefClkN,     -- [in]
         pciRxP        => pciRxP,         -- [in]
         pciRxN        => pciRxN,         -- [in]
         pciTxP        => pciTxP,         -- [out]
         pciTxN        => pciTxN);        -- [out]


   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => userClkP,
         clkN => userClkN,
         rst  => open,
         rstL => open);


end architecture sim;

----------------------------------------------------------------------------------------------------
