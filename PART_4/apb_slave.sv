module apb_slave #(
    parameter int ADDR_WIDTH     = 10,
    parameter int MAT_ADDR_WIDTH = 10,
    parameter int STRIDE_WIDTH   = 8,
    parameter int FLAGS_WIDTH    = 1,

    parameter logic [ADDR_WIDTH-1:0] CONTROL_ADDR  = 'h00,
    parameter logic [ADDR_WIDTH-1:0] DONE_ADDR     = 'h02,
    parameter logic [ADDR_WIDTH-1:0] MAT_A_ADDR    = 'h04,
    parameter logic [ADDR_WIDTH-1:0] MAT_B_ADDR    = 'h06,
    parameter logic [ADDR_WIDTH-1:0] MAT_C_ADDR    = 'h08,
    parameter logic [ADDR_WIDTH-1:0] STRIDE_A_ADDR = 'h0A,
    parameter logic [ADDR_WIDTH-1:0] STRIDE_B_ADDR = 'h0C,
    parameter logic [ADDR_WIDTH-1:0] STRIDE_C_ADDR = 'h0E,
    parameter logic [ADDR_WIDTH-1:0] FLAGS_ADDR    = 'h10
)(
    // APB signals
    input  logic                      PCLK,
    input  logic                      PRESETn,
    input  logic [ADDR_WIDTH-1:0]     PADDR,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic [15:0]               PWDATA,
    output logic [15:0]               PRDATA,
    output logic                      PREADY,

    // connection to the matmul
    output logic                      start,
    output logic                      pe_reset,
    input  logic                      done,
    input  logic [FLAGS_WIDTH-1:0]    flags,
    output logic [MAT_ADDR_WIDTH-1:0] address_mat_a,
    output logic [MAT_ADDR_WIDTH-1:0] address_mat_b,
    output logic [MAT_ADDR_WIDTH-1:0] address_mat_c,
    output logic [STRIDE_WIDTH-1:0]   address_stride_a,
    output logic [STRIDE_WIDTH-1:0]   address_stride_b,
    output logic [STRIDE_WIDTH-1:0]   address_stride_c
);

    typedef enum logic [1:0] {IDLE, SETUP, READ_STATE, WRITE_STATE} apb_state_t;
    typedef enum logic [1:0] {ACC_IDLE, ACC_CLEAR, ACC_RUN, ACC_FINISH} acc_state_t;

    apb_state_t present_state, next_state;
    acc_state_t acc_state, next_acc_state;

    logic [15:0]               next_prdata;
    logic [MAT_ADDR_WIDTH-1:0] next_mat_a, next_mat_b, next_mat_c;
    logic [STRIDE_WIDTH-1:0]   next_stride_a, next_stride_b, next_stride_c;
    logic                      done_reg, next_done_reg;
    logic [FLAGS_WIDTH-1:0]    flags_reg, next_flags_reg;
    logic                      busy, start_request;
    logic [15:0]               rdata_mux;

    assign PREADY   = 1'b1;  // no wait states
    assign busy     = (acc_state != ACC_IDLE);
    assign start    = PRESETn && (acc_state == ACC_RUN);
    assign pe_reset = !PRESETn || (acc_state == ACC_CLEAR);

    // sequential part
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            present_state    <= IDLE;
            acc_state        <= ACC_IDLE;
            PRDATA           <= '0;
            address_mat_a    <= '0;
            address_mat_b    <= '0;
            address_mat_c    <= '0;
            address_stride_a <= '0;
            address_stride_b <= '0;
            address_stride_c <= '0;
            done_reg         <= 1'b0;
            flags_reg        <= '0;
        end else begin
            present_state    <= next_state;
            acc_state        <= next_acc_state;
            PRDATA           <= next_prdata;
            address_mat_a    <= next_mat_a;
            address_mat_b    <= next_mat_b;
            address_mat_c    <= next_mat_c;
            address_stride_a <= next_stride_a;
            address_stride_b <= next_stride_b;
            address_stride_c <= next_stride_c;
            done_reg         <= next_done_reg;
            flags_reg        <= next_flags_reg;
        end
    end

    // read mux
    always_comb begin
        rdata_mux = '0;
        case (PADDR)
            CONTROL_ADDR:  rdata_mux[15]                 = busy;
            DONE_ADDR:     rdata_mux[15]                 = done_reg;
            MAT_A_ADDR:    rdata_mux[MAT_ADDR_WIDTH-1:0] = address_mat_a;
            MAT_B_ADDR:    rdata_mux[MAT_ADDR_WIDTH-1:0] = address_mat_b;
            MAT_C_ADDR:    rdata_mux[MAT_ADDR_WIDTH-1:0] = address_mat_c;
            STRIDE_A_ADDR: rdata_mux[STRIDE_WIDTH-1:0]   = address_stride_a;
            STRIDE_B_ADDR: rdata_mux[STRIDE_WIDTH-1:0]   = address_stride_b;
            STRIDE_C_ADDR: rdata_mux[STRIDE_WIDTH-1:0]   = address_stride_c;
            FLAGS_ADDR:    rdata_mux[FLAGS_WIDTH-1:0]    = flags_reg;
            default:       rdata_mux                     = '0;
        endcase
    end

    // combinational part
    always_comb begin
        next_state     = present_state;
        next_acc_state = acc_state;
        next_prdata    = PRDATA;
        next_mat_a     = address_mat_a;
        next_mat_b     = address_mat_b;
        next_mat_c     = address_mat_c;
        next_stride_a  = address_stride_a;
        next_stride_b  = address_stride_b;
        next_stride_c  = address_stride_c;
        next_done_reg  = done_reg;
        next_flags_reg = flags_reg;
        start_request  = 1'b0;

        // apb fsm 
        case (present_state)
            IDLE: begin
                if (PSEL) next_state = SETUP;
            end

            SETUP: begin
                if (!PSEL)
                    next_state = IDLE;
                else if (PENABLE && PWRITE) begin
                    next_state = WRITE_STATE;
                    case (PADDR)
                        CONTROL_ADDR:  start_request = PWDATA[0] && !busy;
                        MAT_A_ADDR:    if (!busy) next_mat_a    = PWDATA[MAT_ADDR_WIDTH-1:0];
                        MAT_B_ADDR:    if (!busy) next_mat_b    = PWDATA[MAT_ADDR_WIDTH-1:0];
                        MAT_C_ADDR:    if (!busy) next_mat_c    = PWDATA[MAT_ADDR_WIDTH-1:0];
                        STRIDE_A_ADDR: if (!busy) next_stride_a = PWDATA[STRIDE_WIDTH-1:0];
                        STRIDE_B_ADDR: if (!busy) next_stride_b = PWDATA[STRIDE_WIDTH-1:0];
                        STRIDE_C_ADDR: if (!busy) next_stride_c = PWDATA[STRIDE_WIDTH-1:0];
                        default: ;
                    endcase
                end
                else if (PENABLE) begin
                    next_state  = READ_STATE;
                    next_prdata = rdata_mux;
                end
            end

            READ_STATE, WRITE_STATE: begin
                if (PSEL && !PENABLE) next_state = SETUP;
                else                  next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase

        // run control fsm
        case (acc_state)
            ACC_IDLE: begin
                if (start_request) begin
                    next_done_reg  = 1'b0;
                    next_flags_reg = '0;
                    next_acc_state = ACC_CLEAR;
                end
            end
            ACC_CLEAR: next_acc_state = ACC_RUN;
            ACC_RUN: begin
                next_flags_reg = flags_reg | flags;
                if (done) next_acc_state = ACC_FINISH;
            end
            ACC_FINISH: begin
                next_flags_reg = flags_reg | flags;
                next_done_reg  = 1'b1;
                next_acc_state = ACC_IDLE;
            end
            default: next_acc_state = ACC_IDLE;
        endcase
    end

endmodule