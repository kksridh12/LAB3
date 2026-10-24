
TOP := matmul_with_ram_8x8_apb_tb

# Enables the FSDB block in the testbench.

FSDB_FLAGS ?= +define+FSDB

.PHONY: all compile_and_sim compile compile_verdi sim verdi waves_verdi clean

# Compile and simulate. Keep logs and waveforms afterward.
all: compile_and_sim

# Compile with VCS and run simulation
compile_and_sim:
	$(VCS_HOME)/bin/vcs -R -full64 -sverilog \
		-f part4.f -top $(TOP) \
		-debug_access+all -kdb -lca $(FSDB_FLAGS) \
		2>&1 | tee compile_and_sim.log

# Compile with VCS
compile:
	$(VCS_HOME)/bin/vcs -full64 -sverilog \
		-f part4.f -top $(TOP) \
		-debug_access+all $(FSDB_FLAGS) \
		2>&1 | tee compile.log

# Compile and generate the Verdi debug database
compile_verdi:
	$(VCS_HOME)/bin/vcs -full64 -sverilog \
		-f part4.f -top $(TOP) \
		-debug_access+all -kdb -lca $(FSDB_FLAGS) \
		2>&1 | tee compile_verdi.log

# Run the compiled simulation
sim:
	./simv 2>&1 | tee simulation.log

# Launch Verdi
verdi:
	$(VERDI_HOME)/bin/verdi \
		-dbdir ./simv.daidir -nologo

# Launch Verdi with the testbench waveform
waves_verdi:
	$(VERDI_HOME)/bin/verdi \
		-dbdir ./simv.daidir \
		-ssf part4_apb.fsdb -nologo

# Remove generated files only
clean:
	rm -rf csrc simv.daidir DVEFiles verdiLog
	rm -f simv ucli.key vc_hdrs.h
	rm -f compile.log compile_verdi.log compile_and_sim.log simulation.log
	rm -f part4_apb.fsdb part4_apb.vcd
	rm -f novas.conf novas.rc novas.log novas_dump.log
