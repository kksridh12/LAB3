VCS = $(VCS_HOME)/bin/vcs
VERDI = $(VERDI_HOME)/bin/verdi

SV_SRCS := \
	../matmul_part2_tb.sv \
	../matmul.sv \
	../matmul_with_ram.v \
	$(wildcard ../FPAdd*.sv) \
	$(wildcard ../FPMult*.sv)

VCS_FLAGS = -full64 -sverilog -top matmul_part2_tb \
	-kdb -lca -debug_access+all

all: compile_and_sim

# Compile and immediately run simulation
compile_and_sim:
	$(VCS) -R $(VCS_FLAGS) $(SV_SRCS) -l compile_and_sim.log

# Compile only
compile:
	$(VCS) $(VCS_FLAGS) $(SV_SRCS) -l compile.log

# Compile with Verdi support
compile_verdi:
	$(VCS) $(VCS_FLAGS) $(SV_SRCS) -l compile_verdi.log

# Run compiled simulation
sim:
	./simv

# Open Verdi design database
verdi:
	$(VERDI) -dbdir ./simv.daidir -nologo

# Open Verdi with waveforms
waves_verdi:
	$(VERDI) -dbdir ./simv.daidir -ssf novas.fsdb -nologo

# Remove generated simulation files
clean:
	rm -rf simv simv.daidir csrc DVEFiles ucli.key \
		*.log *.fsdb *.vcd *.vpd *.key \
		verdiLog novas.rc verdi_config_file