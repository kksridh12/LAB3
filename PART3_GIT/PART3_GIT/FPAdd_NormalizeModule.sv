//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_NormalizeModule
//
// Description:	 Determine the normalization shift amount and perform 4-shift
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_NormalizeModule (
	input logic [8:0] Sum,
	output logic [8:0] Mmin,
	output logic [2:0] Shift
);
	
	// Determine normalization shift amount by finding leading one
	// (a non-zero sum always has its leading one in Sum[8:2])
	assign Shift =  ( 
		Sum[8] ? 3'b000 :	 
		Sum[7] ? 3'b001 : 
		Sum[6] ? 3'b010 : 
		Sum[5] ? 3'b011 : 
		Sum[4] ? 3'b100 : 
		Sum[3] ? 3'b101 : 
		Sum[2] ? 3'b110 : 3'b111
	);
	
	// Shift by 4?
	assign Mmin = Shift[2] ? {Sum[4:0], 4'b0000} : Sum ;

endmodule

