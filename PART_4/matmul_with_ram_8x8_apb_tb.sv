`timescale 1ns/1ps

module matmul_with_ram_8x8_apb_tb;

    localparam int RAM_DEPTH = 1024;
    localparam int C_RESULT_OFFSET = 2;

    localparam logic [9:0]
        CONTROL_ADDR  = 10'h000,
        DONE_ADDR     = 10'h002,
        MAT_A_ADDR    = 10'h004,
        MAT_B_ADDR    = 10'h006,
        MAT_C_ADDR    = 10'h008,
        STRIDE_A_ADDR = 10'h00A,
        STRIDE_B_ADDR = 10'h00C,
        STRIDE_C_ADDR = 10'h00E,
        FLAGS_ADDR    = 10'h010;

    logic clk = 0;
    logic resetn = 0;

    logic [9:0] PADDR = 0;
    logic [15:0] PWDATA = 0;
    logic PWRITE = 0;
    logic PSEL = 0;
    logic PENABLE = 0;

    wire [15:0] PRDATA;
    wire PREADY;

    integer errors = 0;
    integer writes_left = 0;
    integer writes_right = 0;

    always #5 clk = ~clk;

    matrix_multiplication_8x8_apb dut (
        .PCLK    (clk),
        .PRESETn (resetn),
        .PADDR   (PADDR),
        .PWRITE  (PWRITE),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY)
    );

    // Waveform generation.
    initial begin
`ifdef FSDB
        $fsdbDumpfile("part4_apb.fsdb");
        $fsdbDumpvars(0, matmul_with_ram_8x8_apb_tb, "+all");
