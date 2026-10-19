VCS ?= $(VCS_HOME)/bin/vcs
VERDI ?= $(VERDI_HOME)/bin/verdi

SV_SRCS := \
../testbench_fp.sv \
../FPAdd_AlignModule.sv \
../FPAdd_AlignShift1.sv \
../FPAdd_AlignShift2.sv \
../FPAdd_ExceptionModule.sv \
../FPAdd_ExecutionModule.sv \
../FPAdd_NormalizeModule.sv \
../FPAdd_NormalizeShift1.sv \
../FPAdd_NormalizeShift2.sv \
../FPAdd_PrealignModule.sv \
../FPAdd_RoundModule.sv \
../FPAdd.sv \
../FPMult_ExecuteModule.sv \
../FPMult_NormalizeModule.sv \
../FPMult_PrepModule.sv \
../FPMult_RoundModule.sv \
../FPMult.sv

all: compile_and_sim

# Compile and immediately run simulation
compile_and_sim:
	$(VCS) -R -full64 -sverilog $(SV_SRCS) \
	-kdb -lca -debug_access+all |& tee compile_and_sim.log

# Compile only
compile:
	$(VCS) -full64 -sverilog $(SV_SRCS) \
	-debug_access+all |& tee compile.log

# Compile with Verdi database support
compile_verdi:
	$(VCS) -full64 -sverilog $(SV_SRCS) \
	-debug_access+all -kdb -lca |& tee compile_verdi.log

# Run already-compiled simulation
sim:
	./simv |& tee sim.log

# Launch Verdi
verdi:
	$(VERDI) -dbdir ./simv.daidir -nologo

waves_verdi:
	$(VERDI) -dbdir ./simv.daidir -ssf novas.fsdb -nologo

clean:
	rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key \
	vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.conf *.txt \
	verdi_config_file verdiLog novas.fsdb novas.log *.vcd *.dat novas.rc
