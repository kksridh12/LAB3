//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPMult_PrepModule
//
// Description:	 The pre-alignment module is responsible for taking the inputs
//							apart, checking the parts for exceptions and feeding them to
//							the alignment module.
//
//////////////////////////////////////////////////////////////////////////////////


module FPMult_PrepModule (
	input logic [7:0] a,
	input logic [7:0] b,
	output logic Sa,
	output logic Sb,
	output logic [2:0] Ea,
	output logic [2:0] Eb,
	output logic [7:0] Mp,
	output logic [4:0] InputExc
);
	logic ANaN, BNaN, AInf, BInf;


	assign ANaN = &(a[6:4]) & |(a[3:0]) ;		// All one exponent and not all zero mantissa - NaN
	assign BNaN = &(b[6:4]) & |(b[3:0]) ;		// All one exponent and not all zero mantissa - NaN
	assign AInf = &(a[6:4]) & ~|(a[3:0]) ;		// All one exponent and all zero mantissa - Infinity
	assign BInf = &(b[6:4]) & ~|(b[3:0]) ;		// All one exponent and all zero mantissa - Infinity

	// Check for any exceptions and put all flags into exception vector
	assign InputExc = {(ANaN | BNaN | AInf | BInf), ANaN, BNaN, AInf, BInf} ;

	// Take input numbers apart
	assign Sa = a[7] ;							// A's sign
	assign Sb = b[7] ;							// B's sign
	assign Ea = (a[6:4]);						// Store A's exponent in Ea
	assign Eb = (b[6:4]);						// Store B's exponent in Eb

	// Upper partial product: {1,Ma} * {1,Mb[3:2]}; lower part is added in Execute
	assign Mp = ({1'b1, a[3:0]}*{1'b1, b[3:2]}) ;

endmodule

