module ram (
    addr0, 
    d0, 
    we0, 
    q0,  
    addr1,
    d1,
    we1,
    q1,
    clk);

    input [`AWIDTH-1:0] addr0;
    input [`MASK_WIDTH*`DWIDTH-1:0] d0;
    input [`MASK_WIDTH-1:0] we0;
    output reg [`MASK_WIDTH*`DWIDTH-1:0] q0;
    input [`AWIDTH-1:0] addr1;
    input [`MASK_WIDTH*`DWIDTH-1:0] d1;
    input [`MASK_WIDTH-1:0] we1;
    output reg [`MASK_WIDTH*`DWIDTH-1:0] q1;
    
    input clk;

    reg [31:0] ram[((1<<`AWIDTH)-1):0];

    always @(posedge clk)  
    begin 
        if (|we0 == 1'b1) 
        begin
            ram[addr0] <= d0;
        end
        q0 <= ram[addr0];
    end
        
    always @(posedge clk)  
    begin
        if(|we1 == 1'b1) 
        begin
            ram[addr1] <= d1;
        end
        q1 <= ram[addr1];
    end
    
endmodule
