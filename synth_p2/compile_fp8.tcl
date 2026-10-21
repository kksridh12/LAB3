# Lab 3 Part 2 — FP8 SystemVerilog systolic multiplier
# Run from LAB3/synth_p2 with: dc_shell-t -f compile_fp8.tcl
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
define_design_lib WORK -path ./WORK_fp8
set verilogout_show_unconnected_pins true

# Include the FP8 design and all of its Part 1 arithmetic submodules,
# but NOT the testbench, RAM wrapper, or original integer matmul.v.
set fp8_sources [concat [list ../matmul.sv] \
    [lsort [glob -nocomplain ../FPAdd*.sv]] \
    [lsort [glob -nocomplain ../FPMult*.sv]]]
puts "FP8 source files: $fp8_sources"
analyze -format sverilog $fp8_sources
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
file mkdir reports/fp8
write_file -format verilog -hierarchy -output reports/fp8/matmul_fp8_mapped.v
redirect reports/fp8/clocks.rep { report_clocks }
redirect reports/fp8/timing.rep { report_timing }
redirect reports/fp8/cells.rep { report_cell }
redirect reports/fp8/area.rep { report_area }
redirect reports/fp8/power.rep { report_power }
quit
