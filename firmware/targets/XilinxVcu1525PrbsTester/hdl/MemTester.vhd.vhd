-------------------------------------------------------------------------------
-- File       : MemTester.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-01-30
-- Last update: 2018-01-30
-------------------------------------------------------------------------------
-- Description: MemTester File
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
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

library unisim;
use unisim.vcomponents.all;

entity MemTester is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Application AXI Interface (memClk domain)
      memClk          : in  sl;
      memRst          : in  sl;
      memReady        : in  sl;
      memWriteMasters : out AxiWriteMasterArray(3 downto 0);
      memWriteSlaves  : in  AxiWriteSlaveArray(3 downto 0);
      memReadMasters  : out AxiReadMasterArray(3 downto 0);
      memReadSlaves   : in  AxiReadSlaveArray(3 downto 0));
end MemTester;

architecture mapping of MemTester is

   constant TPD_C : time := 1 ns;

   constant START_ADDR_C : slv(APP_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(APP_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');

   constant NUM_AXIL_MASTERS_C : natural := 4;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 15, 12);

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal memReset : sl;

begin

   U_Rst : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => memClk,
         rstIn  => memRst,
         rstOut => memReset);

   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_C,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
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

   GEN_VEC :
   for i in 3 downto 0 generate
      U_AxiMemTester : entity work.AxiMemTester
         generic map (
            TPD_G        => TPD_C,
            START_ADDR_G => START_ADDR_C,
            STOP_ADDR_G  => STOP_ADDR_C,
            AXI_CONFIG_G => APP_AXI_CONFIG_C)
         port map (
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i),
            -- Memory Interface
            axiClk          => memClk,
            axiRst          => memReset,
            start           => memReady,
            axiWriteMaster  => memWriteMasters(i),
            axiWriteSlave   => memWriteSlaves(i),
            axiReadMaster   => memReadMasters(i),
            axiReadSlave    => memReadSlaves(i));
   end generate GEN_VEC;

end mapping;
