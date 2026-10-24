//////////////////////////////////////////////////////////////////////////////////
//
// Create Date:    17:14:54 09/20/2012
// Module Name:    FPMult_RoundModule
//
//////////////////////////////////////////////////////////////////////////////////


module FPMult_RoundModule (
	input logic [4:0] RoundM,
	input logic [4:0] RoundMP,
	input logic [5:0] RoundE,
	input logic [5:0] RoundEP,
	input logic Sp,
	input logic GRS,
	input logic Inexact,
	output logic [7:0] Z,
	output logic [3:0] Flags
);
	logic [5:0] FinalE;
	logic [3:0] FinalM;
	logic [4:0] PreShiftM;
	logic Overflow, Underflow;

	assign PreShiftM = GRS ? RoundMP : RoundM ;	// Round up if R and (L or S)

	// Post rounding normalization (potential one bit shift> use shifted mantissa if there is overflow)
	assign FinalM = (PreShiftM[4] ? {1'b0, PreShiftM[3:1]} : PreShiftM[3:0]) ;

	assign FinalE = (PreShiftM[4] ? RoundEP : RoundE) ; // Increment exponent if a shift was done

	// Too small to represent as a normal number: flush to a signed zero
	assign Underflow = FinalE[5] | ~|FinalE ;

	// Too large to represent: saturate to a signed infinity
	assign Overflow = ~FinalE[5] & (FinalE[4:0] >= 5'd7) ;

	assign Z = Underflow ? {Sp, 7'b0000000} :
	           Overflow  ? {Sp, 3'b111, 4'b0000} : {Sp, FinalE[2:0], FinalM[3:0]} ;   // Putting the pieces together

	// Flags: {Overflow, Underflow, Invalid, Inexact} (special inputs are handled in FPMult)
	assign Flags = {Overflow, Underflow, 1'b0, (Inexact | Overflow | Underflow)} ;

endmodule
