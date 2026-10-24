//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPMult_NormalizeModule
//
//////////////////////////////////////////////////////////////////////////////////

module FPMult_NormalizeModule (
	input logic [3:0] NormM,
	input logic [3:0] NormE,
	output logic [5:0] RoundE,
	output logic [5:0] RoundEP,
	output logic [4:0] RoundM,
	output logic [4:0] RoundMP
);

	assign RoundE = NormE - 3 ;						// Remove the double bias
	assign RoundEP = NormE - 2 ;
	assign RoundM = NormM ;
	assign RoundMP = NormM + 1 ;

endmodule
