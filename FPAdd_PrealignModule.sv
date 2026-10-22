//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    	FPAdd_PrealignModule
//
// Description:	 	The pre-alignment module is responsible for taking the inputs
//					apart and checking the parts for exceptions.
//					The exponent difference is also calculated in this module.
//
//////////////////////////////////////////////////////////////////////////////////


module FPAdd_PrealignModule (
	input logic [7:0] A,
	input logic [7:0] B,
	output logic Sa,
	output logic Sb,
	output logic [5:0] ShiftDet,
	output logic [4:0] InputExc,
	output logic [6:0] Aout,
	output logic [6:0] Bout
);
	logic ANaN, BNaN, AInf, BInf;
	logic [2:0] DAB, DBA;
	
	assign ANaN = &(A[6:4]) & |(A[3:0]) ;			// All one exponent and not all zero mantissa - NaN
	assign BNaN = &(B[6:4]) & |(B[3:0]) ;			// All one exponent and not all zero mantissa - NaN
	assign AInf = &(A[6:4]) & ~|(A[3:0]) ;			// All one exponent and all zero mantissa - Infinity
	assign BInf = &(B[6:4]) & ~|(B[3:0]) ;			// All one exponent and all zero mantissa - Infinity
	
	// Put all flags into exception vector
	assign InputExc = {(ANaN | BNaN | AInf | BInf), ANaN, BNaN, AInf, BInf} ;
	
	assign DAB = (A[6:4] - B[6:4]) ;
	assign DBA = (B[6:4] - A[6:4]) ;
	
	assign Sa = A[7] ;									// A's sign bit
	assign Sb = B[7] ;									// B's sign	bit
	assign ShiftDet = {DBA[2:0], DAB[2:0]} ;		// Shift data
	assign Aout = A[6:0] ;
	assign Bout = B[6:0] ;
endmodule
