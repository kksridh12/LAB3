//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_ExceptionModule
//
// Description:	 Check the final result for exception conditions and set
//						 flags accordingly.
//
//////////////////////////////////////////////////////////////////////////////////



module FPAdd_ExceptionModule (
	input logic EUF, // Result underflowed and was flushed to zero
	input logic G, // Guard bit
	input logic R, // Round bit
	input logic S, // Sticky bit
	input logic [4:0] InputExc, // Exceptions in inputs A and B
	input logic EOF, // Result overflowed and was saturated to infinity
	output logic [3:0] Flags // Exception flags
);
	logic Overflow, Underflow, Invalid, Inexact;
	
	// Exception flags
	
	// Result is too big to be represented
	assign Overflow = EOF | InputExc[1] | InputExc[0] ;
	
	// Result is too small to be represented
	assign Underflow = EUF ;
	
	// Invalid inputs (NaN inputs; +Inf + -Inf is handled in FPAddSub)
	assign Invalid = InputExc[3] | InputExc[2] ;
	
	// Inexact answer due to rounding, overflow or underflow
	assign Inexact = (G | R | S) | Overflow | Underflow;
	
	// Collect exception flags	
	assign Flags = {Overflow, Underflow, Invalid, Inexact} ; 

endmodule

