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
      TPD_G             : time             := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
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
      -- QSFP-DD Ports
      qsfpRefClkP  : in  slv(7 downto 0);
      qsfpRefClkN  : in  slv(7 downto 0);
      qsfpRxP      : in  slv(31 downto 0);
      qsfpRxN      : in  slv(31 downto 0);
      qsfpTxP      : out slv(31 downto 0);
      qsfpTxN      : out slv(31 downto 0));
end Hardware;

architecture mapping of Hardware is

begin

   --------------
   -- PGP Modules
   --------------
   U_PgpLaneWrapper_1: entity work.PgpLaneWrapper
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXI_BASE_ADDR_G   => AXI_BASE_ADDR_G)
      port map (
         qsfpRefClkP     => qsfpRefClkP,      -- [in]
         qsfpRefClkN     => qsfpRefClkN,      -- [in]
         qsfpRxP         => qsfpRxP,          -- [in]
         qsfpRxN         => qsfpRxN,          -- [in]
         qsfpTxP         => qsfpTxP,          -- [out]
         qsfpTxN         => qsfpTxN,          -- [out]
         dmaClk          => dmaClk,           -- [in]
         dmaRst          => dmaRst,           -- [in]
         dmaBuffGrpPause => dmaBuffGrpPause,  -- [in]
         dmaObMasters    => dmaObMasters,     -- [in]
         dmaObSlaves     => dmaObSlaves,      -- [out]
         dmaIbMasters    => dmaIbMasters,     -- [out]
         dmaIbSlaves     => dmaIbSlaves,      -- [in]
         axilClk         => axilClk,          -- [in]
         axilRst         => axilRst,          -- [in]
         axilReadMaster  => axilReadMaster,   -- [in]
         axilReadSlave   => axilReadSlave,    -- [out]
         axilWriteMaster => axilWriteMaster,  -- [in]
         axilWriteSlave  => axilWriteSlave);  -- [out]
   
end mapping;