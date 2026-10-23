`timescale 1ns/1ps







module matmul_8x8 (







    input logic clk,



    input logic reset,



    input logic pe_reset,



    input logic start_mat_mul,







    output logic done_mat_mul,







    input logic [`AWIDTH-1:0] address_mat_a,



    input logic [`AWIDTH-1:0] address_mat_b,



    input logic [`AWIDTH-1:0] address_mat_c,







    input logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a,



    input logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_b,



    input logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c,







    // Two A RAM banks



    input logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_top,



    input logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_bottom,







    // Two B RAM banks



    input logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_left,



    input logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_right,







    // Two C output streams



    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_left,



    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_right,







    output logic [`AWIDTH-1:0] a_addr_top,



    output logic [`AWIDTH-1:0] a_addr_bottom,







    output logic [`AWIDTH-1:0] b_addr_left,



    output logic [`AWIDTH-1:0] b_addr_right,







    output logic [`AWIDTH-1:0] c_addr_left,



    output logic [`AWIDTH-1:0] c_addr_right,







    output logic c_data_available_left,



    output logic c_data_available_right,







    output logic [`FWIDTH-1:0] flags



);











    //=========================================================



    // Inter-block systolic connections



    //



    // A:



    //



    // block_00



    //    |



    //    v



    // block_10



    //



    // block_01



    //    |



    //    v



    // block_11



    //



    // B:



    //



    // block_00 ---> block_01



    //



    // block_10 ---> block_11



    //=========================================================







    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_00_to_10;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_01_to_11;







    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_00_to_01;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_10_to_11;











    //=========================================================



    // C outputs



    //=========================================================







    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_00_out;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_01_out;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_10_out;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_11_out;











    //=========================================================



    // Boundary outputs not used



    //=========================================================







    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_10_unused;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_11_unused;







    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_01_unused;



    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_11_unused;











    //=========================================================



    // Unused address outputs



    //=========================================================







    logic [`AWIDTH-1:0] a_addr_01_unused;



    logic [`AWIDTH-1:0] a_addr_10_unused;



    logic [`AWIDTH-1:0] a_addr_11_unused;







    logic [`AWIDTH-1:0] b_addr_01_unused;



    logic [`AWIDTH-1:0] b_addr_10_unused;



    logic [`AWIDTH-1:0] b_addr_11_unused;







    logic [`AWIDTH-1:0] c_addr_00_unused;



    logic [`AWIDTH-1:0] c_addr_10_unused;











    //=========================================================



    // C valid signals



    //=========================================================







    logic c_avail_00;



    logic c_avail_01;



    logic c_avail_10;



    logic c_avail_11;











    //=========================================================



    // Local done signals



    //=========================================================







    logic done_00;



    logic done_01;



    logic done_10;



    logic done_11;











    //=========================================================



    // FP8 flags



    //=========================================================







    logic [`FWIDTH-1:0] flags_00;



    logic [`FWIDTH-1:0] flags_01;



    logic [`FWIDTH-1:0] flags_10;



    logic [`FWIDTH-1:0] flags_11;











    //=========================================================



    // BLOCK 00



    //



    // Position:



    // a_loc = 0



    // b_loc = 0



    //



    // Top row + left column.



    //



    // A comes from A RAM bank 0.



    // B comes from B RAM bank 0.



    //=========================================================







    matmul_4x4_systolic block_00 (







        .clk(clk),



        .reset(reset),



        .pe_reset(pe_reset),







        .start_mat_mul(start_mat_mul),



        .done_mat_mul(done_00),







        .address_mat_a(address_mat_a),



        .address_mat_b(address_mat_b),



        .address_mat_c(address_mat_c),







        .address_stride_a(address_stride_a),



        .address_stride_b(address_stride_b),



        .address_stride_c(address_stride_c),







        .a_data(a_data_top),



        .b_data(b_data_left),







        .a_data_in('0),



        .b_data_in('0),







        .c_data_in('0),



        .c_data_out(c_00_out),







        .a_data_out(a_00_to_10),



        .b_data_out(b_00_to_01),







        .a_addr(a_addr_top),



        .b_addr(b_addr_left),







        .c_addr(c_addr_00_unused),







        .c_data_available(c_avail_00),







        .validity_mask_a_rows(4'b1111),



        .validity_mask_a_cols_b_rows(4'b1111),



        .validity_mask_b_cols(4'b1111),







        .final_mat_mul_size(8'd8),







        .a_loc(8'd0),



        .b_loc(8'd0),







        .flags(flags_00)



    );











    //=========================================================



    // BLOCK 01



    //



    // Position:



    // a_loc = 1



    // b_loc = 0



    //



    // Top row + right column.



    //



    // IMPORTANT:



    //



    // Because b_loc == 0, A comes directly from memory.



    // This block must therefore use A RAM BANK 1.



    //



    // Because a_loc != 0, B comes from block_00.



    //=========================================================







    matmul_4x4_systolic block_01 (







        .clk(clk),



        .reset(reset),



        .pe_reset(pe_reset),







        .start_mat_mul(start_mat_mul),



        .done_mat_mul(done_01),







        .address_mat_a(address_mat_a),



        .address_mat_b(address_mat_b),



        .address_mat_c(address_mat_c),







        .address_stride_a(address_stride_a),



        .address_stride_b(address_stride_b),



        .address_stride_c(address_stride_c),







        // SECOND A RAM BANK



        .a_data(a_data_bottom),







        // Direct B data is not selected because a_loc != 0.



        .b_data(b_data_right),







        .a_data_in('0),







        // B forwarded from block_00.



        .b_data_in(b_00_to_01),







        // C serialization



        .c_data_in(c_00_out),



        .c_data_out(c_01_out),







        // A continues downward to block_11.



        .a_data_out(a_01_to_11),







        .b_data_out(b_01_unused),







        .a_addr(a_addr_bottom),



        .b_addr(b_addr_01_unused),







        .c_addr(c_addr_right),







        .c_data_available(c_avail_01),







        .validity_mask_a_rows(4'b1111),



        .validity_mask_a_cols_b_rows(4'b1111),



        .validity_mask_b_cols(4'b1111),







        .final_mat_mul_size(8'd8),







        .a_loc(8'd1),



        .b_loc(8'd0),







        .flags(flags_01)



    );











    //=========================================================



    // BLOCK 10



    //



    // Position:



    // a_loc = 0



    // b_loc = 1



    //



    // Bottom row + left column.



    //



    // Because b_loc != 0, A comes from block_00.



    //



    // Because a_loc == 0, B comes directly from memory.



    // This block therefore uses B RAM BANK 1.



    //=========================================================







    matmul_4x4_systolic block_10 (







        .clk(clk),



        .reset(reset),



        .pe_reset(pe_reset),







        .start_mat_mul(start_mat_mul),



        .done_mat_mul(done_10),







        .address_mat_a(address_mat_a),



        .address_mat_b(address_mat_b),



        .address_mat_c(address_mat_c),







        .address_stride_a(address_stride_a),



        .address_stride_b(address_stride_b),



        .address_stride_c(address_stride_c),







        // Direct A data is not selected because b_loc != 0.



        .a_data(a_data_bottom),







        // SECOND B RAM BANK



        .b_data(b_data_right),







        // A forwarded from block_00.



        .a_data_in(a_00_to_10),







        .b_data_in('0),







        .c_data_in('0),



        .c_data_out(c_10_out),







        .a_data_out(a_10_unused),







        // B continues to block_11.



        .b_data_out(b_10_to_11),







        .a_addr(a_addr_10_unused),



        .b_addr(b_addr_right),







        .c_addr(c_addr_10_unused),







        .c_data_available(c_avail_10),







        .validity_mask_a_rows(4'b1111),



        .validity_mask_a_cols_b_rows(4'b1111),



        .validity_mask_b_cols(4'b1111),







        .final_mat_mul_size(8'd8),







        .a_loc(8'd0),



        .b_loc(8'd1),







        .flags(flags_10)



    );











    //=========================================================



    // BLOCK 11



    //



    // Position:



    // a_loc = 1



    // b_loc = 1



    //



    // Bottom row + right column.



    //



    // A comes from block_01.



    // B comes from block_10.



    //=========================================================







    matmul_4x4_systolic block_11 (







        .clk(clk),



        .reset(reset),



        .pe_reset(pe_reset),







        .start_mat_mul(start_mat_mul),



        .done_mat_mul(done_11),







        .address_mat_a(address_mat_a),



        .address_mat_b(address_mat_b),



        .address_mat_c(address_mat_c),







        .address_stride_a(address_stride_a),



        .address_stride_b(address_stride_b),



        .address_stride_c(address_stride_c),







        // Direct RAM inputs are unused for this block.



        .a_data(a_data_bottom),



        .b_data(b_data_right),







        // A from block_01.



        .a_data_in(a_01_to_11),







        // B from block_10.



        .b_data_in(b_10_to_11),







        // Bottom C stream serialization.



        .c_data_in(c_10_out),



        .c_data_out(c_11_out),







        .a_data_out(a_11_unused),



        .b_data_out(b_11_unused),







        .a_addr(a_addr_11_unused),



        .b_addr(b_addr_11_unused),







        .c_addr(c_addr_left),







        .c_data_available(c_avail_11),







        .validity_mask_a_rows(4'b1111),



        .validity_mask_a_cols_b_rows(4'b1111),



        .validity_mask_b_cols(4'b1111),







        .final_mat_mul_size(8'd8),







        .a_loc(8'd1),



        .b_loc(8'd1),







        .flags(flags_11)



    );











    //=========================================================



    // C outputs



    //=========================================================







    assign c_data_right = c_01_out;



    assign c_data_left  = c_11_out;







    assign c_data_available_right = c_avail_01;



    assign c_data_available_left  = c_avail_11;











    //=========================================================



    // Combine FP8 flags



    //=========================================================







    always_comb begin







        flags =



            flags_00 |



            flags_01 |



            flags_10 |



            flags_11;







    end











    //=========================================================



    // 8x8 completion timing



    //



    // The local 4x4 done timing occurs too early for the



    // complete 8x8 result stream. Keep the tiled operation



    // active long enough for capture/output.



    //=========================================================







    logic [7:0] wrapper_clk_cnt;







    always_ff @(posedge clk) begin







        if (reset || !start_mat_mul) begin







            wrapper_clk_cnt <= 8'd0;



            done_mat_mul    <= 1'b0;







        end



        else begin







            if (wrapper_clk_cnt < 8'd40)



                wrapper_clk_cnt <= wrapper_clk_cnt + 1'b1;







            if (wrapper_clk_cnt == 8'd38)



                done_mat_mul <= 1'b1;



            else



                done_mat_mul <= 1'b0;







        end







    end



endmodule


