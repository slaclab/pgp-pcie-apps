-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application File
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
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.HtspPkg.all;

entity Application is
   generic (
      TPD_G                 : time             := 1 ns;
      AXIL_BASE_ADDR_G      : slv(31 downto 0) := x"0040_0000";
      AXIL_CLK_FREQ_G       : real             := 156.25E+6;
      TX_MAX_PAYLOAD_SIZE_G : positive         := 8192);
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
      dmaObMaster     : out AxiStreamMasterType;
      dmaObSlave      : in  AxiStreamSlaveType;
      dmaIbMaster     : in  AxiStreamMasterType;
      dmaIbSlave      : out AxiStreamSlaveType);
end Application;

architecture mapping of Application is

   constant NUM_AXIL_MASTERS_C : natural := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 18, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal readMaster  : AxiLiteReadMasterType;
   signal readSlave   : AxiLiteReadSlaveType;
   signal writeMaster : AxiLiteWriteMasterType;
   signal writeSlave  : AxiLiteWriteSlaveType;

   signal axilReset : sl;
   signal dmaReset  : sl;

begin

   U_axilRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => axilRst,
         rstOut => axilReset);

   U_dmaRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => dmaClk,
         rstIn  => dmaRst,
         rstOut => dmaReset);

   ----------------------------------
   -- Map the AXI-Lite to Application
   ----------------------------------
   U_AxiLiteAsync : entity surf.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         COMMON_CLK_G    => false,
         NUM_ADDR_BITS_G => 24)
      port map (
         -- Slave Interface
         sAxiClk         => axilClk,
         sAxiClkRst      => axilReset,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         -- Master Interface
         mAxiClk         => dmaClk,
         mAxiClkRst      => dmaReset,
         mAxiReadMaster  => readMaster,
         mAxiReadSlave   => readSlave,
         mAxiWriteMaster => writeMaster,
         mAxiWriteSlave  => writeSlave);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => dmaClk,
         axiClkRst           => dmaReset,
         sAxiWriteMasters(0) => writeMaster,
         sAxiWriteSlaves(0)  => writeSlave,
         sAxiReadMasters(0)  => readMaster,
         sAxiReadSlaves(0)   => readSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------------
   -- AXI-Lite: PRBS TX
   --------------------
   U_SsiPrbsTx : entity surf.SsiPrbsTx
      generic map (
         TPD_G                      => TPD_G,
         AXI_DEFAULT_PKT_LEN_G      => toSlv((2*512*1024/64)-1, 32),  -- 500Kpixels @ 2B per pixel
         AXI_DEFAULT_TRIG_DLY_G     => toSlv(24999, 32),  -- 250MHz DMA clock / 10kHz trig rate - 1
         PRBS_SEED_SIZE_G           => 512,
         MASTER_AXI_STREAM_CONFIG_G => HTSP_AXIS_CONFIG_C)
      port map (
         mAxisClk        => dmaClk,
         mAxisRst        => dmaReset,
         mAxisMaster     => dmaObMaster,
         mAxisSlave      => dmaObSlave,
         locClk          => dmaClk,
         locRst          => dmaReset,
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1));

   --------------------
   -- AXI-Lite: PRBS RX
   --------------------
   U_SsiPrbsRx : entity surf.SsiPrbsRx
      generic map (
         TPD_G                     => TPD_G,
         PRBS_SEED_SIZE_G          => 512,
         SLAVE_AXI_STREAM_CONFIG_G => HTSP_AXIS_CONFIG_C)
      port map (
         sAxisClk       => dmaClk,
         sAxisRst       => dmaReset,
         sAxisMaster    => dmaIbMaster,
         sAxisSlave     => dmaIbSlave,
         axiClk         => dmaClk,
         axiRst         => dmaReset,
         axiReadMaster  => axilReadMasters(2),
         axiReadSlave   => axilReadSlaves(2),
         axiWriteMaster => axilWriteMasters(2),
         axiWriteSlave  => axilWriteSlaves(2));

end mapping;
