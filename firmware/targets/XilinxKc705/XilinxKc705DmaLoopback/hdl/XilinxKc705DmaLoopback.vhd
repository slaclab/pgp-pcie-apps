-------------------------------------------------------------------------------
-- File       : XilinxKc705DmaLoopback.vhd
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

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxKc705DmaLoopback is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      DMA_SIZE_G           : positive                    := 1;
      BUILD_INFO_G         : BuildInfoType);
   port (
      -------------------
      --  Top Level Ports
      -------------------       
      -- System Ports
      emcClk     : in  sl;
      -- Boot Memory Ports
      bootCsL    : out sl;
      bootMosi   : out sl;
      bootMiso   : in  sl;
      -- PCIe Ports
      pciRstL    : in  sl;
      pciRefClkP : in  sl;              -- 100 MHz
      pciRefClkN : in  sl;              -- 100 MHz
      pciRxP     : in  slv(3 downto 0);
      pciRxN     : in  slv(3 downto 0);
      pciTxP     : out slv(3 downto 0);
      pciTxN     : out slv(3 downto 0));
end XilinxKc705DmaLoopback;

architecture top_level of XilinxKc705DmaLoopback is

   signal axilClk : sl;
   signal axilRst : sl;

   signal dmaClk     : sl;
   signal dmaRst     : sl;
   signal dmaMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

begin

   axilClk <= dmaClk;
   axilRst <= dmaRst;

   U_Core : entity work.XilinxKc705Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_SIZE_G           => DMA_SIZE_G)
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
         -- AXI-Lite Interface
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => open,
         appReadSlave   => AXI_LITE_READ_SLAVE_EMPTY_OK_C,
         appWriteMaster => open,
         appWriteSlave  => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C,
         -------------------
         --  Top Level Ports
         -------------------            
         -- System Ports
         emcClk         => emcClk,
         -- Boot Memory Ports 
         bootCsL        => bootCsL,
         bootMosi       => bootMosi,
         bootMiso       => bootMiso,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

end top_level;
