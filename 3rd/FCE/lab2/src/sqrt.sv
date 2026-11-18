module sqrt #( 
    parameter int W = 16
) (
    input   logic                   clk_i,
    input   logic                   rst_n_i, 
    input   logic   [W-1:0]         x_i,
    input   logic                   start_i,
    output  logic   [W/2-1:0]       res_o,
    output  logic                   is_busy_o,
    output  logic                   is_done_o
);

    localparam int R_W = W / 2;

    typedef enum logic [1:0] {
        IDLE,
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
    logic   [W-1:0] x, x_next;
    logic   [W-1:0] y, y_next;
    logic   [W-1:0] m, m_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            x <= '0;
            y <= '0;
            m <= '0;
        end else begin
            x <= x_next;
            y <= y_next;
            m <= m_next;
        end
    end
    
    logic [W-1:0] b;
    assign b = y | m;
    always_comb begin
        state_next = state;
        x_next = x;
        y_next = y;
        m_next = m;

        case (state)
            IDLE: begin
                if (start_i) begin
                    state_next = CALC;
                    x_next = x_i;
                    y_next = '0;
                    m_next = W'(1) << (W - 2);
                end
            end

            CALC: begin
                if (x >= b) begin
                    x_next = x - b; 
                    y_next = (y >> 1) | m;
                end else begin
                    y_next = (y >> 1);
                end

                m_next = m >> 2;

                if (m == 1) begin
                    state_next = DONE;
                end 
            end

            DONE: state_next = IDLE;

            default: state_next = IDLE;
        endcase
    end

    assign res_o = y[R_W-1:0];
    assign is_busy_o = (state == CALC);
    assign is_done_o = (state == DONE);

endmodule