`else
        $dumpfile("part4_apb.vcd");
        $dumpvars(0, matmul_with_ram_8x8_apb_tb);
`endif
    end

    // Observe actual output RAM writes.
    always @(posedge clk) begin
        if (resetn) begin
            if (dut.c_data_available_left)
                writes_left = writes_left + 1;

            if (dut.c_data_available_right)
                writes_right = writes_right + 1;
        end
    end

    initial begin
        #100000;
        $fatal(1, "Global simulation timeout");
    end

   
    task automatic write(
        input logic [9:0] addr,
        input logic [15:0] data
    );
        @(negedge clk);
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PADDR   = addr;
        PWDATA  = data;

        @(negedge clk);
        PENABLE = 1;

        @(posedge clk);
        if (PREADY !== 1'b1)
            $fatal(1, "Expected zero-wait APB write");

        @(negedge clk);
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;

        $display("%0t WRITE addr=%h data=%h",
                 $time, addr, data);
    endtask

    task automatic read(
        input logic [9:0] addr,
        output logic [15:0] data
    );
        @(negedge clk);
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = addr;

        @(negedge clk);
        PENABLE = 1;

        @(posedge clk);
        if (PREADY !== 1'b1)
            $fatal(1, "Expected zero-wait APB read");

        // Sample before clearing the bus.
        data = PRDATA;

        @(negedge clk);
        PSEL    = 0;
        PENABLE = 0;
        PADDR   = 0;

        $display("%0t READ addr=%h data=%h",
                 $time, addr, data);
    endtask

    task automatic check_csr(
        input logic [9:0] addr,
        input logic [15:0] expected
    );
        logic [15:0] actual;

        read(addr, actual);

        if (actual !== expected) begin
            $display("ERROR CSR %h: expected=%h actual=%h",
                     addr, expected, actual);
            errors++;
        end
    endtask

    task automatic reset_design;
        @(negedge clk);
        resetn = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;

        repeat (5) @(negedge clk);
        resetn = 1;

        repeat (2) @(negedge clk);
    endtask

    // --------------------------------------------------------
    // RAM initialization
    // --------------------------------------------------------
    task automatic load_matrices(
        input logic [7:0] a_value,
        input logic [7:0] b_value
    );
        for (int i = 0; i < RAM_DEPTH; i++) begin
            dut.matrix_A0.ram[i] = 32'b0;
            dut.matrix_A1.ram[i] = 32'b0;
            dut.matrix_B0.ram[i] = 32'b0;
            dut.matrix_B1.ram[i] = 32'b0;

            // Sentinel prevents a false pass in the zero test.
            dut.matrix_C0.ram[i] = 32'hDEADBEEF;
            dut.matrix_C1.ram[i] = 32'hDEADBEEF;
        end

        for (int i = 0; i < 8; i++) begin
            dut.matrix_A0.ram[i] = {4{a_value}};
            dut.matrix_A1.ram[i] = {4{a_value}};
            dut.matrix_B0.ram[i] = {4{b_value}};
            dut.matrix_B1.ram[i] = {4{b_value}};
        end
    endtask

    task automatic configure;
        write(MAT_A_ADDR,    16'd0);
        write(MAT_B_ADDR,    16'd0);
        write(MAT_C_ADDR,    16'd0);

        write(STRIDE_A_ADDR, 16'd1);
        write(STRIDE_B_ADDR, 16'd1);
        write(STRIDE_C_ADDR, 16'd1);

        check_csr(MAT_A_ADDR,    16'd0);
        check_csr(MAT_B_ADDR,    16'd0);
        check_csr(MAT_C_ADDR,    16'd0);
        check_csr(STRIDE_A_ADDR, 16'd1);
        check_csr(STRIDE_B_ADDR, 16'd1);
        check_csr(STRIDE_C_ADDR, 16'd1);
    endtask

    task automatic wait_done;
        logic [15:0] status;
        int polls;

        polls = 0;
        status = 0;

        do begin
            read(DONE_ADDR, status);
            polls++;
        end while ((status[15] !== 1'b1) && (polls < 100));

        if (status[15] !== 1'b1)
            $fatal(1, "Timeout polling DONE");

        if (writes_left < 8 || writes_right < 8) begin
            $display("ERROR: insufficient C writes: left=%0d right=%0d",
                     writes_left, writes_right);
            errors++;
        end
    endtask

    task automatic check_results(input logic [7:0] expected);
        logic [31:0] expected_word;

        expected_word = {4{expected}};

        for (int i = 0; i < 8; i++) begin
            if (dut.matrix_C0.ram[i+C_RESULT_OFFSET]
                !== expected_word) begin
                $display("ERROR C0[%0d]: got=%h expected=%h",
                         i+C_RESULT_OFFSET,
                         dut.matrix_C0.ram[i+C_RESULT_OFFSET],
                         expected_word);
                errors++;
            end

            if (dut.matrix_C1.ram[i+C_RESULT_OFFSET]
                !== expected_word) begin
                $display("ERROR C1[%0d]: got=%h expected=%h",
                         i+C_RESULT_OFFSET,
                         dut.matrix_C1.ram[i+C_RESULT_OFFSET],
                         expected_word);
                errors++;
            end
        end
    endtask

    task automatic run_test(
        input string test_name,
        input logic [7:0] a_value,
        input logic [7:0] b_value,
        input logic [7:0] expected_value,
        input bit expect_exception
    );
        int errors_before;
        logic [15:0] flags_value;

        errors_before = errors;
        $display("\nSTART TEST: %s", test_name);

        reset_design();
        load_matrices(a_value, b_value);

        writes_left = 0;
        writes_right = 0;

        configure();

        check_csr(DONE_ADDR,  16'h0000);
        check_csr(FLAGS_ADDR, 16'h0000);

        write(CONTROL_ADDR, 16'h0001);
        wait_done();

        read(FLAGS_ADDR, flags_value);

        if ($isunknown(flags_value)) begin
            $display("ERROR: FLAGS contains X/Z");
            errors++;
        end
        else if (expect_exception) begin
            if (flags_value == 16'h0000) begin
                $display("ERROR: expected an exception");
                errors++;
            end
        end
        else if (flags_value !== 16'h0000) begin
            $display("ERROR: unexpected FLAGS=%h", flags_value);
            errors++;
        end

        // Check all 64 values in the normal tests.
        if (!expect_exception)
            check_results(expected_value);

        // Verify completion remains readable.
        check_csr(DONE_ADDR, 16'h8000);

        if (errors == errors_before)
            $display("PASS: %s", test_name);
        else
            $display("FAIL: %s", test_name);
    endtask

    initial begin
        

        run_test(
            "A=ones, B=ones",
            8'h30, 8'h30, 8'h60, 1'b0
        );

        run_test(
            "A=ones, B=zeros",
            8'h30, 8'h00, 8'h00, 1'b0
        );

        run_test(
            "Finite operands causing overflow",
            8'h6F, 8'h6F, 8'h00, 1'b1
        );

        if (errors != 0)
            $fatal(1, "PART IV FAILED: %0d errors", errors);

        $display("\nPART IV: ALL TESTS PASSED");
        #20;
        $finish;
    end

endmodule
