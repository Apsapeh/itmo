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
        WAIT_B_L,
        WAIT_CALC,
        WAIT_SENDING_ANS
    } state_e;

    state_e state, state_next;
    logic [7:0] a, a_next, b, b_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            a <= 8'b0;
            b <= 8'b0;
            state <= WAIT_A_L;
        end else begin
            a <= a_next;
            b <= b_next;
            state <= state_next;
        end
    end

    // UART RX
    logic rx_confirm, rx_confirm_next;
    wire [7:0] rx_data;
    wire rx_is_ready; 

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            rx_confirm <= 1'b0;
        end else if (rx_confirm) begin  // Oneshot confirmation
            rx_confirm <= 1'b0;
        end else begin
            rx_confirm <= rx_confirm_next;
        end
    end

    uart_rx #() uart_rx0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .rx_wire_i(rx_wire_i),
        .confirm_i(rx_confirm),
        .data_o(rx_data),
        .is_ready_o(rx_is_ready)
    );

    // UART TX
    logic [7:0] tx_data, tx_data_next;
    logic       tx_start, tx_start_next;
    wire        tx_busy;

    uart_tx #() uart_tx0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .data_i(tx_data),
        .start_i(tx_start),
        .tx_wire_o(tx_wire_o),
        .busy_o(tx_busy)
    );

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            tx_data  <= 8'b0;
            tx_start <= 1'b0;
        end else begin
            tx_data  <= tx_data_next;
            if (tx_start) begin         // Oneshot transmission starting
                tx_start <= 1'b0;
            end else begin
                tx_start <= tx_start_next;
            end
        end
    end

    assign tx_data_next = a + b;
   
    always_comb begin
        state_next = state;
        a_next = a;
        b_next = b;
        rx_confirm_next = rx_confirm;
        tx_start_next = tx_start;

        case (state)
            WAIT_A_L: begin
                if (rx_is_ready) begin
                    a_next = rx_data;
                    rx_confirm_next = 1'b1;
                    state_next = WAIT_B_L;
                end
            end

            WAIT_B_L: begin
                if (rx_is_ready && ~rx_confirm) begin
                    b_next = rx_data;
                    rx_confirm_next = 1'b1;
                    state_next = WAIT_CALC;
                end
            end

            WAIT_CALC: begin
                state_next = WAIT_SENDING_ANS;
                tx_start_next = 1'b1;
            end

            WAIT_SENDING_ANS: begin
                if (~tx_busy) begin
                    state_next = WAIT_A_L;
                end
            end
        endcase
    end

    
endmodule
