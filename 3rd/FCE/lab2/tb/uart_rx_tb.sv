`timescale 1ns/1ps

module uart_rx_tb;

    logic clk = 1'b0;
    logic rst_n = 1'b1;
    logic rx_wire;
    logic confirm = 1'b0;

    wire [7:0] data;
    wire is_ready;

    uart_rx #(
        .CLK_FREQ(50),
        .BAUD_RATE(100_000)
    ) dut (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .rx_wire_i(rx_wire),
        .confirm_i(confirm),
        .data_o(data),
        .is_ready_o(is_ready)
    ); 

   // Iverilog output for gtkwave 
   initial begin  
       $dumpfile("uart_rx.vcd"); 
       $dumpvars(0, uart_rx_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #10 clk = ~clk; 
        end 
    end 

    integer i;
    integer d_i;
    logic [7:0] test_data;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        for (d_i = 0; d_i < 256; d_i = d_i + 1) begin
            test_data = d_i[7:0];

            // idle 
            rx_wire = 1'b1;
            #3000;

            // start receiving
            rx_wire = 1'b0;
            #10_000;

            if (is_ready === 1'b1) begin
                $display("Test FAILED: too early done receiving");
                $finish;
            end

            for (i = 0; i < 8; i = i + 1) begin
                rx_wire = test_data[i];
                #10_000;

                if (is_ready === 1'b1) begin
                    $display("Test FAILED: too early done receiving");
                    $finish;
                end
            end

            // receiving stop bit
            rx_wire = 1'b1;
            #10_000;

            #100;
            if (is_ready !== 1'b1) begin
                $display("Test FAILED: isn't done");
                $finish;
            end

            confirm = 1'b1;

            if (data !== test_data) begin
                $display("Test FAILED: expected=%d got=%d", test_data, data);
                $finish;
            end

            @(posedge clk);
            confirm = 1'b0;

        end


        $display("Test PASSED");
        #10 $finish;
    end
endmodule
