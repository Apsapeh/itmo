module cbrt (
    input   logic                   clk_i,
    input   logic                   rst_n_i, 
    input   logic   [15:0]          x_i,
    input   logic                   start_i,
    output  logic   [5:0]           res_o,
    output  logic                   is_busy_o,
    output  logic                   is_done_o
);
    typedef enum logic [2:0] {
        IDLE,
        P1_WAIT,  // p1(tmp) = 3 * y
        P2_START,  // p2(tmp) = p1 * (y + 1)
        P2_WAIT, 
        CALC,
        DONE
    } state_e;

    state_e               state, state_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    /* ====> Variables <==== */
    logic   [15:0]  x,    x_next;
    logic   [5:0]   y,    y_next;
    logic   [3:0]   s,    s_next;
    logic   [12:0]  tmp,  tmp_next; // tmp variable for '3 * y' and 'tmp * (y + 1)'

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            x <= '0;
            y <= '0;
            s <= '0;
            tmp <= '0;
        end else begin
            x <= x_next;
            y <= y_next;
            s <= s_next;
            tmp <= tmp_next;
        end
    end

    /* ====> Devices <==== */
    logic [6:0]  mul_a; 
    logic [5:0]  mul_b;
    logic        mul_start;
    logic [12:0] mul_res;
    wire         mul_is_busy, mul_is_done;
    mul #(
        .A_W(7),
        .B_W(6)
     ) mul (
        .clk_i    (clk_i),
        .rst_n_i  (rst_n_i),
        .a_i      (mul_a),
        .b_i      (mul_b),
        .start_i  (mul_start),
        .res_o    (mul_res),
        .is_busy_o(mul_is_busy),
        .is_done_o(mul_is_done)
    );

    logic [5:0] y_sh;
    logic [5:0] y_sh_inc;
    assign y_sh = y << 1;
    assign y_sh_inc = y_sh | 1'b1;

    logic [16:0] b;
    logic [15:0] b_lo;
    assign b    = {4'd0, tmp | 13'd1} << s;
    assign b_lo = b[15:0];
    always_comb begin
        state_next = state;
        x_next = x;
        y_next = y;
        s_next = s;
        tmp_next  = tmp;
        mul_a     = '0;
        mul_b     = '0;
        mul_start = '0;

        case (state)
            IDLE: begin
                if (start_i) begin
                    state_next = P1_WAIT;
                    x_next = x_i;
                    y_next = '0;
                    s_next = 4'd15;

                    // mul p1
                    mul_a = '0;
                    mul_b = 6'd3;
                    mul_start = 1'b1;
                end
            end

            P1_WAIT: begin
                if (mul_is_done) begin
                    state_next = P2_START;
                    tmp_next = mul_res;
                end
            end

            P2_START: begin
                state_next = P2_WAIT;
                mul_a = tmp[6:0];
                mul_b = y_sh_inc;
                mul_start = 1'b1;
            end

            P2_WAIT: begin
                if (mul_is_done) begin
                    state_next = CALC;
                    tmp_next = mul_res;
                end
            end

            CALC: begin
                if ({1'b0, x} >= b) begin
                    x_next = x - b_lo;
                    y_next = y_sh_inc;
                end else begin
                    y_next = y_sh;
                end


                if (s == '0) begin
                    state_next = DONE;
                end else begin
                    state_next = P1_WAIT;
                    s_next = s - 3;

                    mul_a = {1'b0, y_next << 1};
                    mul_b = 6'd3;
                    mul_start = 1'd1;
                end
            end

            DONE: state_next = IDLE;

            default: state_next = IDLE;
        endcase
    end

    assign res_o = y;
    assign is_busy_o = (state != IDLE);
    assign is_done_o = (state == DONE);

endmodule
