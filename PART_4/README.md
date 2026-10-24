# Part IV: APB-Controlled FP8 8×8 Matrix Multiplier

## Overview

This design adds a 16-bit APB slave interface to the FP8 8×8
systolic matrix multiplier.

The APB slave replaces the original RAM wrapper's start-control FSM.
It provides matrix-address and stride configuration, operation control,
and readable completion and exception status.

PREADY is always high, so APB accesses have zero wait states.
All blocks use the same clock.

## Required Tools

- Synopsys VCS for compilation and simulation
- Synopsys Verdi for waveform inspection
- The course environment setup for VCS, Verdi, and FSDB dumping

Before running, ensure VCS_HOME and VERDI_HOME are configured.
If your course setup uses env.cshrc, source it from a compatible
csh/tcsh shell:

    source env.cshrc

## Files

Part IV files:

- apb_slave.sv
- matmul_with_ram_8x8_apb.sv
- matmul_with_ram_8x8_apb_tb.sv
- Makefile
- part4.f

Required computation and memory files:

- matmul_part3.sv
- matmul_8x8.sv
- ram.sv
- FPAdd.sv and its submodules
- FPMult.sv and its submodules

The simulation top is:

    matmul_with_ram_8x8_apb_tb

The design top is:

    matrix_multiplication_8x8_apb

part4.f lists the source files to compile. Its paths are relative
to the directory where make is run. matmul_part3.sv must appear
before files that use its macro definitions.

Do not include the original Part III wrapper or its testbenches
in the Part IV source list.

## Compile and Run

Open a terminal in the directory containing Makefile and part4.f.

Compile and run:

    make

Alternatively, compile and run separately:

    make compile_verdi
    make sim

Compilation and simulation messages are saved in:

- compile_and_sim.log when using make
- compile_verdi.log when using make compile_verdi
- simulation.log when using make sim

The Makefile enables FSDB generation by default. FSDB dumping
requires the environment's Verdi/VCS dump-library setup.

To run with VCD output instead:

    make compile_and_sim FSDB_FLAGS=

## View Waveforms

For FSDB output:

    make waves_verdi

The waveform file is:

    part4_apb.fsdb

To open the compiled design without loading a waveform:

    make verdi

For VCD output, open part4_apb.vcd using a compatible waveform viewer.

## Testbench Operation

The testbench uses APB read/write tasks adapted from example_tb.v.

For each test, it:

1. Resets the design.
2. Initializes matrix A and B RAM banks through hierarchical paths.
3. Fills output RAMs with a sentinel value.
4. Writes the matrix base addresses and strides through APB.
5. Reads back the configuration registers.
6. Writes the start register.
7. Polls the DONE register until completion.
8. Reads exception flags.
9. Checks output RAM contents for the normal cases.

The read task samples PRDATA at the completing APB rising edge.
A bounded polling loop and a global timeout detect missing completion.

Matrix loading and result inspection use paths such as:

    dut.matrix_A0.ram[index]
    dut.matrix_C0.ram[index]

Renaming RAM instances requires updating these paths.

## Test Cases

### Test 1: A = ones, B = ones

Each input element is FP8 1.0, encoded as 0x30.

Each output element should be FP8 8.0, encoded as 0x60.

The test checks all 64 output elements and expects FLAGS = 0.

### Test 2: A = ones, B = zeros

A contains FP8 1.0 and B contains zero.

The test checks all 64 output elements are zero and expects FLAGS = 0.

Output RAMs initially contain 0xDEADBEEF to prevent an unwritten
zero-initialized RAM from producing a false pass.

### Test 3: Exception Case

A and B contain FP8 15.5, encoded as 0x6F.

The test expects at least one exception flag to assert.
The observed simulation returned FLAGS = 0x0009.

This test checks completion, output-write activity, and exception
status. It does not compare exception-case output encodings.

Each test applies a global reset; consecutive operations without
reset are not covered by this testbench.

## Expected Output

A successful simulation prints:

    PASS: A=ones, B=ones
    PASS: A=ones, B=zeros
    PASS: Finite operands causing overflow

    PART IV: ALL TESTS PASSED

A failing check reports the CSR address or output RAM location.
Timeouts terminate simulation using $fatal.

## Register Map

All CSRs are 16 bits wide. Unused read bits return zero.

| Address | Register | Access | Fields |
|---------|----------|--------|--------|
| 0x00 | CONTROL | R/W | Write bit 0 to start; read bit 15 for busy |
| 0x02 | DONE | R | Bit 15: sticky completion |
| 0x04 | MATRIX_A_ADDRESS | R/W | Bits 9:0: RAM base address |
| 0x06 | MATRIX_B_ADDRESS | R/W | Bits 9:0: RAM base address |
| 0x08 | MATRIX_C_ADDRESS | R/W | Bits 9:0: RAM base address |
| 0x0A | STRIDE_A | R/W | Bits 7:0: address stride |
| 0x0C | STRIDE_B | R/W | Bits 7:0: address stride |
| 0x0E | STRIDE_C | R/W | Bits 7:0: address stride |
| 0x10 | FLAGS | R | Bits 3:0: sticky exception flags |

Configuration writes and new start requests are ignored while busy.
DONE and FLAGS clear on reset or the next accepted start request.
Unmapped reads return zero; unmapped writes have no effect.

## Recommended Waveform Signals

- clk, resetn
- PSEL, PENABLE, PWRITE, PADDR
- PWDATA, PRDATA, PREADY
- dut.address_mat_a/b/c
- dut.address_stride_a/b/c
- dut.start_mat_mul
- dut.done_mat_mul
- dut.flags
- dut.u_apb.done_reg
- dut.u_apb.flags_reg
- dut.c_data_available_left/right
- dut.c_addr_left/right
- dut.c_data_left/right

PRDATA is combinational. When the idle bus parks PADDR at 0,
PRDATA may show busy in bit 15. This is not a DONE read.
A valid DONE read selects address 0x02 during an APB read access.

## Current Core Assumptions

The result checker uses C_RESULT_OFFSET = 2, matching the supplied
Part III checker. It checks eight words per output RAM bank at
addresses 2 through 9.

The supplied 8×8 core uses counter-based completion timing.
The APB wrapper retains that behavior.

## Troubleshooting

- Source file not found:
  Correct the corresponding path in part4.f.

- Undefined macro:
  Check source order and the shared project definitions.

- Unresolved module:
  Add the missing FP8 dependency to part4.f.

- Unknown FSDB system task:
  Load the course FSDB environment/linking setup, or use VCD mode.

- Missing separator in Makefile:
  Ensure command lines begin with a tab.

## Cleanup

Remove generated simulation files:

    make clean


Exclude generated files such as simv, csrc/, simv.daidir/, and
FSDB/VCD waveform databases from the submission ZIP.
