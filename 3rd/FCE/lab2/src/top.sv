module top (
    input logic clk_i,
    input logic rst_n_i,

    // input logic start_i,
    //input wire [15:0] a_i,
    //input wire [15:0] b_i,
    input  wire rx_wire_i,
    output wire tx_wire_o
);

    typedef enum logic [2:0] {
        WAIT_A_L,
        WAIT_A_H,
        WAIT_B_L,
        WAIT_B_H,
        START_CALC,
        WAIT_CALC,
        WAIT_SENDING_ANS_L,
        WAIT_SENDING_ANS_H
    } state_e;

    /* ====> Variables <==== */
    state_e state, state_next;
    logic [15:0] a, a_next, b, b_next;

    // UART RX
    logic rx_confirm, rx_confirm_next;
    wire [7:0] rx_data;
    wire rx_is_ready;

    // UART TX
    logic [7:0] tx_data, tx_data_next;
    logic       tx_start, tx_start_next;
    wire        tx_busy;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            a <= 8'b0;
            b <= 8'b0;
            state <= WAIT_A_L;
            // rx
            rx_confirm <= 1'b0;
            // tx
            tx_data  <= 8'b0;
            tx_start <= 1'b0;
        end else begin
            a <= a_next;
            b <= b_next;
            state <= state_next;
            // rx
            rx_confirm <= rx_confirm_next;
            // tx
            tx_data  <= tx_data_next;
            tx_start <= tx_start_next;
        end
    end

    /* ====> Devices <==== */
    uart_rx #() uart_rx0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .rx_wire_i(rx_wire_i),
        .confirm_i(rx_confirm),
        .data_o(rx_data),
        .is_ready_o(rx_is_ready)
    );

    uart_tx #() uart_tx0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .data_i(tx_data),
        .start_i(tx_start),
        .tx_wire_o(tx_wire_o),
        .busy_o(tx_busy)
    );

    logic calc_start, calc_is_busy, calc_is_done;
    logic [8:0] calc_res; 
    calc calc0 (
        .clk_i    (clk_i),
        .rst_n_i  (rst_n_i),
        .a_i      (a),
        .b_i      (b),
        .start_i  (calc_start),
        .res_o    (calc_res),
        .is_busy_o(calc_is_busy),
        .is_done_o(calc_is_done)
    );

   
    always_comb begin
        state_next = state;
        a_next = a;
        b_next = b;
        rx_confirm_next = 1'b0;
        tx_start_next = 1'b0;
        tx_data_next = tx_data;

        calc_start = '0;

        case (state)
            WAIT_A_L: begin
                if (rx_is_ready && ~rx_confirm) begin
                    a_next = {rx_data, a[15:8]};
                    rx_confirm_next = 1'b1;
                    state_next = WAIT_A_H;
                end
            end

            WAIT_A_H: begin
                if (rx_is_ready && ~rx_confirm) begin
                    a_next = {rx_data, a[15:8]} ;
                    rx_confirm_next = 1'b1;
                    state_next = WAIT_B_L;
                end
            end

            WAIT_B_L: begin
                if (rx_is_ready && ~rx_confirm) begin
                    b_next = {rx_data, b[15:8]};
                    rx_confirm_next = 1'b1;
                    state_next = WAIT_B_H;
                end
            end

            WAIT_B_H: begin
                if (rx_is_ready && ~rx_confirm) begin
                    b_next = {rx_data, b[15:8]};
                    rx_confirm_next = 1'b1;
                    state_next = START_CALC;
                end
            end

            START_CALC: begin
                state_next = WAIT_CALC;
                calc_start = 1'd1;
            end

            WAIT_CALC: begin
                if (calc_is_done) begin
                    state_next = WAIT_SENDING_ANS_L;
                    tx_start_next = 1'b1;
                    tx_data_next = calc_res[7:0];
                end
            end

            WAIT_SENDING_ANS_L: begin
                if (~tx_busy && ~tx_start) begin
                    state_next = WAIT_SENDING_ANS_H;
                    tx_start_next = 1'b1;
                    tx_data_next = {7'd0, calc_res[8]};
                end
            end

            WAIT_SENDING_ANS_H: begin
                if (~tx_busy && ~tx_start) begin
                    state_next = WAIT_A_L;
                end
            end
        endcase
    end

    
endmodule
