`timescale 1ns/1ps

module apb_slave #(
    parameter int ADDR_WIDTH     = 10,
    parameter int MAT_ADDR_WIDTH = 10,
    parameter int STRIDE_WIDTH   = 8,
    parameter int FLAGS_WIDTH    = 4
)(
    // APB interface
    input  logic                      PCLK,
    input  logic                      PRESETn,
    input  logic [ADDR_WIDTH-1:0]      PADDR,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic [15:0]                PWDATA,

    output logic [15:0]                PRDATA,
    output logic                      PREADY,

    // Accelerator control/status
    output logic                      start,
    output logic                      pe_reset,
    input  logic                      done,
    input  logic [FLAGS_WIDTH-1:0]     flags,

    // Matrix configuration
    output logic [MAT_ADDR_WIDTH-1:0]  address_mat_a,
    output logic [MAT_ADDR_WIDTH-1:0]  address_mat_b,
    output logic [MAT_ADDR_WIDTH-1:0]  address_mat_c,

    output logic [STRIDE_WIDTH-1:0]    address_stride_a,
    output logic [STRIDE_WIDTH-1:0]    address_stride_b,
    output logic [STRIDE_WIDTH-1:0]    address_stride_c
);

    localparam logic [ADDR_WIDTH-1:0]
        CONTROL_ADDR  = 'h00,
        DONE_ADDR     = 'h02,
        MAT_A_ADDR    = 'h04,
        MAT_B_ADDR    = 'h06,
        MAT_C_ADDR    = 'h08,
        STRIDE_A_ADDR = 'h0A,
        STRIDE_B_ADDR = 'h0C,
        STRIDE_C_ADDR = 'h0E,
        FLAGS_ADDR    = 'h10;

    logic apb_write;
    logic busy;
    logic start_request;
    logic done_reg;
    logic [FLAGS_WIDTH-1:0] flags_reg;

    // Zero-wait APB interface.
    assign PREADY = 1'b1;

    assign apb_write =
        PRESETn && PSEL && PENABLE && PWRITE;

  
    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        READ_STATE,
        WRITE_STATE
    } apb_state_t;

    apb_state_t present_state, next_state;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    always_comb begin
        next_state = present_state;

        case (present_state)
            IDLE: begin
                if (PSEL && !PENABLE)
                    next_state = SETUP;
            end

            SETUP: begin
                if (!PSEL)
                    next_state = IDLE;
                else if (PENABLE) begin
                    if (PWRITE)
                        next_state = WRITE_STATE;
                    else
                        next_state = READ_STATE;
                end
            end

            READ_STATE, WRITE_STATE: begin
                if (PSEL && !PENABLE)
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end

            default:
                next_state = IDLE;
        endcase
    end

    // --------------------------------------------------------
    // Configuration registers
    // --------------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            address_mat_a    <= '0;
            address_mat_b    <= '0;
            address_mat_c    <= '0;
            address_stride_a <= '0;
            address_stride_b <= '0;
            address_stride_c <= '0;
        end
        else if (apb_write && !busy) begin
            case (PADDR)
                MAT_A_ADDR:
                    address_mat_a <= PWDATA[MAT_ADDR_WIDTH-1:0];

                MAT_B_ADDR:
                    address_mat_b <= PWDATA[MAT_ADDR_WIDTH-1:0];

                MAT_C_ADDR:
                    address_mat_c <= PWDATA[MAT_ADDR_WIDTH-1:0];

                STRIDE_A_ADDR:
                    address_stride_a <= PWDATA[STRIDE_WIDTH-1:0];

                STRIDE_B_ADDR:
                    address_stride_b <= PWDATA[STRIDE_WIDTH-1:0];

                STRIDE_C_ADDR:
                    address_stride_c <= PWDATA[STRIDE_WIDTH-1:0];

                default: ;
            endcase
        end
    end

    // --------------------------------------------------------
    // Accelerator control FSM
    // --------------------------------------------------------
    typedef enum logic [1:0] {
        ACC_IDLE,
        ACC_CLEAR,
        ACC_RUN,
        ACC_FINISH
    } acc_state_t;

    acc_state_t acc_state;

    assign busy = (acc_state != ACC_IDLE);

    assign start_request =
        apb_write &&
        (PADDR == CONTROL_ADDR) &&
        PWDATA[0] &&
        !busy;

    // Held high for the entire core operation.
    assign start = PRESETn && (acc_state == ACC_RUN);

    // Active-high PE accumulator reset.
    assign pe_reset = !PRESETn || (acc_state == ACC_CLEAR);

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            acc_state <= ACC_IDLE;
            done_reg  <= 1'b0;
            flags_reg <= '0;
        end
        else begin
            case (acc_state)
                ACC_IDLE: begin
                    if (start_request) begin
                        done_reg  <= 1'b0;
                        flags_reg <= '0;
                        acc_state <= ACC_CLEAR;
                    end
                end

                ACC_CLEAR: begin
                    acc_state <= ACC_RUN;
                end

                ACC_RUN: begin
                    flags_reg <= flags_reg | flags;

                    if (done)
                        acc_state <= ACC_FINISH;
                end

                ACC_FINISH: begin
                    done_reg  <= 1'b1;
                    acc_state <= ACC_IDLE;
                end

                default: begin
                    acc_state <= ACC_IDLE;
                    done_reg  <= 1'b0;
                    flags_reg <= '0;
                end
            endcase
        end
    end

    // --------------------------------------------------------
    // Combinational read mux
    // --------------------------------------------------------
    always_comb begin
        PRDATA = '0;

        if (PRESETn) begin
            case (PADDR)
                CONTROL_ADDR:
                    PRDATA[15] = busy;

                DONE_ADDR:
                    PRDATA[15] = done_reg;

                MAT_A_ADDR:
                    PRDATA[MAT_ADDR_WIDTH-1:0] = address_mat_a;

                MAT_B_ADDR:
                    PRDATA[MAT_ADDR_WIDTH-1:0] = address_mat_b;

                MAT_C_ADDR:
                    PRDATA[MAT_ADDR_WIDTH-1:0] = address_mat_c;

                STRIDE_A_ADDR:
                    PRDATA[STRIDE_WIDTH-1:0] = address_stride_a;

                STRIDE_B_ADDR:
                    PRDATA[STRIDE_WIDTH-1:0] = address_stride_b;

                STRIDE_C_ADDR:
                    PRDATA[STRIDE_WIDTH-1:0] = address_stride_c;

                FLAGS_ADDR:
                    PRDATA[FLAGS_WIDTH-1:0] = flags_reg;

                default:
                    PRDATA = '0;
            endcase
        end
    end

endmodule
