`timescale 1ns/1ps

module uart_tx_rx_tb;

    // tx
    logic tx_clk = 1'b0;
    logic tx_rst_n = 1'b1;
    logic tx_start, tx_busy;

    // rx
    logic rx_clk = 1'b0;
    logic rx_rst_n = 1'b1;
    logic rx_confirm = 1'b0;
    logic rx_is_ready;

    logic [7:0] data_in;
    wire  [7:0] data_out;
    wire data_wire;
    pullup(data_wire);

    uart_tx #(
        .CLK_FREQ(50),
        .BAUD_RATE(100_000)
    ) dut_tx (
        .clk_i(tx_clk),
        .rst_n_i(tx_rst_n),
        .data_i(data_in),
        .start_i(tx_start),
        .tx_wire_o(data_wire),
        .busy_o(tx_busy)
    ); 

    uart_rx #(
        .CLK_FREQ(50),
        .BAUD_RATE(100_000)
    ) dut_rx (
        .clk_i(rx_clk),
        .rst_n_i(rx_rst_n),
        .rx_wire_i(data_wire),
        .confirm_i(rx_confirm),
        .data_o(data_out),
        .is_ready_o(rx_is_ready)
    );



   // Iverilog output for gtkwave 
   initial begin  
       $dumpfile("uart_tx_rx.vcd"); 
       $dumpvars(0, uart_tx_rx_tb); 
    end  

    // Clock tx with freq (100 MHz) and offset 103ns
    initial begin 
        #103;
        forever begin  
            #10 tx_clk = ~tx_clk; 
        end 
    end 

    // Clock rx with freq (100 MHz)
    initial begin  
        forever begin  
            #10 rx_clk = ~rx_clk; 
        end 
    end

    // Start tx
    integer t_i;
    initial begin
        tx_rst_n = 1'b0;
        @(posedge tx_clk);
        #1;
        tx_rst_n = 1'b1;

        for (t_i = 0; t_i < 256; t_i = t_i + 1) begin
            data_in = t_i[7:0];
            // data_in = 8'b1000_0001;

            #(500 + ($abs($random) % 1000));
            tx_start = 1'b1;

            #(500 + ($abs($random) % 1000));
            tx_start = 1'b0;

            wait (tx_busy === 1'b0);
            // $display("Sent %d", data_in);
            
            #(5000 + ($abs($random) % 1000));
        end

        // $finish;
    end

    // Start rx
    integer r_i;
    initial begin
        rx_rst_n = 1'b0;
        @(posedge rx_clk);
        #1;
        rx_rst_n = 1'b1;

        for (r_i = 0; r_i < 256; r_i = r_i + 1) begin
            $display("Waiting %d", r_i[7:0]);
            wait (rx_is_ready === 1'b1);

            #1;
            
            rx_confirm = 1'b1;
            @(posedge rx_clk);

            if (data_out !== r_i[7:0]) begin
                $display("ERROR: expected=%d  got=%d", r_i[7:0], data_out);
                #100 $finish;
            end

            // @(posedge rx_clk);
            #1 rx_confirm = 1'b0;
        end

        $display("PASSED");
        $finish;
    end 
endmodule
