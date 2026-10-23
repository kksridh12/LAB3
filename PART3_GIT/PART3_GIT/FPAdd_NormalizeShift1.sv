//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_NormalizeShift1
//
// Description:	 Normalization shift stage 1, performs 3|2|1|0 shift
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_NormalizeShift1 (
	input logic [8:0] MminP,
	input logic [1:0] Shift,
	output logic [8:0] Mmin
);
	
	// Shift left {0 | 1 | 2 | 3} bits
	assign Mmin = MminP << Shift ;
	
endmodule

