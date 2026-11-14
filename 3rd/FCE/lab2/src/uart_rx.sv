module uart_rx #(
    parameter CLK_FREQ = 27,
    parameter BAUD_RATE = 115200
) (
    input logic clk_i,
    input logic rst_n_i,
    input logic rx_wire_i,
    input logic confirm_i,
    output logic [7:0] data_o,
    output logic is_ready_o
);

    localparam integer CYCLE   = CLK_FREQ * 1_000_000 / BAUD_RATE;
    localparam integer CYCLE_W = $clog2(CYCLE);
    localparam logic [CYCLE_W-1:0] CYCLE_MAX = CYCLE - 1;
    localparam logic [CYCLE_W-1:0] CYCLE_MAX_HALF = CYCLE_MAX / 2;

    typedef enum logic [2:0] {
        WAIT_START,
        WAIT_START_MID,
        WAIT_BIT,
        WAIT_STOP,
        WAIT_CONFIRM
    } state_e;

    state_e state, state_next;
    logic [CYCLE_W-1:0] baud_cnt, baud_cnt_next;
    logic baud_cnt_enable, baud_cnt_enable_next;
    logic [2:0] bit_cnt, bit_cnt_next;
    logic [7:0] data_buf;
    logic is_ready_next;

    always_ff @(posedge clk_i) begin
        if (~rst_n_i) begin
            state <= WAIT_START;
            baud_cnt <= 0;
            bit_cnt <= 3'd0;
            is_ready_o <= 1'b0;
        end else begin
            state <= state_next;
            baud_cnt <= baud_cnt_next;
            bit_cnt <= bit_cnt_next;
            is_ready_o <= is_ready_next;
        end
    end

    logic baud_tick;
    assign baud_tick = (baud_cnt == CYCLE_MAX); 

    // Baud cycle counter
    always_comb begin
        if (state == WAIT_START) begin
            baud_cnt_next = CYCLE_MAX_HALF;
        end else if (state == WAIT_START_MID && baud_tick) begin // Wait half of baud cycle and reset timer
            baud_cnt_next = 0;
        end else if (baud_cnt == CYCLE_MAX) begin
            baud_cnt_next = 0;
        end else begin
            baud_cnt_next = baud_cnt + 1'd1;
        end
    end

    // Data bit counter
    always_comb begin
        if (state == WAIT_BIT) begin
            if (baud_tick) begin
                bit_cnt_next = bit_cnt + 1'd1;
            end else begin
                bit_cnt_next = bit_cnt;
            end
        end else begin
            bit_cnt_next = 3'd0;
        end
    end

    // UART FSM
    always_comb begin
        state_next = state;
        is_ready_next = is_ready_o;

        case (state)
            WAIT_START: begin
                if (~rx_wire_i) begin
                    state_next = WAIT_START_MID;
                    is_ready_next = 1'b0;
                end
            end

            WAIT_START_MID: begin
                if (baud_tick)
                    state_next = WAIT_BIT;
            end

            WAIT_BIT: begin
                if (baud_tick && bit_cnt == 3'd7)
                    state_next = WAIT_STOP;
            end

            WAIT_STOP: begin
                if (baud_tick) begin
                    state_next = WAIT_CONFIRM;
                    is_ready_next = 1'b1;
                end
            end

            WAIT_CONFIRM: begin
                if (confirm_i) begin
                    state_next = WAIT_START;
                    is_ready_next = 1'b0;
                end
            end

            default: state_next = WAIT_START;
        endcase
    end

    // Write data to internal buf
    always_ff @(posedge clk_i) begin
        if (~rst_n_i)
            data_buf <= 8'd0;
        else if (state == WAIT_BIT && baud_tick)
            data_buf <= {rx_wire_i, data_buf[7:1]} ;
    end

    // Export buf when receiving is done
    always_ff @(posedge clk_i) begin
        if (~rst_n_i)
            data_o <= 8'd0;
        else if (is_ready_next)
            data_o <= data_buf;
    end

endmodule;
