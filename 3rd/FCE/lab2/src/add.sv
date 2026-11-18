module add #( 
    parameter int W = 6
) (
    input   logic                   clk_i,
    input   logic                   rst_n_i, 
    input   logic   [W-1:0]         a_i,
    input   logic   [W-1:0]         b_i,
    input   logic                   start_i,
    output  logic   [W:0]           res_o,
    output  logic                   is_busy_o,
    output  logic                   is_done_o
);

    localparam int RES_W_W = $clog2(W+1);

    typedef enum logic [2:0] {
        IDLE,
        CALC,
        DONE
    } state_e;

    state_e               state, state_next;
    logic   [W:0]         res, res_next;  

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= IDLE;
            res <= 0;
        end else begin
            state <= state_next;
            res <= res_next;
        end
    end

    /* ====> Variables <==== */
    logic   [RES_W_W-1:0] bit_cnt, bit_cnt_next;
    logic   [W-1:0]       a, a_next;
    logic   [W-1:0]       b, b_next;
    logic                 c, c_next;  

    always_ff @(posedge clk_i) begin
        bit_cnt <= bit_cnt_next;
        a <= a_next;
        b <= b_next;
        c <= c_next;
    end

    /* ====> Devices <==== */
    logic fa_s, fa_c;
    full_adder full_adder0 (
         .a_i(a[0]),
         .b_i(b[0]),
         .c_i(c),
         .s_o(fa_s),
         .c_o(fa_c)
    ); 

    always_comb begin
        state_next = state;
        res_next = res;
        bit_cnt_next = bit_cnt;
        a_next = a;
        b_next = b;
        c_next = c;

        case (state)
            IDLE: begin
                if (start_i) begin
                    state_next = CALC;
                    res_next = 0;
                    bit_cnt_next = 0;
                    a_next = a_i;
                    b_next = b_i;
                    c_next = 1'b0;
                end
            end

            CALC: begin
                res_next = {fa_s, res[W:1]};    
                
                if (bit_cnt == W[RES_W_W-1:0]) begin
                    state_next = DONE;
                end else begin
                    bit_cnt_next = bit_cnt + 1'd1;
                    a_next = a >> 1;
                    b_next = b >> 1;
                    c_next = fa_c;
                end
            end

            DONE: state_next = IDLE;

            default: state_next = IDLE;
        endcase
    end

    assign res_o = res;
    assign is_busy_o = (state != IDLE);
    assign is_done_o = (state == DONE);

endmodule
