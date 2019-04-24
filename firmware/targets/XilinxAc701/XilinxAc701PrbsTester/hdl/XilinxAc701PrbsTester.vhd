-------------------------------------------------------------------------------
-- File       : XilinxAc701PrbsTester.vhd
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxAc701PrbsTester is
   generic (
      TPD_G : time := 1 ns;

      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;

      DMA_SIZE_G : positive := 1;
      NUM_VC_G   : positive := 1;

      PRBS_SEED_SIZE_G : natural range 32 to 256 := 256;

      BUILD_INFO_G : BuildInfoType);
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
      pciRxP     : in  slv(0 downto 0);
      pciRxN     : in  slv(0 downto 0);
      pciTxP     : out slv(0 downto 0);
      pciTxN     : out slv(0 downto 0));
end XilinxAc701PrbsTester;

architecture top_level of XilinxAc701PrbsTester is

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal dmaClk       : sl;
   signal dmaRst       : sl;
   signal dmaObMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

begin

   axilClk <= dmaClk;
   axilRst <= dmaRst;

   U_Core : entity work.XilinxAc701Core
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
         dmaObMasters   => dmaObMasters,
         dmaObSlaves    => dmaObSlaves,
         dmaIbMasters   => dmaIbMasters,
         dmaIbSlaves    => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
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

   ---------------
   -- PRBS Modules
   ---------------
   U_Hardware : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_G,
         NUM_VC_G          => NUM_VC_G,
         PRBS_SEED_SIZE_G  => PRBS_SEED_SIZE_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- DMA Interface
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves);

end top_level;

