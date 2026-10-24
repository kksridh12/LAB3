//////////////////////////////////////////////////////////////////////////////////
//
// Create Date:    08:40:21 09/19/2012
// Module Name:    FPMult
//
// FP8 (E3M4) version: [7] sign, [6:4] exponent (bias 3), [3:0] mantissa
// Single Cycle Combinational Multiplier
//
//////////////////////////////////////////////////////////////////////////////////


module FPMult (
	input logic [7:0] a,
	input logic [7:0] b,
	output logic [7:0] result,
	output logic [3:0] flags
);
	logic [7:0] Z_int, Mp;
	logic [3:0] Flags_int, NormM, NormE;
	logic [4:0] InputExc, RoundM, RoundMP;
	logic [5:0] RoundE, RoundEP;
	logic [2:0] Ea, Eb;
	logic Sa, Sb, Sp, GRS, Inexact;

	// Prepare the operands and check for exceptions
	FPMult_PrepModule PrepModule(.a(a), .b(b), .Sa(Sa), .Sb(Sb), .Ea(Ea), .Eb(Eb), .Mp(Mp), .InputExc(InputExc));

	// Perform (unsigned) mantissa multiplication
	FPMult_ExecuteModule ExecuteModule(.a(a[3:0]), .b(b[1:0]), .MpC(Mp), .Ea(Ea), .Eb(Eb), .Sa(Sa), .Sb(Sb), .Sp(Sp), .NormE(NormE), .NormM(NormM), .GRS(GRS), .Inexact(Inexact));

	// Remove the exponent bias and precompute the round-up candidate
	FPMult_NormalizeModule NormalizeModule(.NormM(NormM), .NormE(NormE), .RoundE(RoundE), .RoundEP(RoundEP), .RoundM(RoundM), .RoundMP(RoundMP));

	// Round result and if necessary, perform a second (post-rounding) normalization step
	FPMult_RoundModule RoundModule(.RoundM(RoundM), .RoundMP(RoundMP), .RoundE(RoundE), .RoundEP(RoundEP), .Sp(Sp), .GRS(GRS), .Inexact(Inexact), .Z(Z_int), .Flags(Flags_int));

	// Special inputs: an all-zero exponent is treated as zero (subnormals flushed to zero)
	logic AZero, BZero, AnyZero, AnyInf, AnyNaN, Special;
	logic [7:0] SpecialRes;
	logic [3:0] SpecialFlags;

	assign AZero = ~|a[6:4] ;
	assign BZero = ~|b[6:4] ;
	assign AnyZero = AZero | BZero ;
	assign AnyInf = InputExc[1] | InputExc[0] ;
	assign AnyNaN = InputExc[3] | InputExc[2] ;
	assign Special = AnyZero | InputExc[4] ;

	// NaN propagates, 0 * Inf = NaN, Inf * x = signed Inf, 0 * x = signed zero
	assign SpecialRes = InputExc[3] ? a :
	                    InputExc[2] ? b :
	                    (AnyInf & AnyZero) ? 8'h7F :
	                    AnyInf ? {Sp, 3'b111, 4'b0000} : {Sp, 7'b0000000} ;

	// Same convention as FPAddSub: Inf inputs set Overflow, NaN inputs and 0 * Inf set Invalid
	assign SpecialFlags = {AnyInf, 1'b0, (AnyNaN | (AnyInf & AnyZero)), 1'b0} ;

	assign result = Special ? SpecialRes : Z_int ;
	assign flags = Special ? SpecialFlags : Flags_int ;	// {Overflow, Underflow, Invalid, Inexact}
endmodule

