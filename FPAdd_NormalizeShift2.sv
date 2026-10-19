//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_NormalizeShift2
//
// Description:	 Normalization shift stage 2, calculates post-normalization
//						 mantissa and exponent, as well as the bits used in rounding
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_NormalizeShift2 (
	input logic [8:0] PSSum,
	input logic [2:0] CExp,
	input logic [2:0] Shift,
	output logic [3:0] NormM,
	output logic [5:0] NormE,
	output logic ZeroSum,
	output logic R,
	output logic S,
	output logic FG
);
	
	// Calculate normalized exponent and mantissa, check for all-zero sum
	assign ZeroSum = ~|PSSum ;			// Check for all zero sum
	assign NormE = CExp - Shift + 1'b1 ;		// The sum's leading one is one place above the hidden bit
	assign NormM = PSSum[7:4] ;		// The new, normalized mantissa
	
	// Also need to compute sticky and round bits for the rounding stage
	assign FG = PSSum[3] ; 
	assign R = PSSum[2] ;
	assign S = |PSSum[1:0] ;
	
endmodule

