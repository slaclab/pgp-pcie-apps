-------------------------------------------------------------------------------
-- Title      : Testbench for design "PgpLane"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2bPkg.all;
use surf.SsiPkg.all;

----------------------------------------------------------------------------------------------------

entity PgpLaneTb is

end entity PgpLaneTb;

----------------------------------------------------------------------------------------------------

architecture sim of PgpLaneTb is

   -- component generics
   constant TPD_G             : time                := 1 ns;
   constant SIM_SPEEDUP_G     : boolean             := true;
   constant LANE_G            : natural             := 0;
   constant DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tIdBits => 3);
   constant AXI_BASE_ADDR_G   : slv(31 downto 0)    := (others                      => '0');

   -- component ports
   signal pgpTxP          : sl;                                                             -- [out]
   signal pgpTxN          : sl;                                                             -- [out]
   signal pgpRxP          : sl;                                                             -- [in]
   signal pgpRxN          : sl;                                                             -- [in]
   signal pgpRefClk       : sl;                                                             -- [in]
   signal dmaClk          : sl;                                                             -- [in]
   signal dmaRst          : sl;                                                             -- [in]
   signal dmaBuffGrpPause : slv(7 downto 0)        := (others => '0');                      -- [in]
   signal dmaObMaster     : AxiStreamMasterType    := AXI_STREAM_MASTER_INIT_C;             -- [in]
   signal dmaObSlave      : AxiStreamSlaveType;                                             -- [out]
   signal dmaIbMaster     : AxiStreamMasterType;                                            -- [out]
   signal dmaIbSlave      : AxiStreamSlaveType     := AXI_STREAM_SLAVE_FORCE_C;             -- [in]
   signal axilClk         : sl;                                                             -- [in]
   signal axilRst         : sl;                                                             -- [in]
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;          -- [in]
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;   -- [out]
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;         -- [in]
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;  -- [out]

begin

   pgpRxP <= pgpTxP;
   pgpRxN <= pgpTxN;

   -- component instantiation
   U_PgpLane : entity work.PgpLane
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         LANE_G            => LANE_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXI_BASE_ADDR_G   => AXI_BASE_ADDR_G)
      port map (
         pgpTxP          => pgpTxP,           -- [out]
         pgpTxN          => pgpTxN,           -- [out]
         pgpRxP          => pgpRxP,           -- [in]
         pgpRxN          => pgpRxN,           -- [in]
         pgpRefClk       => pgpRefClk,        -- [in]
         dmaClk          => dmaClk,           -- [in]
         dmaRst          => dmaRst,           -- [in]
         dmaBuffGrpPause => dmaBuffGrpPause,  -- [in]
         dmaObMaster     => dmaObMaster,      -- [in]
         dmaObSlave      => dmaObSlave,       -- [out]
         dmaIbMaster     => dmaIbMaster,      -- [out]
         dmaIbSlave      => dmaIbSlave,       -- [in]
         axilClk         => axilClk,          -- [in]
         axilRst         => axilRst,          -- [in]
         axilReadMaster  => axilReadMaster,   -- [in]
         axilReadSlave   => axilReadSlave,    -- [out]
         axilWriteMaster => axilWriteMaster,  -- [in]
         axilWriteSlave  => axilWriteSlave);  -- [out]


   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => pgpRefClk);

   U_ClkRst_2 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8.0 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => axilClk,
         rst  => axilRst);

   U_ClkRst_3 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 4.0 ns,
         CLK_DELAY_G       => 1.4 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => dmaClk,
         rst  => dmaRst);


end architecture sim;

----------------------------------------------------------------------------------------------------
