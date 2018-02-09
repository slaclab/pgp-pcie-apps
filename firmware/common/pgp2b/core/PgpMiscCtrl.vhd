-------------------------------------------------------------------------------
-- File       : PgpMiscCtrl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-04
-- Last update: 2018-02-08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP Gen3 Card'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP Gen3 Card', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiPciePkg.all;
use work.AppPkg.all;

entity PgpMiscCtrl is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Control/Status  (axilClk domain)
      config          : out ConfigType;
      rxUserRst       : out sl;
      txUserRst       : out sl;
      -- AXI-Lite Register Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpMiscCtrl;

architecture rtl of PgpMiscCtrl is

   type RegType is record
      config         : ConfigType;
      rxUserRst      : sl;
      txUserRst      : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      config         => CONFIG_INIT_C,
      rxUserRst      => '0',
      txUserRst      => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rxUserReset : sl;
   signal txUserReset : sl;

   attribute use_dsp48      : string;
   attribute use_dsp48 of r : signal is "yes";

begin

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(regCon, x"68", 0, v.config.gtDrpOverride);
      axiSlaveRegister(regCon, x"6C", 0, v.config.txDiffCtrl);

      axiSlaveRegister(regCon, x"70", 0, v.config.txPreCursor);
      axiSlaveRegister(regCon, x"74", 0, v.config.txPostCursor);
      axiSlaveRegister(regCon, x"78", 0, v.config.qPllRxSelect);
      axiSlaveRegister(regCon, x"7C", 0, v.config.qPllTxSelect);

      axiSlaveRegister(regCon, x"80", 0, v.txUserRst);
      axiSlaveRegister(regCon, x"84", 0, v.rxUserRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      config         <= r.config;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_rxUserRst : entity work.PwrUpRst
      generic map (
         TPD_G       => TPD_G,
         USE_DSP48_G => "yes",
         DURATION_G  => 125000000)
      port map (
         arst   => r.rxUserRst,
         clk    => axilClk,
         rstOut => rxUserReset);

   U_RstRx : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => rxUserReset,
         rstOut => rxUserRst);

   U_txUserRst : entity work.PwrUpRst
      generic map (
         TPD_G       => TPD_G,
         USE_DSP48_G => "yes",
         DURATION_G  => 125000000)
      port map (
         arst   => r.txUserRst,
         clk    => axilClk,
         rstOut => txUserReset);

   U_RstTx : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => txUserReset,
         rstOut => txUserRst);

end rtl;
