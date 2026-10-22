//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    	FPAdd_AlignModule
//
// Description:	 	The alignment module determines the larger input operand and
//					sets the mantissas, shift and common exponent accordingly.
//
//////////////////////////////////////////////////////////////////////////////////

module FPAdd_AlignModule (
	input logic [6:0] A, // Input A without sign
	input logic [6:0] B, // Input B without sign
	input logic [5:0] ShiftDet,
	output logic [2:0] CExp, // Common exponent
	output logic MaxAB, // Larger operand (0/A, 1/B)
	output logic [2:0] Shift, // Alignment shift amount
	output logic [3:0] Mmin, // Smaller mantissa
	output logic [3:0] Mmax // Larger mantissa
);
	
	assign MaxAB = (A[6:0] < B[6:0]) ;	
	
	// Determine final shift value (exponent difference, at most 7)
	assign Shift = MaxAB ? ShiftDet[5:3] : ShiftDet[2:0] ;
	
	// Take out smaller mantissa
	assign Mmin = MaxAB ? A[3:0] : B[3:0] ; 
	
	// Take out larger mantissa	
	assign Mmax = MaxAB ? B[3:0]: A[3:0] ;	
	
	// Common exponent
	assign CExp = (MaxAB ? B[6:4] : A[6:4]) ;		
	
endmodule

