module mul #( 
    parameter int A_W = 6,
    parameter int B_W = 2
) (
    input   logic                   clk_i,
    input   logic                   rst_n_i, 
    input   logic   [A_W-1:0]       a_i,
    input   logic   [B_W-1:0]       b_i,
    input   logic                   start_i,
    output  logic   [A_W+B_W-1:0]   res_o,
    output  logic                   is_busy_o,
    output  logic                   is_done_o
);
    localparam int RES_W_W = $clog2(A_W + B_W);

    typedef enum logic [2:0] {
        IDLE,
        CALC,
        DONE
    } state_e;

    state_e state, state_next;  
   
    logic   [A_W+B_W-1:0] a, a_next;                // Left shift each tick, like a[bit_cnt]
    logic   [B_W-1:0]     b, b_next;                // Right shift each tick, like b[bit_cnt]
    logic   [A_W+B_W-1:0] res, res_next;
    logic   [RES_W_W-1:0] bit_cnt, bit_cnt_next; 

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= IDLE;
            res <= 0;
            bit_cnt <= 0;
        end else begin
            state <= state_next;
            res <= res_next;
            bit_cnt <= bit_cnt_next;
        end
    end

    // Update temporal variables. Doesn't need to reset
    always_ff @(posedge clk_i) begin
        a <= a_next;
        b <= b_next;
    end

    logic b_lb;
    assign b_lb = b[0];
    always_comb begin
        state_next = state;
        res_next = res;
        bit_cnt_next = bit_cnt;
        a_next = a;
        b_next = b;
            
        case (state)
            IDLE: begin
                if (start_i) begin
                   state_next = CALC;
                   res_next = 0;
                   bit_cnt_next = 0;
                   a_next = {2'b0, a_i};
                   b_next = b_i;
                end
            end

            CALC: begin
                if (b_lb) begin
                    res_next = res + a;
                end

                // Iterate each bit in b
                if (bit_cnt == B_W[RES_W_W-1:0]-1) begin
                    state_next = DONE; 
                end else begin
                    bit_cnt_next = bit_cnt + 1; 
                    a_next = a << 1;
                    b_next = b >> 1;
                end
            end

            DONE: state_next = IDLE; 
            
            default : state_next = IDLE; 
        endcase
    end 

    assign res_o = res;
    assign is_busy_o = (state == CALC);
    assign is_done_o = (state == DONE); 

endmodule

