module calc (
    input   logic                   clk_i,
    input   logic                   rst_n_i,
    input   logic   [15:0]          a_i,
    input   logic   [15:0]          b_i,
    input   logic                   start_i,
    output  logic   [8:0]           res_o,          
    output  logic                   is_busy_o,
    output  logic                   is_done_o
);
    typedef enum logic [2:0] {
        IDLE,
        ROOTS_WAIT,     // cbrt and sqrt work at the same time
        ADD_WAIT,
        DONE
    } state_e;

    state_e  state, state_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    /* ====> Variables <==== */
    logic   [5:0]   c_res,  c_res_next;      // cbrt
    logic           c_end,  c_end_next;     
    logic   [7:0]   s_res,  s_res_next;      // sqrt
    logic           s_end,  s_end_next;     
    logic   [8:0]   res,    res_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            c_res <= '0;
            s_res <= '0;
            c_end  <= 1'b0;
            s_end  <= 1'b0;
            res   <= '0;
        end else begin
            c_res <= c_res_next;
            s_res <= s_res_next;
            c_end  <= c_end_next;
            s_end  <= s_end_next;
            res   <= res_next;
        end
    end

    /* ====> Devices <==== */
    logic           cbrt_start;
    logic           cbrt_is_done;
    logic   [5:0]   cbrt_res;
    cbrt cbrt0 (
        .clk_i    (clk_i),
        .rst_n_i  (rst_n_i),
        .x_i      (a_i),
        .start_i  (cbrt_start),
        .res_o    (cbrt_res),
        .is_busy_o(),
        .is_done_o(cbrt_is_done)
    );

    logic           sqrt_start;
    logic           sqrt_is_done;
    logic   [7:0]   sqrt_res;
    sqrt #(.W(16)) sqrt0 (
        .clk_i    (clk_i),
        .rst_n_i  (rst_n_i),
        .x_i      (b_i),
        .start_i  (sqrt_start),
        .res_o    (sqrt_res),
        .is_busy_o(),
        .is_done_o(sqrt_is_done)
    );

    logic           add_start;
    logic           add_is_done;
    logic   [7:0]   add_a, add_b;
    logic   [8:0]   add_res;
    add #(.W(8)) add0 (
        .clk_i    (clk_i),
        .rst_n_i  (rst_n_i),
        .a_i      (add_a),
        .b_i      (add_b),
        .start_i  (add_start),
        .res_o    (add_res),
        .is_busy_o(),
        .is_done_o(add_is_done)
    );

    always_comb begin
        state_next = state;
        c_res_next = c_res;
        s_res_next = s_res;
        c_end_next  = c_end;
        s_end_next  = s_end;
        res_next   = res;
        cbrt_start = 1'b0;
        sqrt_start = 1'b0;
        add_start  = 1'b0;
        add_a      = '0;
        add_b      = '0;

        case (state)
            IDLE: begin
                if (start_i) begin
                    state_next = ROOTS_WAIT;
                    c_end_next  = 1'b0;
                    s_end_next  = 1'b0;
                    cbrt_start = 1'b1;      
                    sqrt_start = 1'b1;
                end
            end

            ROOTS_WAIT: begin
                if (cbrt_is_done) begin         // is_done is one shot, store it 
                    c_res_next = cbrt_res;
                    c_end_next  = 1'b1;
                end
                if (sqrt_is_done) begin
                    s_res_next = sqrt_res;
                    s_end_next  = 1'b1;
                end

                if (c_end && s_end) begin         
                    state_next = ADD_WAIT;
                    add_a      = {2'b00, c_res};
                    add_b      = s_res;
                    add_start  = 1'b1;
                end
            end

            ADD_WAIT: begin
                if (add_is_done) begin
                    res_next   = add_res;
                    state_next = DONE;
                end
            end

            DONE: state_next = IDLE;

            default: state_next = IDLE;
        endcase
    end

    assign res_o     = res;
    assign is_busy_o = (state != IDLE) && (state != DONE);
    assign is_done_o = (state == DONE);

endmodule
