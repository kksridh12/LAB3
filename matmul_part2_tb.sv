`timescale 1ns/1ps
// Lab 3 Part 2 testbench: FP8 E3M4 inputs, normal case and exception case.
// Uses the original matrix_multiplication and RAM modules unchanged.
module matmul_part2_tb;
  reg clk = 0;
  always #10 clk = ~clk;
  reg resetn = 0, pe_resetn = 0, start = 0;
  wire done;
  reg [3:0] flags_seen = 0;
  integer i;
  integer errors = 0;
  reg [31:0] expected_word;

  matrix_multiplication u_matmul (
      .clk(clk), .resetn(resetn), .pe_resetn(pe_resetn),
      .address_mat_a(10'd0), .address_mat_b(10'd0), .address_mat_c(10'd0),
      .address_stride_a(8'd1), .address_stride_b(8'd1), .address_stride_c(8'd1),
      .start(start), .done(done)
  );

  // Observe combined FP flags without changing the fixed top-level RAM module.
  wire [3:0] fp_flags = u_matmul.u_matmul_4x4.flags;
  always @(posedge clk) begin
    if (!resetn || !pe_resetn) flags_seen <= 4'b0;
    else flags_seen <= flags_seen | fp_flags;
  end

  task automatic load_normal;
    begin
      // Values: FP8 E3M4 
      // 0x20 = 0.5
      // 0x30 = 1.0
      // 0x38 = 1.5
      // 0x40 = 2.0
      // Existing RAM loading convention: A columns, B rows, with reversed lane order.
      u_matmul.matrix_A.ram[0] = {8'h40,8'h30,8'h40,8'h20};
      u_matmul.matrix_A.ram[1] = {8'h40,8'h30,8'h30,8'h40};
      u_matmul.matrix_A.ram[2] = {8'h30,8'h38,8'h40,8'h30};
      u_matmul.matrix_A.ram[3] = {8'h30,8'h40,8'h30,8'h40};

      // Matrix B, stored by rows with reversed lane order.
      u_matmul.matrix_B.ram[0] = {8'h30,8'h40,8'h30,8'h30};
      u_matmul.matrix_B.ram[1] = {8'h30,8'h30,8'h20,8'h30};
      u_matmul.matrix_B.ram[2] = {8'h40,8'h30,8'h30,8'h40};
      u_matmul.matrix_B.ram[3] = {8'h38,8'h30,8'h30,8'h30};
    end
  endtask

  task automatic run_case(input integer number);
    begin
      // Apply reset with start deasserted between independent test cases.
      @(negedge clk);
      start = 0; resetn = 0; pe_resetn = 0;
      repeat (4) @(negedge clk);
      load_normal();
      if (number == 2) begin
        // NaN is FP8 E3M4 0x7F: causes invalid flag when multiplied.
        u_matmul.matrix_A.ram[0][7:0] = 8'h7F;
      end
      // Zero the output RAM so that old results cannot be mistaken for new ones.
      for (i=0; i<4; i=i+1) u_matmul.matrix_C.ram[i] = 32'h00000000;
      @(negedge clk);
      resetn = 1; pe_resetn = 1;
      repeat (4) @(negedge clk);
      start = 1;
      @(posedge done);
      #1;
      $display("CASE %0d DONE: flags_seen=%b current_flags=%b time=%0t", number, flags_seen, fp_flags, $time);
      @(negedge clk); start = 0;
      repeat (4) @(negedge clk);
      for (i=0; i<4; i=i+1) begin
        $display("CASE %0d C RAM[%0d] = %08h", number, i, u_matmul.matrix_C.ram[i]);
        if (number == 1) begin
          case (i)
            0: expected_word = 32'h5c5c605a;
            1: expected_word = 32'h54545652;
            2: expected_word = 32'h605a6058;
            3: expected_word = 32'h5e60615e;
          endcase
          if (u_matmul.matrix_C.ram[i] !== expected_word) begin
            errors = errors + 1;
            $display("FAIL CASE 1 RAM[%0d]: expected %08h, got %08h", i, expected_word, u_matmul.matrix_C.ram[i]);
          end else $display("PASS CASE 1 RAM[%0d]", i);
        end
      end
      if (number == 1) begin
        if (flags_seen !== 4'b0) begin
          errors = errors + 1;
          $display("FAIL CASE 1 flags: expected 0000, got %b", flags_seen);
        end else $display("PASS CASE 1 flags");
      end
      if (number == 2) begin
        // Only assert flag behavior here; exceptional-result values must be
        // checked against the Part 1 FP8 arithmetic specification separately.
        if (flags_seen[1] !== 1'b1) begin
          errors = errors + 1;
          $display("FAIL CASE 2 invalid flag: expected bit 1 asserted, got %b", flags_seen);
        end else $display("PASS CASE 2 invalid flag");
      end
    end
  endtask

  initial begin
    $fsdbDumpvars;
    run_case(1);
    run_case(2);
    if (errors != 0) $fatal(1, "LAB3 PART2: %0d check(s) failed", errors);
    $display("LAB3 PART2: all implemented checks passed");
    $finish;
  end

  initial begin
    #10000;
    $fatal(1, "Timeout waiting for done; check control and array timing");
  end
endmodule
