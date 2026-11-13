`timescale 1ns/1ps

module uart_tx_tb;

    logic clk = 1'b0;
    logic rst_n = 1'b1;
    logic [7:0] data;
    logic start;

    wire tx_wire;
    wire busy;

    uart_tx #(
        .CLK_FREQ(50),
        .BAUD_RATE(100_000)
    ) dut (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .data_i(data),
        .start_i(start),
        .tx_wire_o(tx_wire),
        .busy_o(busy)
    ); 

   // Iverilog output for gtkwave 
   initial begin  
       $dumpfile("uart_tb.vcd"); 
       $dumpvars(0, uart_tx_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #10 clk = ~clk; 
        end 
    end 

    integer i;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        data = $random;
        // data = 8'b01010101;
        // data = 8'b11111111;
        start = 1'b1;

        // wait for start bit
        @(posedge clk);
        #1;
        if (tx_wire !== 1'b0)
            $display("Error start bit");

        
        for (i = 0; i < 8; i = i + 1) begin
             #10_000;

             if (tx_wire !== data[i])
                 $display("Error data bit[%d]: expected=%b got=%b", i, data[i], tx_wire);

             if (busy === 1'b0)
                 $display("Done at %d)", i);
        end

        // wait for stop bit
        #10_000;
        if (tx_wire != 1'b1)
            $display("Error stop bit");

        // wait for stop transimition
        #10_000;

        if (busy !== 1'b0)
            $display("Error: Must be not busy");

        #10 $finish;
    end
endmodule
