//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:    FPAdd_AlignShift2
//
// Description:	 Alignment shift stage 2, performs 3|2|1 shift
//
//////////////////////////////////////////////////////////////////////////////////

module FPAdd_AlignShift2 (
	input logic [7:0] MminP, // Smaller mantissa after 0|4 shift
	input logic [1:0] Shift, // Shift amount
	output logic [7:0] Mmin // The smaller mantissa
);
	logic [7:0] Lvl2;
	
	// Shift {0 | 1 | 2 | 3} bits, bits shifted out are collected in the sticky bit
	always_comb begin
	  case (Shift[1:0])
			2'b00:  Lvl2 = MminP ;
			2'b01:  Lvl2 = {1'b0,   MminP[7:2], |MminP[1:0]} ;
			2'b10:  Lvl2 = {2'b00,  MminP[7:3], |MminP[2:0]} ;
			2'b11:  Lvl2 = {3'b000, MminP[7:4], |MminP[3:0]} ;
	  endcase
	end
	
	// Assign output
	assign Mmin = Lvl2;						// Take out smaller mantissa				

endmodule

