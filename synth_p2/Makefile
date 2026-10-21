# Run from LAB3/synth_p2
.PHONY: all synth_integer synth_fp8 clean_synth clean
all: synth_integer synth_fp8

synth_integer:
	@mkdir -p reports/integer
	dc_shell-t -f compile_integer.tcl > reports/integer/synth.log 2>&1

synth_fp8:
	@mkdir -p reports/fp8
	dc_shell-t -f compile_fp8.tcl > reports/fp8/synth.log 2>&1

# Preserve reports; only clean temporary Design Compiler files.
clean_synth:
	rm -rf WORK_integer WORK_fp8 *.syn *.pvl *.mr *.svf command.log

clean: clean_synth
	rm -rf reports/integer/* reports/fp8/*