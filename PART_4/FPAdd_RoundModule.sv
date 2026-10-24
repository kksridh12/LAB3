//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_RoundModule
//
// Description:	 Performs 'Round to nearest, tie to even'-rounding on the
//						 normalized mantissa according to the G, R, S bits. Calculates
//						 final result and checks for exponent overflow.
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_RoundModule (
	input logic ZeroSum,
	input logic [5:0] NormE,
	input logic [3:0] NormM,
	input logic R,
	input logic S,
	input logic G,
	input logic PSgn,
	output logic [7:0] Z,
	output logic EOF,
	output logic EUF
);
	logic [4:0] RoundUpM;
	logic [3:0] RoundM;
	logic [5:0] RoundE;
	logic RoundUp, RoundOF, FSgn;

	// The cases where we need to round upwards (= adding one) in Round to nearest, tie to even
	assign RoundUp = (G & ((R | S) | NormM[0])) ;

	// Note that in the other cases (rounding down), the sum is already 'rounded'
	assign RoundUpM = (NormM + 1) ;								// The sum, rounded up by 1
	assign RoundM = (RoundUp ? RoundUpM[3:0] : NormM) ; 	// Compute final mantissa
	assign RoundOF = RoundUp & RoundUpM[4] ; 				// Check for overflow when rounding up

	// Calculate post-rounding exponent (add 1 to compensate for rounding overflow)
	assign RoundE = ZeroSum ? 6'b000000 : (NormE + RoundOF) ; 							// Final exponent

	// An exact zero sum is +0 in round to nearest; otherwise take the larger operand's sign
	assign FSgn = ZeroSum ? 1'b0 : PSgn ;

	// Assign final result
	// Underflow flushes to a signed zero, overflow saturates to a signed infinity
	assign Z = EUF ? {FSgn, 7'b0000000} :
	           EOF ? {FSgn, 3'b111, 4'b0000} : {FSgn, RoundE[2:0], RoundM[3:0]} ;

	// Indicate exponent underflow (too small for a normal number, flushed to a signed zero)
	assign EUF = ~ZeroSum & (RoundE[5] | ~|RoundE) ;

	// Indicate exponent overflow (exponent 7 is reserved for Inf/NaN)
	assign EOF = ~RoundE[5] & (RoundE[4:0] >= 5'd7) ;

endmodule

