module uart_tx #(
    parameter CLK_FREQ = 27,
    parameter BAUD_RATE = 115200
) (
    input logic clk_i,
    input logic rst_n_i,
    input logic [7:0] data_i,
    input logic start_i,
    output logic tx_wire_o,
    output logic busy_o
);

    localparam integer CYCLE   = CLK_FREQ * 1_000_000 / BAUD_RATE;
    localparam integer CYCLE_W = $clog2(CYCLE);
    localparam logic [CYCLE_W-1:0] CYCLE_MAX = CYCLE - 1;

    typedef enum logic [1:0] {
        IDLE,
        START,
        SEND_BIT,
        STOP
    } state_e;

    state_e state, state_next;

    logic [CYCLE_W-1:0] baud_cnt, baud_cnt_next;
    logic [2:0] bit_cnt, bit_cnt_next;

    logic baud_tick;
    assign baud_tick = (baud_cnt == CYCLE_MAX);

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= IDLE;
            bit_cnt <= 3'd0;
        end else begin
            state <= state_next;
            bit_cnt <= bit_cnt_next;
        end
    end

    always_ff @(posedge clk_i) begin
        if (~rst_n_i || (baud_cnt == CYCLE_MAX) || (state == IDLE)) begin
            baud_cnt <= 0;
        end else begin
            baud_cnt <= baud_cnt + 1'd1;
        end
    end

    always_comb begin
        if (state == IDLE)
            bit_cnt_next = 3'd0;
        else if (baud_tick) begin
            if (state == SEND_BIT && bit_cnt < 3'd7)
                bit_cnt_next = bit_cnt + 1'b1;
            else
                bit_cnt_next = 3'd0;
        end else
            bit_cnt_next = bit_cnt;
    end


    always_comb begin
        state_next = state;

        case (state)
            IDLE: begin
                if (start_i)
                    state_next = START;
            end

            START: begin
                if (baud_tick)
                    state_next = SEND_BIT;
            end

            SEND_BIT: begin
                if (baud_tick && (bit_cnt == 3'd7))
                    state_next = STOP;
            end

            STOP: begin
                if (baud_tick)
                    state_next = IDLE;
            end

            default: begin
                state_next = state;
            end
        endcase
    end

    // tx_wire_o
    always_comb begin
        case (state)
            IDLE:       tx_wire_o = 1'b1;
            START:      tx_wire_o = 1'b0;
            SEND_BIT:   tx_wire_o = data_i[bit_cnt];
            STOP:       tx_wire_o = 1'b1;
            default:    tx_wire_o = 1'b1;
        endcase
    end

    assign busy_o = (state != IDLE);

endmodule
