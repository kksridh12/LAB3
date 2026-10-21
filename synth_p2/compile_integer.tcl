# Lab 3 Part 2 — original integer systolic multiplier
# Run from LAB3/synth_p2 with: dc_shell-t -f compile_integer.tcl
set my_toplevel matmul_4x4_systolic
set my_clock_pin clk
set my_clk_freq_MHz 1000
set my_input_delay_ns 0.1
set my_output_delay_ns 0.1

set OSU_FREEPDK [file join [getenv PDK_DIR] osu_soc lib files]
set search_path [concat $search_path [list $OSU_FREEPDK]]
set alib_library_analysis_path $OSU_FREEPDK
set target_library [list gscl45nm.db]
set link_library [list * gscl45nm.db dw_foundation.sldb]
define_design_lib WORK -path ./WORK_integer
set verilogout_show_unconnected_pins true

analyze -format verilog [list ./original/matmul.v]
elaborate $my_toplevel
current_design $my_toplevel
link
uniquify

set my_period [expr {1000.0 / $my_clk_freq_MHz}]
create_clock -period $my_period [get_ports $my_clock_pin]
set_driving_cell -lib_cell INVX1 [all_inputs]
set_input_delay $my_input_delay_ns -clock clk [remove_from_collection [all_inputs] [get_ports $my_clock_pin]]
set_output_delay $my_output_delay_ns -clock clk [all_outputs]

compile -ungroup_all -map_effort medium
compile -incremental_mapping -map_effort medium
check_design
report_constraint -all_violators
change_names -hierarchy -rules verilog
file mkdir reports/integer
write_file -format verilog -hierarchy -output reports/integer/matmul_integer_mapped.v
redirect reports/integer/clocks.rep { report_clocks }
redirect reports/integer/timing.rep { report_timing }
redirect reports/integer/cells.rep { report_cell }
redirect reports/integer/area.rep { report_area }
redirect reports/integer/power.rep { report_power }
quit
