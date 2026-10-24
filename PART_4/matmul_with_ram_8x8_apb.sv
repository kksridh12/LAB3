`timescale 1ns/1ps

`define DWIDTH 8
`define AWIDTH 10
`define MEM_SIZE 1024
`define FWIDTH 4

`define MAT_MUL_SIZE 4
`define MASK_WIDTH 4
`define LOG2_MAT_MUL_SIZE 2

`define BB_MAT_MUL_SIZE `MAT_MUL_SIZE
`define NUM_CYCLES_IN_MAC 3
`define MEM_ACCESS_LATENCY 1
`define REG_DATAWIDTH 32
`define REG_ADDRWIDTH 8
`define ADDR_STRIDE_WIDTH 8
`define MAX_BITS_POOL 3

module matrix_multiplication_8x8_apb (
    input  logic                PCLK,
    input  logic                PRESETn,
    input  logic [`AWIDTH-1:0]  PADDR,
    input  logic                PWRITE,
    input  logic                PSEL,
    input  logic                PENABLE,
    input  logic [15:0]         PWDATA,

    output logic [15:0]         PRDATA,
    output logic                PREADY
);

    logic reset;
    logic pe_reset;
    logic start_mat_mul;
    logic done_mat_mul;

    logic [`FWIDTH-1:0] flags;

    logic [`AWIDTH-1:0] address_mat_a;
    logic [`AWIDTH-1:0] address_mat_b;
    logic [`AWIDTH-1:0] address_mat_c;

    logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a;
    logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_b;
    logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c;

    logic [`AWIDTH-1:0] a_addr_top;
    logic [`AWIDTH-1:0] a_addr_bottom;
    logic [`AWIDTH-1:0] b_addr_left;
    logic [`AWIDTH-1:0] b_addr_right;
    logic [`AWIDTH-1:0] c_addr_left;
    logic [`AWIDTH-1:0] c_addr_right;

    logic [31:0] a_data_top;
    logic [31:0] a_data_bottom;
    logic [31:0] b_data_left;
    logic [31:0] b_data_right;
    logic [31:0] c_data_left;
    logic [31:0] c_data_right;

    logic c_data_available_left;
    logic c_data_available_right;

    assign reset = ~PRESETn;

    // APB control replaces the original start FSM.
    apb_slave #(
        .ADDR_WIDTH     (`AWIDTH),
        .MAT_ADDR_WIDTH (`AWIDTH),
        .STRIDE_WIDTH   (`ADDR_STRIDE_WIDTH),
        .FLAGS_WIDTH    (`FWIDTH)
    ) u_apb (
        .PCLK             (PCLK),
        .PRESETn          (PRESETn),
        .PADDR            (PADDR),
        .PWRITE           (PWRITE),
        .PSEL             (PSEL),
        .PENABLE          (PENABLE),
        .PWDATA           (PWDATA),
        .PRDATA           (PRDATA),
        .PREADY           (PREADY),

        .start            (start_mat_mul),
        .pe_reset         (pe_reset),
        .done             (done_mat_mul),
        .flags            (flags),

        .address_mat_a    (address_mat_a),
        .address_mat_b    (address_mat_b),
        .address_mat_c    (address_mat_c),
        .address_stride_a (address_stride_a),
        .address_stride_b (address_stride_b),
        .address_stride_c (address_stride_c)
    );

    // Matrix A RAM banks.
    ram matrix_A0 (
        .addr0(a_addr_top),
        .d0(32'b0),
        .we0(4'b0),
        .q0(a_data_top),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    ram matrix_A1 (
        .addr0(a_addr_bottom),
        .d0(32'b0),
        .we0(4'b0),
        .q0(a_data_bottom),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    // Matrix B RAM banks.
    ram matrix_B0 (
        .addr0(b_addr_left),
        .d0(32'b0),
        .we0(4'b0),
        .q0(b_data_left),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    ram matrix_B1 (
        .addr0(b_addr_right),
        .d0(32'b0),
        .we0(4'b0),
        .q0(b_data_right),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    // Matrix C RAM banks.
    ram matrix_C0 (
        .addr0(c_addr_left),
        .d0(c_data_left),
        .we0({4{c_data_available_left}}),
        .q0(),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    ram matrix_C1 (
        .addr0(c_addr_right),
        .d0(c_data_right),
        .we0({4{c_data_available_right}}),
        .q0(),
        .addr1({`AWIDTH{1'b0}}),
        .d1(32'b0),
        .we1(4'b0),
        .q1(),
        .clk(PCLK)
    );

    // Existing 8x8 core.
    matmul_8x8 u_matmul_8x8 (
        .clk                    (PCLK),
        .reset                  (reset),
        .pe_reset               (pe_reset),

        .start_mat_mul          (start_mat_mul),
        .done_mat_mul           (done_mat_mul),

        .address_mat_a          (address_mat_a),
        .address_mat_b          (address_mat_b),
        .address_mat_c          (address_mat_c),

        .address_stride_a       (address_stride_a),
        .address_stride_b       (address_stride_b),
        .address_stride_c       (address_stride_c),

        .a_data_top             (a_data_top),
        .a_data_bottom          (a_data_bottom),
        .b_data_left            (b_data_left),
        .b_data_right           (b_data_right),

        .c_data_left            (c_data_left),
        .c_data_right           (c_data_right),

        .a_addr_top             (a_addr_top),
        .a_addr_bottom          (a_addr_bottom),
        .b_addr_left            (b_addr_left),
        .b_addr_right           (b_addr_right),
        .c_addr_left            (c_addr_left),
        .c_addr_right           (c_addr_right),

        .c_data_available_left  (c_data_available_left),
        .c_data_available_right (c_data_available_right),

        .flags                  (flags)
    );

endmodule
