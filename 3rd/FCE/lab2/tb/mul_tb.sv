`timescale 1ns/1ps

module mul_tb;

    logic clk = 1'b0;
    logic rst_n = 1'b1;

    logic [5:0] a = 6'd40;
    logic [1:0] b = 2'd3;
    logic start = 1'd0;

    wire [7:0] res;
    wire is_busy;
    wire is_done;


    mul #(
         .A_W(6 /* default 6 */),
         .B_W(2 /* default 2 */)
      ) mul (
         .clk_i    (clk),
         .rst_n_i  (rst_n),
         .a_i      (a),
         .b_i      (b),
         .start_i  (start),
         .res_o    (res),
         .is_busy_o(is_busy),
         .is_done_o(is_done)
     ); 

   // Iverilog output for gtkwave 
   initial begin  
       $dumpfile("mul_tb.vcd"); 
       $dumpvars(0, mul_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #10 clk = ~clk; 
        end 
    end 

    integer a_i, expected;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        for (a_i = 0; a_i < 41; a_i += 1) begin
            // a_i = 32;
            a = a_i[5:0];
            expected = a_i * 3;

            start = 1'b1;
            @(posedge clk);
            #1;
            start = 1'b0;

            wait (is_done === 1'b1);
            #1;

            if (res !== expected[7:0]) begin
                $display("ERROR: a=%d  expected=%d  got=%d", a, expected, res);
                #10 $finish(); 
            end

            @(posedge clk);
            #1;
        end

        $display("Test PASSED");
        #10 $finish;
    end

    initial begin
        #1_000_000 $display("TIME OUT");
        $finish();
    end
endmodule
