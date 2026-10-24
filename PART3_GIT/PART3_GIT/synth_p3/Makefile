# Run from LAB3/synth_p3
.PHONY: all synth clean_synth clean
all: synth

synth:
	@mkdir -p reports/
	dc_shell-t -f compile.tcl | tee -i reports/synth.log

# Preserve reports; only clean temporary Design Compiler files.
clean_synth:
	rm -rf WORK *.syn *.pvl *.mr *.svf command.log

clean: clean_synth
	rm -rf reports
