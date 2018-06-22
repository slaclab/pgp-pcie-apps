-------------------------------------------------------------------------------
-- File       : Application.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-01-30
-- Last update: 2018-02-12
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.AxiPciePkg.all;
use work.Pgp3Pkg.all;
use work.BuildInfoPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Application is
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- AXI-Lite Interface (dmaClk domain)
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in    sl;
      dmaRst          : in    sl;
      dmaObMasters    : in    AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out   AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out   AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in    AxiStreamSlaveArray(7 downto 0);
      -- MIG[1] DDR AXI Interface (mig1Clk domain)
      mig1Clk         : in    sl;
      mig1Rst         : in    sl;
      mig1Ready       : in    sl;
      mig1WriteMaster : out   AxiWriteMasterType;
      mig1WriteSlave  : in    AxiWriteSlaveType;
      mig1ReadMaster  : out   AxiReadMasterType;
      mig1ReadSlave   : in    AxiReadSlaveType;
      ---------------------
      --  Application Ports
      ---------------------          
      -- MIG[0] DDR Ports
      mig0DdrClkP     : in    sl;
      mig0DdrClkN     : in    sl;
      mig0DdrOut      : out   DdrOutType;
      mig0DdrInOut    : inout DdrInOutType;
      -- MIG[2] DDR Ports
      mig2DdrClkP     : in    sl;
      mig2DdrClkN     : in    sl;
      mig2DdrOut      : out   DdrOutType;
      mig2DdrInOut    : inout DdrInOutType;
      -- MIG[3] DDR Ports
      mig3DdrClkP     : in    sl;
      mig3DdrClkN     : in    sl;
      mig3DdrOut      : out   DdrOutType;
      mig3DdrInOut    : inout DdrInOutType;
      -- QSFP[0] Ports
      qsfp0RefClkP    : in    slv(1 downto 0);
      qsfp0RefClkN    : in    slv(1 downto 0);
      qsfp0RxP        : in    slv(3 downto 0);
      qsfp0RxN        : in    slv(3 downto 0);
      qsfp0TxP        : out   slv(3 downto 0);
      qsfp0TxN        : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in    slv(1 downto 0);
      qsfp1RefClkN    : in    slv(1 downto 0);
      qsfp1RxP        : in    slv(3 downto 0);
      qsfp1RxN        : in    slv(3 downto 0);
      qsfp1TxP        : out   slv(3 downto 0);
      qsfp1TxN        : out   slv(3 downto 0));
end Application;

architecture mapping of Application is

   -- Defined module generics as constants (in case partial reconfiguration build)
   constant TPD_G            : time             := 1 ns;
   constant AXI_BASE_ADDR_G  : slv(31 downto 0) := BAR0_BASE_ADDR_C;

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 23, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

   -- Unused memory signals
   mig1WriteMaster <= AXI_WRITE_MASTER_INIT_C;
   mig1ReadMaster  <= AXI_READ_MASTER_INIT_C;

   -------------------------
   -- Unused QSFP interfaces
   -------------------------
   U_UnusedQsfp : entity work.TerminateQsfp
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk      => axilClk,
         axilRst      => axilRst,
         ---------------------
         --  Application Ports
         ---------------------         
         -- QSFP[0] Ports
         qsfp0RefClkP => qsfp0RefClkP,
         qsfp0RefClkN => qsfp0RefClkN,
         qsfp0RxP     => qsfp0RxP,
         qsfp0RxN     => qsfp0RxN,
         qsfp0TxP     => qsfp0TxP,
         qsfp0TxN     => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP => qsfp1RefClkP,
         qsfp1RefClkN => qsfp1RefClkN,
         qsfp1RxP     => qsfp1RxP,
         qsfp1RxN     => qsfp1RxN,
         qsfp1TxP     => qsfp1TxP,
         qsfp1TxN     => qsfp1TxN);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
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

   ------------------------------
   -- Standard AXI Version module
   ------------------------------
   U_Version : entity work.AxiVersion
      generic map (
         TPD_G        => TPD_C,
         BUILD_INFO_G => BUILD_INFO_C,
         CLK_PERIOD_G => (0.5/SYS_CLK_FREQ_C))
      port map (
         -- AXI-Lite Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(0),
         axiReadSlave   => axilReadSlaves(0),
         axiWriteMaster => axilWriteMasters(0),
         axiWriteSlave  => axilWriteSlaves(0));

   ---------------
   -- PRBS Modules
   ---------------
   U_Hardware : entity work.Hardware
      generic map (
         TPD_G            => TPD_G,
         NUM_VC_G         => 4,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(1).baseAddr)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1),
         -- DMA Interface
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves);

end mapping;
