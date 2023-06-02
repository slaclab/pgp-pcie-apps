##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS Laserlocker Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
## User Debug Script

# Bypass the debug chipscope generation
# return

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
open_run synth_1

create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0 ]
endgroup
create_debug_core u_ila_1 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1 ]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_1 ]
endgroup
create_debug_core u_ila_2 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_2]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_2]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_2]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_2]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_2 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2 ]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_2 ]
endgroup
connect_debug_port u_ila_0/clk [get_nets [list {U_axilClk/clkOut[0]} ]]
connect_debug_port u_ila_1/clk [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/pgpRxClk} ]]
connect_debug_port u_ila_2/clk [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/pgpTxClk} ]]
set_property port_width 1 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_all_in[0]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_rx_datapath_in[0]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_rx_cdr_stable_out[0]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_tx_datapath_in[0]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxReset} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/stableRst} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txReset} ]]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_rx_done_out[0]} ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/txpmaresetdone_out[0]} ]]
create_debug_port u_ila_1 probe
set_property port_width 16 [get_debug_ports u_ila_1/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[1]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[2]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[3]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[4]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[5]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[6]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[7]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[8]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[9]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[10]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[11]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[12]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[13]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[14]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxData[15]} ]]
create_debug_port u_ila_1 probe
set_property port_width 2 [get_debug_ports u_ila_1/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDataK[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDataK[1]} ]]
create_debug_port u_ila_1 probe
set_property port_width 2 [get_debug_ports u_ila_1/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDispErr[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDispErr[1]} ]]
create_debug_port u_ila_1 probe
set_property port_width 2 [get_debug_ports u_ila_1/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDecErr[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxDecErr[1]} ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtpowergood_out[0]} ]]
create_debug_port u_ila_1 probe
set_property port_width 16 [get_debug_ports u_ila_1/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[1]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[2]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[3]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[4]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[5]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[6]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[7]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[8]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[9]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[10]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[11]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[12]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[13]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[14]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_rx_out[15]} ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxResetDone} ]]
set_property port_width 2 [get_debug_ports u_ila_2/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txDataK[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txDataK[1]} ]]
create_debug_port u_ila_2 probe
set_property port_width 16 [get_debug_ports u_ila_2/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
connect_debug_port u_ila_2/probe1 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[1]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[2]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[3]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[4]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[5]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[6]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[7]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[8]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[9]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[10]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[11]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[12]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[13]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[14]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txData[15]} ]]
create_debug_port u_ila_2 probe
set_property port_width 16 [get_debug_ports u_ila_2/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
connect_debug_port u_ila_2/probe2 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[0]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[1]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[2]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[3]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[4]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[5]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[6]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[7]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[8]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[9]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[10]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[11]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[12]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[13]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[14]} {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_userdata_tx_in[15]} ]]
create_debug_port u_ila_2 probe
set_property port_width 1 [get_debug_ports u_ila_2/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
connect_debug_port u_ila_2/probe3 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/gtwiz_reset_tx_done_out[0]} ]]
create_debug_port u_ila_2 probe
set_property port_width 1 [get_debug_ports u_ila_2/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
connect_debug_port u_ila_2/probe4 [get_nets [list {U_Hardware_1/U_PgpLaneWrapper_1/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/txResetDone} ]]


###############################
## Set the name of the ILA core
###############################
# set ilaCore u_ila_0

# ##################
# ## Create the core
# ##################
# CreateDebugCore ${ilaCore}

# #######################
# ## Set the record depth
# #######################
# set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaCore}]

# #################################
# ## Set the clock for the ILA core
# #################################
# SetDebugCoreClk ${ilaCore} {dmaClk}


# #######################
# ## Set the debug Probes
# #######################
# ConfigProbe ${ilaCore} {dmaRst}


# ##########################
# ## Write the port map file
# ##########################
# WriteDebugProbes ${ilaCore}
