###############################################################################
# Created by write_sdc
# Wed Nov 21 17:01:46 2022
###############################################################################
current_design core_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 25.0000 [get_ports {clk}]
set_propagated_clock [get_clocks {clk}]


###############################################################################
# Design Rules
###############################################################################