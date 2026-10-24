//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_AlignShift1
//
// Description:	 Alignment shift stage 1, performs 0|4 shift
//						 Output format: [7] hidden 1, [6:3] mantissa, [2:1] guard/round, [0] sticky
//
//////////////////////////////////////////////////////////////////////////////////
module FPAdd_AlignShift1 (
	input logic [3:0] MminP, // Smaller mantissa
	input logic Shift, // Shift by 4?
	output logic [7:0] Mmin // The smaller mantissa after 0|4 shift
);
	logic [7:0] Lvl1;
	
	assign Lvl1 = {1'b1, MminP, 3'b000} ;		// Append hidden 1 and guard/round/sticky space
	
	// Shift by 4? Bits shifted out are collected in the sticky bit
	assign Mmin = Shift ? {4'b0000, Lvl1[7:5], Lvl1[4] | (|Lvl1[3:0])} : Lvl1 ;
	
endmodule

