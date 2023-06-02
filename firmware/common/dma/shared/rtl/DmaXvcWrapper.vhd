-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: XVC Wrapper
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.EthMacPkg.all;
use surf.Pgp4Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity DmaXvcWrapper is
   generic (
      TPD_G                  : time    := 1 ns;
      SIMULATION_G           : boolean := false;
      IB_SLAVE_AXI_CONFIG_G  : AxiStreamConfigType;
      OB_MASTER_AXI_CONFIG_G : AxiStreamConfigType);
   port (
      -- Clock and Reset (xvcClk domain)
      xvcClk       : in sl;
      xvcRst       : in sl;
      -- Clock and Reset (pgpClk domain)
      axilClk      : in sl;
      axilRst      : in sl;
      -- IB FIFO
      ibFifoMaster : in  AxiStreamMasterType;
      ibFifoSlave  : out AxiStreamSlaveType;
      -- OB FIFO
      obFifoSlave  : in  AxiStreamSlaveType;
      obFifoMaster : out AxiStreamMasterType);
end DmaXvcWrapper;

architecture rtl of DmaXvcWrapper is

   signal ibXvcMaster  : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal ibXvcSlave   : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal obXvcMaster  : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal obXvcSlave   : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   signal rxFifoSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal txFifoMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;

begin

   -----------------------------------------------------------------
   -- Xilinx Virtual Cable (XVC)
   -- https://www.xilinx.com/products/intellectual-property/xvc.html
   -----------------------------------------------------------------
   U_XVC : entity surf.UdpDebugBridgeWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk            => xvcClk,
         rst            => xvcRst,
         -- UDP XVC Interface
         obServerMaster => ibXvcMaster,
         obServerSlave  => ibXvcSlave,
         ibServerMaster => obXvcMaster,
         ibServerSlave  => obXvcSlave);

   U_IB_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         -- FIFO configurations
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => IB_SLAVE_AXI_CONFIG_G,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => ibFifoMaster,
         sAxisSlave  => rxFifoSlave,
         -- Master Port
         mAxisClk    => xvcClk,
         mAxisRst    => xvcRst,
         mAxisMaster => ibXvcMaster,
         mAxisSlave  => ibXvcSlave);

   U_OB_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         -- FIFO configurations
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => EMAC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => OB_MASTER_AXI_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => xvcClk,
         sAxisRst    => xvcRst,
         sAxisMaster => obXvcMaster,
         sAxisSlave  => obXvcSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => txFifoMaster,
         mAxisSlave  => obFifoSlave);

   GEN_REAL : if (SIMULATION_G = false) generate
      -- tie with FIFOs
      ibFifoSlave  <= rxFifoSlave;
      obFifoMaster <= txFifoMaster;
   end generate GEN_REAL;

   GEN_SIM : if (SIMULATION_G = true) generate
      -- bypass
      ibFifoSlave  <= AXI_STREAM_SLAVE_FORCE_C;
      obFifoMaster <= AXI_STREAM_MASTER_INIT_C;
   end generate GEN_SIM;

end rtl;