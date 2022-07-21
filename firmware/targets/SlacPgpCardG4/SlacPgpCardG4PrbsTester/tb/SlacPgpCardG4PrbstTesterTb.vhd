-------------------------------------------------------------------------------
-- Title      : Testbench for design "SlacPgpCardG4PrbsTester"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of pgp-pcie-apps. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of pgp-pcie-apps, including this file, may be
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

entity SlacPgpCardG4PrbsTesterTb is

end entity SlacPgpCardG4PrbsTesterTb;

----------------------------------------------------------------------------------------------------

architecture sim of SlacPgpCardG4PrbsTesterTb is

   -- component generics
   constant TPD_G                : time                        := 0.2 ns;
   constant DMA_LANES_G          : positive                    := 2;
   constant NUM_VC_G             : positive                    := 8;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
   constant DMA_BYTE_WIDTH_G     : natural                     := 32;
   constant PRBS_SEED_SIZE_G     : natural range 32 to 256     := 32;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;

   -- component ports
   signal emcClk      : sl              := '0';              -- [in]
   signal pwrScl      : sl              := '0';              -- [inout]
   signal pwrSda      : sl              := '0';              -- [inout]
   signal sfpScl      : sl              := '0';              -- [inout]
   signal sfpSda      : sl              := '0';              -- [inout]
   signal qsfpScl     : slv(1 downto 0) := "00";             -- [inout]
   signal qsfpSda     : slv(1 downto 0) := "00";             -- [inout]
   signal qsfpRstL    : slv(1 downto 0) := "00";             -- [out]
   signal qsfpLpMode  : slv(1 downto 0) := "00";             -- [out]
   signal qsfpModSelL : slv(1 downto 0) := "00";             -- [out]
   signal qsfpModPrsL : slv(1 downto 0) := "00";             -- [in]
   signal flashCsL    : sl              := '0';              -- [out]
   signal flashMosi   : sl              := '0';              -- [out]
   signal flashMiso   : sl              := '0';              -- [in]
   signal flashHoldL  : sl              := '0';              -- [out]
   signal flashWp     : sl              := '0';              -- [out]
   signal pciRstL     : sl              := '0';              -- [in]
   signal pciRefClkP  : sl              := '0';              -- [in]
   signal pciRefClkN  : sl              := '0';              -- [in]
   signal pciRxP      : slv(7 downto 0) := (others => '0');  -- [in]
   signal pciRxN      : slv(7 downto 0) := (others => '0');  -- [in]
   signal pciTxP      : slv(7 downto 0) := (others => '0');  -- [out]
   signal pciTxN      : slv(7 downto 0) := (others => '0');  -- [out]

begin

   -- component instantiation
   U_SlacPgpCardG4PrbsTester : entity work.SlacPgpCardG4PrbsTester
      generic map (
         TPD_G                => TPD_G,
         DMA_LANES_G          => DMA_LANES_G,
         NUM_VC_G             => NUM_VC_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         PRBS_SEED_SIZE_G     => PRBS_SEED_SIZE_G,
         BUILD_INFO_G         => BUILD_INFO_G)
      port map (
         emcClk      => emcClk,         -- [in]
         pwrScl      => pwrScl,         -- [inout]
         pwrSda      => pwrSda,         -- [inout]
         sfpScl      => sfpScl,         -- [inout]
         sfpSda      => sfpSda,         -- [inout]
         qsfpScl     => qsfpScl,        -- [inout]
         qsfpSda     => qsfpSda,        -- [inout]
         qsfpRstL    => qsfpRstL,       -- [out]
         qsfpLpMode  => qsfpLpMode,     -- [out]
         qsfpModSelL => qsfpModSelL,    -- [out]
         qsfpModPrsL => qsfpModPrsL,    -- [in]
         flashCsL    => flashCsL,       -- [out]
         flashMosi   => flashMosi,      -- [out]
         flashMiso   => flashMiso,      -- [in]
         flashHoldL  => flashHoldL,     -- [out]
         flashWp     => flashWp,        -- [out]
         pciRstL     => pciRstL,        -- [in]
         pciRefClkP  => pciRefClkP,     -- [in]
         pciRefClkN  => pciRefClkN,     -- [in]
         pciRxP      => pciRxP,         -- [in]
         pciRxN      => pciRxN,         -- [in]
         pciTxP      => pciTxP,         -- [out]
         pciTxN      => pciTxN);        -- [out]



end architecture sim;

----------------------------------------------------------------------------------------------------
