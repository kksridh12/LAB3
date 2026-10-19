//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:      testbench_fp
// Project Name: 	 Floating Point Project
//
// Description:	 Self-checking testbench for the combinational FP8 (E3M4)
//						 adder/subtractor (FPAddSub) and multiplier (FPMult).
//
//						 FP8 E3M4 format: [7] sign, [6:4] exponent (bias 3), [3:0] mantissa
//						 Special values : exponent 0 = zero (denormals flushed to zero)
//											  exponent 7, mantissa 0 = infinity
//											  exponent 7, mantissa != 0 = NaN
//						 Rounding			: round to nearest, ties to even
//
//						 Common encodings used below:
//							0x00 +0      0x80 -0      0x30 +1.0    0xB0 -1.0
//							0x38 +1.5    0xB8 -1.5    0x40 +2.0    0x44 +2.5
//							0xC4 -2.5    0x48 +3.0    0xC8 -3.0    0x32 +1.125
//							0x34 +1.25   0x60 +8.0    0x10 +0.25 (min normal)
//							0x11 +0.265625            0x6F +15.5 (max normal)
//							0x70 +Inf    0x7F NaN
//
//						 Flags: {Overflow, Underflow, Invalid, Inexact}
//
//////////////////////////////////////////////////////////////////////////////////

timeunit 1ns;
timeprecision 1ps;


module testbench_fp;

// Adder signals
	logic [7:0] add_a;
	logic [7:0] add_b;
	logic [7:0] add_result;
	logic [3:0] add_flags;

	// Multiplier signals
	logic [7:0] mul_a;
	logic [7:0] mul_b;
	logic [7:0] mul_result;
	logic [3:0] mul_flags;

	int pass_count;
	int fail_count;

	// Units under test (both are purely combinational)
	FPAdd u_add
	(	.a(add_a), .b(add_b),
		.result(add_result), .flags(add_flags)) ;

	FPMult u_mult
	(	.a(mul_a), .b(mul_b),
		.result(mul_result), .flags(mul_flags)) ;

	// Apply one adder test and compare against the expected result and flags
	task automatic check_add(
		input logic [7:0] a,
		input logic [7:0] b,
		input logic [7:0] exp_result,
		input logic [3:0] exp_flags,
		input string name
	);
		begin
			add_a = a;
			add_b = b;
			#10;
			if (add_result === exp_result && add_flags === exp_flags) begin
				pass_count = pass_count + 1;
				$display("PASS  ADD  %s : %h + %h = %h  flags=%b", name, a, b, add_result, add_flags);
			end else begin
				fail_count = fail_count + 1;
				$display("FAIL  ADD  %s : %h + %h = %h  flags=%b  (expected %h flags=%b)",
					name, a, b, add_result, add_flags, exp_result, exp_flags);
			end
		end
	endtask

	// Apply one multiplier test and compare against the expected result and flags
	task automatic check_mul(
		input logic [7:0] a,
		input logic [7:0] b,
		input logic [7:0] exp_result,
		input logic [3:0] exp_flags,
		input string name
	);
		begin
			mul_a = a;
			mul_b = b;
			#10;
			if (mul_result === exp_result && mul_flags === exp_flags) begin
				pass_count = pass_count + 1;
				$display("PASS  MUL  %s : %h * %h = %h  flags=%b", name, a, b, mul_result, mul_flags);
			end else begin
				fail_count = fail_count + 1;
				$display("FAIL  MUL  %s : %h * %h = %h  flags=%b  (expected %h flags=%b)",
					name, a, b, mul_result, mul_flags, exp_result, exp_flags);
			end
		end
	endtask

	initial begin
		pass_count = 0 ;
		fail_count = 0 ;
		add_a = 0 ; add_b = 0 ;
		mul_a = 0 ; mul_b = 0 ;

		$display("---------------- FP8 Adder ----------------") ;
		//         a      b      result  flags     description
		check_add(8'h30, 8'h38, 8'h44, 4'b0000, "two positives: 1.0 + 1.5 = 2.5") ;
		check_add(8'h48, 8'hB0, 8'h40, 4'b0000, "mixed signs: 3.0 + -1.0 = 2.0") ;
		check_add(8'h30, 8'hB0, 8'h00, 4'b0000, "cancellation: 1.0 + -1.0 = +0") ;
		check_add(8'h38, 8'h00, 8'h38, 4'b0000, "add zero: 1.5 + 0 = 1.5") ;
		check_add(8'h80, 8'h80, 8'h80, 4'b0000, "-0 + -0 = -0") ;
		check_add(8'h60, 8'h10, 8'h60, 4'b0001, "rounding tie to even: 8 + 0.25 = 8") ;
		check_add(8'h6F, 8'h6F, 8'h70, 4'b1001, "overflow: 15.5 + 15.5 = +Inf") ;
		check_add(8'h11, 8'h90, 8'h00, 4'b0101, "underflow: 0.265625 + -0.25 -> +0") ;
		check_add(8'h70, 8'h30, 8'h70, 4'b1000, "infinity: +Inf + 1.0 = +Inf") ;
		check_add(8'h70, 8'hF0, 8'h7F, 4'b1010, "invalid: +Inf + -Inf = NaN") ;
		check_add(8'h7F, 8'h30, 8'h7F, 4'b0010, "NaN propagation: NaN + 1.0") ;

		$display("---------------- FP8 Multiplier ----------------") ;
		//         a      b      result  flags     description
		check_mul(8'h38, 8'h40, 8'h48, 4'b0000, "two positives: 1.5 * 2.0 = 3.0") ;
		check_mul(8'hB8, 8'h40, 8'hC8, 4'b0000, "sign: -1.5 * 2.0 = -3.0") ;
		check_mul(8'h44, 8'h00, 8'h00, 4'b0000, "multiply by zero: 2.5 * 0 = +0") ;
		check_mul(8'hC4, 8'h00, 8'h80, 4'b0000, "signed zero: -2.5 * 0 = -0") ;
		check_mul(8'h32, 8'h32, 8'h34, 4'b0001, "rounding: 1.125 * 1.125 = 1.25") ;
		check_mul(8'h6F, 8'h40, 8'h70, 4'b1001, "overflow: 15.5 * 2.0 = +Inf") ;
		check_mul(8'h10, 8'h10, 8'h00, 4'b0101, "underflow: 0.25 * 0.25 = +0") ;
		check_mul(8'h70, 8'h40, 8'h70, 4'b1000, "infinity: +Inf * 2.0 = +Inf") ;
		check_mul(8'h70, 8'h00, 8'h7F, 4'b1010, "invalid: +Inf * 0 = NaN") ;
		check_mul(8'h7F, 8'h30, 8'h7F, 4'b0010, "NaN propagation: NaN * 1.0") ;

		$display("------------------------------------------------") ;
		$display("Tests passed: %0d   Tests failed: %0d", pass_count, fail_count) ;
		if (fail_count == 0)
			$display("ALL TESTS PASSED") ;
		$finish ;
	end
	initial begin
	    $fsdbDumpfile("novas.fsdb");
	    $fsdbDumpvars(0, "+mda");
    end

endmodule

