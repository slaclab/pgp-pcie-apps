-------------------------------------------------------------------------------
-- File       : Hardware.vhd
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
      TPD_G             : time                    := 1 ns;
      DMA_SIZE_G        : positive                := 1;
      NUM_VC_G          : positive                := 1;
      PRBS_SEED_SIZE_G  : natural range 32 to 512 := 32;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0)        := x"0080_0000");
   port (
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
      dmaObMasters    : in  AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0));
end Hardware;

architecture mapping of Hardware is

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(DMA_SIZE_G-1 downto 0) := genAxiLiteConfig(DMA_SIZE_G, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(DMA_SIZE_G-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(DMA_SIZE_G-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(DMA_SIZE_G-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(DMA_SIZE_G-1 downto 0);

   signal dmaReset  : slv(DMA_SIZE_G-1 downto 0);
   signal axilRseet : slv(DMA_SIZE_G-1 downto 0);
   signal pause     : slv(7 downto 0);

begin
   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => DMA_SIZE_G,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ---------------
   -- PRBS Modules
   ---------------
   GEN_VEC : for i in DMA_SIZE_G-1 downto 0 generate

      U_PrbsLane : entity work.PrbsLane
         generic map(
            TPD_G             => TPD_G,
            NUM_VC_G          => NUM_VC_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            PRBS_SEED_SIZE_G  => PRBS_SEED_SIZE_G,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i).baseAddr)
         port map(
            -- DMA Interface
            dmaClk          => dmaClk,
            dmaRst          => dmaReset(i),
            dmaBuffGrpPause => pause,
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRseet(i),
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

      U_dmaRst : entity surf.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => dmaClk,
            rstIn  => dmaRst,
            rstOut => dmaReset(i));

      U_axilRst : entity surf.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => axilClk,
            rstIn  => axilRst,
            rstOut => axilRseet(i));

   end generate;

   -- Help with timing
   process(dmaClk)
   begin
      if rising_edge(dmaClk) then
         pause <= dmaBuffGrpPause after TPD_G;
      end if;
   end process;

end mapping;
