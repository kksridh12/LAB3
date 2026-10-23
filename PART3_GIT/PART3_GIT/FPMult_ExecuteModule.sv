//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPMult_ExecuteModule
//
//////////////////////////////////////////////////////////////////////////////////


module FPMult_ExecuteModule (
	input logic [3:0] a,
	input logic [1:0] b,
	input logic [7:0] MpC,
	input logic [2:0] Ea,
	input logic [2:0] Eb,
	input logic Sa,
	input logic Sb,
	output logic Sp,
	output logic [3:0] NormE,
	output logic [3:0] NormM,
	output logic GRS,
	output logic Inexact
);
	logic [9:0] Mp;

	assign Sp = (Sa ^ Sb) ;												// Equal signs give a positive product

	assign Mp = (MpC<<2) + ({1'b1, a[3:0]}*{3'b000, b[1:0]}) ;

	assign NormM = (Mp[9] ? Mp[8:5] : Mp[7:4]); 					// Check for overflow
	assign NormE = (Ea + Eb + Mp[9]);									// If so, increment exponent

	// Round to nearest even: round up if R & (L | S)
	assign GRS = Mp[9] ? (Mp[4] & (Mp[5] | (|Mp[3:0]))) :
	                     (Mp[3] & (Mp[4] | (|Mp[2:0]))) ;

	// Product is inexact if any bit below the kept mantissa is set
	assign Inexact = Mp[9] ? (|Mp[4:0]) : (|Mp[3:0]) ;

endmodule

