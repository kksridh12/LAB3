//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_ExecutionModule
//
// Description:	 Module that executes the addition or subtraction on mantissas.
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_ExecutionModule (
	input logic [3:0] Mmax,
	input logic [7:0] Mmin,
	input logic Sa,
	input logic Sb,
	input logic MaxAB,
	output logic [8:0] Sum,
	output logic PSgn
);

	// Equal signs add the magnitudes, opposite signs subtract the smaller from the larger
	assign Sum = (Sa^Sb) ? ({2'b01, Mmax, 3'b000} - {1'b0, Mmin}) : ({2'b01, Mmax, 3'b000} + {1'b0, Mmin}) ;
	
	// The result takes the sign of the larger operand
	assign PSgn = (MaxAB ? Sb : Sa) ;

endmodule

