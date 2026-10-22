//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd
//
// Description:	 Top Module for an 8-bit (FP8 E3M4) floating point adder/subtractor.
//						 Format: [7] sign, [6:4] exponent (bias 3), [3:0] mantissa.
//						 Supports only the default rounding mode.
//						 Combinational: no pipeline registers, the result is
//						 available in the same cycle.
//
//	Inputs:
//				a (8 bits)			: FP8 E3M4 floating point number
//				b (8 bits)			: FP8 E3M4 floating point number
//
//
// Outputs:
//				result (8 bits)	: Result of the operation, in FP8 E3M4 format
//				flags	 (4 bits)	: Flags indicating exceptions:
//											Bit 3: Overflow
//											Bit 2: Underflow
//											Bit 1: Invalid/NaN
//											Bit 0: Inexact
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd (
	input logic [7:0] a,
	input logic [7:0] b,
	output logic [7:0] result,
	output logic [3:0] flags
);

	// Internal wires between modules
	logic [6:0] Aout, Bout;
	logic Sa, Sb, MaxAB;
	logic [2:0] CExp, Shift_A, Shift_N;
	logic [3:0] Mmax, MminP, NormM, flags_int;
	logic [4:0] InputExc;
	logic [5:0] ShiftDet, NormE;
	logic [7:0] MminS, Mmin, result_int;
	logic [8:0] Sum, SumS_1, SumS_2;
	logic PSgn, ZeroSum, R, S, FG, EOF, EUF;

	// Prepare the operands for alignment and check for exceptions
	FPAdd_PrealignModule PrealignModule (
		.A(a), .B(b), .Sa(Sa), .Sb(Sb), .ShiftDet(ShiftDet),
		.InputExc(InputExc), .Aout(Aout), .Bout(Bout)
	);

	// Determine the larger operand, common exponent and alignment shift
	FPAdd_AlignModule AlignModule (
		.A(Aout), .B(Bout), .ShiftDet(ShiftDet), .CExp(CExp), .MaxAB(MaxAB),
		.Shift(Shift_A), .Mmin(MminP), .Mmax(Mmax)
	);

	// Alignment Shift Stage 1
	FPAdd_AlignShift1 AlignShift1 (
		.MminP(MminP), .Shift(Shift_A[2]), .Mmin(MminS)
	);

	// Alignment Shift Stage 2
	FPAdd_AlignShift2 AlignShift2 (
		.MminP(MminS), .Shift(Shift_A[1:0]), .Mmin(Mmin)
	);

	// Perform mantissa addition
	FPAdd_ExecutionModule ExecutionModule (
		.Mmax(Mmax), .Mmin(Mmin), .Sa(Sa), .Sb(Sb), .MaxAB(MaxAB),
		.Sum(Sum), .PSgn(PSgn)
	);

	// Prepare normalization of result
	FPAdd_NormalizeModule NormalizeModule (
		.Sum(Sum), .Mmin(SumS_1), .Shift(Shift_N)
	);

	// Normalization Shift Stage 1
	FPAdd_NormalizeShift1 NormalizeShift1 (
		.MminP(SumS_1), .Shift(Shift_N[1:0]), .Mmin(SumS_2)
	);

	// Normalization Shift Stage 2 and final guard, sticky and round bits
	FPAdd_NormalizeShift2 NormalizeShift2 (
		.PSSum(SumS_2), .CExp(CExp), .Shift(Shift_N), .NormM(NormM),
		.NormE(NormE), .ZeroSum(ZeroSum), .R(R), .S(S), .FG(FG)
	);

	// Round and put result together
	FPAdd_RoundModule RoundModule (
		.ZeroSum(ZeroSum), .NormE(NormE), .NormM(NormM), .R(R), .S(S),
		.G(FG), .PSgn(PSgn), .Z(result_int), .EOF(EOF), .EUF(EUF)
	);

	// Check for exceptions
	FPAdd_ExceptionModule Exceptionmodule (
		.EUF(EUF), .G(FG), .R(R), .S(S), .InputExc(InputExc), .EOF(EOF),
		.Flags(flags_int)
	);

	// Special inputs: an all-zero exponent is treated as zero (subnormals flushed to zero)
	logic AZero, BZero, AnyInf, AnyNaN, InfDiff, Special;
	logic [7:0] SpecialRes;
	logic [3:0] SpecialFlags;

	assign AZero = ~|a[6:4] ;
	assign BZero = ~|b[6:4] ;
	assign AnyInf = InputExc[1] | InputExc[0] ;
	assign AnyNaN = InputExc[3] | InputExc[2] ;
	assign InfDiff = InputExc[1] & InputExc[0] & (a[7] ^ b[7]) ;
	assign Special = InputExc[4] | AZero | BZero ;

	// NaN propagates, +Inf + -Inf = NaN, Inf + x = Inf,
	// 0 + 0 is -0 only if both are negative, 0 + x = x, x + 0 = x
	assign SpecialRes = InputExc[3] ? a :
	                    InputExc[2] ? b :
	                    InfDiff ? 8'h7F :
	                    InputExc[1] ? a :
	                    InputExc[0] ? b :
	                    (AZero & BZero) ? {(a[7] & b[7]), 7'b0000000} :
	                    AZero ? b : a ;

	// Inf inputs set Overflow, NaN inputs and +Inf + -Inf set Invalid; results with a zero operand are exact
	assign SpecialFlags = {AnyInf, 1'b0, (AnyNaN | InfDiff), 1'b0} ;

	assign result = Special ? SpecialRes : result_int ;
	assign flags = Special ? SpecialFlags : flags_int ;

endmodule
