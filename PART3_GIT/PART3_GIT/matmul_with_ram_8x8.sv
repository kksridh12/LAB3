`timescale 1ns/1ps



module matrix_multiplication_8x8 (

    input  logic clk,

    input  logic resetn,

    input  logic pe_resetn,



    input  logic [`AWIDTH-1:0] address_mat_a,

    input  logic [`AWIDTH-1:0] address_mat_b,

    input  logic [`AWIDTH-1:0] address_mat_c,



    input  logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a,

    input  logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_b,

    input  logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c,



    input  logic start,

    output logic done

);



    //---------------------------------------------------------

    // Internal reset/control

    //---------------------------------------------------------



    logic reset;

    logic pe_reset;



    assign reset    = ~resetn;

    assign pe_reset = ~pe_resetn;



    logic start_mat_mul;

    logic done_mat_mul;



    //---------------------------------------------------------

    // Simple start FSM

    //---------------------------------------------------------



    typedef enum logic [1:0] {

        IDLE,

        START,

        RUN

    } state_t;



    state_t state;



    always_ff @(posedge clk) begin

        if (!resetn) begin

            state         <= IDLE;

            start_mat_mul <= 1'b0;

        end

        else begin

            case (state)



                IDLE: begin

                    start_mat_mul <= 1'b0;



                    if (start)

                        state <= START;

                end



                START: begin

                    start_mat_mul <= 1'b1;

                    state <= RUN;

                end



                RUN: begin

                    if (done_mat_mul) begin

                        start_mat_mul <= 1'b0;

                        state <= IDLE;

                    end

                end



                default: begin

                    state <= IDLE;

                    start_mat_mul <= 1'b0;

                end



            endcase

        end

    end



    assign done = done_mat_mul;





    //---------------------------------------------------------

    // A RAM banks

    //---------------------------------------------------------



    logic [`AWIDTH-1:0] a_addr_top;

    logic [`AWIDTH-1:0] a_addr_bottom;



    logic [31:0] a_data_top;

    logic [31:0] a_data_bottom;





    ram matrix_A0 (

        .addr0(a_addr_top),

        .d0(32'b0),

        .we0(4'b0000),

        .q0(a_data_top),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    ram matrix_A1 (

        .addr0(a_addr_bottom),

        .d0(32'b0),

        .we0(4'b0000),

        .q0(a_data_bottom),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    //---------------------------------------------------------

    // B RAM banks

    //---------------------------------------------------------



    logic [`AWIDTH-1:0] b_addr_left;

    logic [`AWIDTH-1:0] b_addr_right;



    logic [31:0] b_data_left;

    logic [31:0] b_data_right;





    ram matrix_B0 (

        .addr0(b_addr_left),

        .d0(32'b0),

        .we0(4'b0000),

        .q0(b_data_left),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    ram matrix_B1 (

        .addr0(b_addr_right),

        .d0(32'b0),

        .we0(4'b0000),

        .q0(b_data_right),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    //---------------------------------------------------------

    // C RAM banks

    //---------------------------------------------------------



    logic [`AWIDTH-1:0] c_addr_left;

    logic [`AWIDTH-1:0] c_addr_right;



    logic [31:0] c_data_left;

    logic [31:0] c_data_right;



    logic c_data_available_left;

    logic c_data_available_right;





    ram matrix_C0 (

        .addr0(c_addr_left),

        .d0(c_data_left),

        .we0(c_data_available_left ? 4'b1111 : 4'b0000),

        .q0(),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    ram matrix_C1 (

        .addr0(c_addr_right),

        .d0(c_data_right),

        .we0(c_data_available_right ? 4'b1111 : 4'b0000),

        .q0(),



        .addr1({`AWIDTH{1'b0}}),

        .d1(32'b0),

        .we1(4'b0000),

        .q1(),



        .clk(clk)

    );





    //---------------------------------------------------------

    // 8x8 systolic multiplier

    //---------------------------------------------------------



    logic [`FWIDTH-1:0] flags;



    matmul_8x8 u_matmul_8x8 (



        .clk(clk),

        .reset(reset),

        .pe_reset(pe_reset),



        .start_mat_mul(start_mat_mul),

        .done_mat_mul(done_mat_mul),



        .address_mat_a(address_mat_a),

        .address_mat_b(address_mat_b),

        .address_mat_c(address_mat_c),



        .address_stride_a(address_stride_a),

        .address_stride_b(address_stride_b),

        .address_stride_c(address_stride_c),



        .a_data_top(a_data_top),

        .a_data_bottom(a_data_bottom),



        .b_data_left(b_data_left),

        .b_data_right(b_data_right),



        .c_data_left(c_data_left),

        .c_data_right(c_data_right),



        .a_addr_top(a_addr_top),

        .a_addr_bottom(a_addr_bottom),



        .b_addr_left(b_addr_left),

        .b_addr_right(b_addr_right),



        .c_addr_left(c_addr_left),

        .c_addr_right(c_addr_right),



        .c_data_available_left(c_data_available_left),

        .c_data_available_right(c_data_available_right),



        .flags(flags)

    );



endmodule
