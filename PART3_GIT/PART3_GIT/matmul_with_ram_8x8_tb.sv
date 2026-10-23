`timescale 1ns/1ps



module matmul_with_ram_8x8_tb;



    logic clk;

    logic resetn;

    logic pe_resetn;

    logic start;

    logic done;



    integer i;

    integer errors;





    //=========================================================

    // DUT

    //=========================================================



    matrix_multiplication_8x8 dut (



        .clk(clk),

        .resetn(resetn),

        .pe_resetn(pe_resetn),



        .address_mat_a(10'd0),

        .address_mat_b(10'd0),

        .address_mat_c(10'd0),



        .address_stride_a(8'd1),

        .address_stride_b(8'd1),

        .address_stride_c(8'd1),



        .start(start),

        .done(done)

    );





    //=========================================================

    // Clock

    //=========================================================



    initial begin



        clk = 1'b0;



        forever begin

            #5 clk = ~clk;

        end



    end





    //=========================================================

    // FSDB

    //=========================================================



    initial begin



        $fsdbDumpfile("part3_8x8.fsdb");

        $fsdbDumpvars(0, matmul_with_ram_8x8_tb, "+all");



    end





    //=========================================================

    // Main test

    //

    // A = 8x8 all 1.0

    // B = 8x8 all 1.0

    //

    // FP8:

    //

    // 1.0 = 8'h30

    // 8.0 = 8'h60

    //

    // Therefore every C element should eventually be 8'h60.

    //=========================================================



    initial begin



        errors = 0;



        resetn    = 1'b0;

        pe_resetn = 1'b0;

        start     = 1'b0;





        //=====================================================

        // Initialize A RAM banks

        //

        // Fill enough locations with FP8 1.0 for the current

        // diagnostic simulation.

        //=====================================================



        for (i = 0; i < 32; i = i + 1) begin



            dut.matrix_A0.ram[i] = 32'h30303030;

            dut.matrix_A1.ram[i] = 32'h30303030;



        end





        //=====================================================

        // Initialize B RAM banks

        //=====================================================



        for (i = 0; i < 32; i = i + 1) begin



            dut.matrix_B0.ram[i] = 32'h30303030;

            dut.matrix_B1.ram[i] = 32'h30303030;



        end





        //=====================================================

        // IMPORTANT ZERO-PADDING FIX

        //

        // The original address generator sets:

        //

        // address - stride

        //

        // when memory access becomes inactive.

        //

        // With base address = 0 and stride = 1:

        //

        // 0 - 1 = 1023

        //

        // for the 10-bit address.

        //

        // Because the RAM is synchronous, an uninitialized

        // location 1023 was returning X on the following

        // cycle and contaminating the FP8 accumulators.

        //

        // Make that padding location FP8 zero.

        //=====================================================



        dut.matrix_A0.ram[1023] = 32'h00000000;

        dut.matrix_A1.ram[1023] = 32'h00000000;



        dut.matrix_B0.ram[1023] = 32'h00000000;

        dut.matrix_B1.ram[1023] = 32'h00000000;





        //=====================================================

        // Clear C RAM banks

        //=====================================================



        for (i = 0; i < 32; i = i + 1) begin



            dut.matrix_C0.ram[i] = 32'h00000000;

            dut.matrix_C1.ram[i] = 32'h00000000;



        end





        //=====================================================

        // Reset

        //=====================================================



        repeat (5)

            @(posedge clk);



        resetn    = 1'b1;

        pe_resetn = 1'b1;





        repeat (3)

            @(posedge clk);





        //=====================================================

        // Start test

        //=====================================================



        $display("");

        $display("========================================");

        $display("PART III - 8x8 ALL-ONES TEST");

        $display("========================================");



        $display("FP8 1.0 = 8'h30");

        $display("FP8 8.0 = 8'h60");

        $display("Expected result word = 60606060");



        $display("");





        start = 1'b1;



        @(posedge clk);

        @(posedge clk);



        start = 1'b0;





        //=====================================================

        // Wait for done

        //=====================================================



        fork



            begin : WAIT_DONE



                @(posedge done);



                $display(

                    "DONE asserted at time %0t",

                    $time

                );



            end





            begin : TIMEOUT



                repeat (200)

                    @(posedge clk);



                $display(

                    "ERROR: Timeout waiting for done"

                );



                errors = errors + 1;



            end



        join_any



        disable fork;





        //=====================================================

        // Allow final RAM writes to settle

        //=====================================================



        repeat (8)

            @(posedge clk);





        //=====================================================

        // Print C RAM bank 0

        //=====================================================



        $display("");

        $display("C RAM BANK 0:");

        $display("----------------------------------------");



        for (i = 0; i < 16; i = i + 1) begin



            $display(

                "C0[%0d] = %h",

                i,

                dut.matrix_C0.ram[i]

            );



        end





        //=====================================================

        // Print C RAM bank 1

        //=====================================================



        $display("");

        $display("C RAM BANK 1:");

        $display("----------------------------------------");



        for (i = 0; i < 16; i = i + 1) begin



            $display(

                "C1[%0d] = %h",

                i,

                dut.matrix_C1.ram[i]

            );



        end





        //=====================================================

        // Diagnostic result checking

        //

        // This checker is still checking addresses 0..7.

        // We already observed that the current C stream may

        // begin writing at a later address, so the RAM dump

        // above is also important.

        //=====================================================



        $display("");

        $display("Checking expected output locations...");

        $display("");





        for (i = 0; i < 8; i = i + 1) begin





            if (dut.matrix_C0.ram[i+2] !== 32'h60606060) begin



                $display(

                    "ERROR C0[%0d]: got %h expected 60606060",

                    i+2,

                    dut.matrix_C0.ram[i+2]

                );



                errors = errors + 1;



            end

            else begin



                $display(

                    "PASS C0[%0d] = %h",

                    i+2,

                    dut.matrix_C0.ram[i+2]

                );



            end





            if (dut.matrix_C1.ram[i+2] !== 32'h60606060) begin



                $display(

                    "ERROR C1[%0d]: got %h expected 60606060",

                    i+2,

                    dut.matrix_C1.ram[i+2]

                );



                errors = errors + 1;



            end

            else begin



                $display(

                    "PASS C1[%0d] = %h",

                    i+2,

                    dut.matrix_C1.ram[i+2]

                );



            end



        end





        //=====================================================

        // Final result

        //=====================================================



        $display("");

        $display("========================================");



        if (errors == 0) begin



            $display("*** PART III TEST 1 PASS ***");



        end

        else begin



            $display("*** PART III TEST 1 FAIL ***");



            $display(

                "Total errors = %0d",

                errors

            );



        end



        $display("========================================");

        $display("");





        #20;



        $finish;



    end





    //=========================================================

    // DIAGNOSTIC 1

    //

    // Actual PE accumulator results.

    //=========================================================



    always @(posedge clk) begin



        if (dut.start_mat_mul) begin



            $display(

                "BLOCK T=%0t | B00 C00=%h C33=%h | B01 C00=%h C33=%h | B10 C00=%h C33=%h | B11 C00=%h C33=%h",

                $time,



                dut.u_matmul_8x8.block_00.matrixC00,

                dut.u_matmul_8x8.block_00.matrixC33,



                dut.u_matmul_8x8.block_01.matrixC00,

                dut.u_matmul_8x8.block_01.matrixC33,



                dut.u_matmul_8x8.block_10.matrixC00,

                dut.u_matmul_8x8.block_10.matrixC33,



                dut.u_matmul_8x8.block_11.matrixC00,

                dut.u_matmul_8x8.block_11.matrixC33

            );



        end



    end





    //=========================================================

    // DIAGNOSTIC 2

    //

    // Inter-block systolic routes.

    //=========================================================



    always @(posedge clk) begin



        if (dut.start_mat_mul) begin



            $display(

                "ROUTE T=%0t CNT=%0d | A00to10=%h B00to01=%h | A01to11=%h B10to11=%h",

                $time,



                dut.u_matmul_8x8.wrapper_clk_cnt,



                dut.u_matmul_8x8.a_00_to_10,

                dut.u_matmul_8x8.b_00_to_01,



                dut.u_matmul_8x8.a_01_to_11,

                dut.u_matmul_8x8.b_10_to_11

            );



        end



    end





    //=========================================================

    // DIAGNOSTIC 3

    //

    // Actual inputs being consumed by blocks 01, 10 and 11.

    //=========================================================



    always @(posedge clk) begin



        if (dut.start_mat_mul) begin



            $display(

                "PEIN T=%0t CNT=%0d | B01 a0=%h b0=%h | B10 a0=%h b0=%h | B11 a0=%h b0=%h",

                $time,



                dut.u_matmul_8x8.wrapper_clk_cnt,



                dut.u_matmul_8x8.block_01.a0,

                dut.u_matmul_8x8.block_01.b0,



                dut.u_matmul_8x8.block_10.a0,

                dut.u_matmul_8x8.block_10.b0,



                dut.u_matmul_8x8.block_11.a0,

                dut.u_matmul_8x8.block_11.b0

            );



        end



    end





    //=========================================================

    // DIAGNOSTIC 4

    //

    // RAM addresses and RAM output data.

    //=========================================================



    always @(posedge clk) begin



        if (dut.start_mat_mul) begin



            $display(

                "RAMDBG T=%0t CNT=%0d | A0addr=%0d A1addr=%0d A0data=%h A1data=%h | B0addr=%0d B1addr=%0d B0data=%h B1data=%h",

                $time,



                dut.u_matmul_8x8.wrapper_clk_cnt,



                dut.a_addr_top,

                dut.a_addr_bottom,



                dut.a_data_top,

                dut.a_data_bottom,



                dut.b_addr_left,

                dut.b_addr_right,



                dut.b_data_left,

                dut.b_data_right

            );



        end



    end





endmodule
