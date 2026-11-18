`timescale 1ns/1ps

module add_tb;

    localparam W = 6;
    localparam C = int'($pow(2, W));

    logic clk = 1'b0;
    logic rst_n = 1'b1;

    logic [W-1:0] a = 0;
    logic [W-1:0] b = 0;
    logic start = 1'd0;

    wire [W:0] res;
    wire is_busy;
    wire is_done;


    add #(
         .W(6 /* default 6 */)
    ) dut (
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
       $dumpfile("add_tb.vcd"); 
       $dumpvars(0, add_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #10 clk = ~clk; 
        end 
    end 

    integer a_i, b_i, expected;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        for (a_i = 0; a_i < C; a_i += 1) begin
            for (b_i = 0; b_i < C; b_i += 1) begin
                a = a_i[W-1:0];
                b = b_i[W-1:0];
                expected = a_i + b_i;

                start = 1'b1;
                @(posedge clk);
                #1;
                start = 1'b0;

                wait (is_done === 1'b1);
                #1

                if (res != expected[W:0]) begin
                    $display("ERROR: a=%d  b=%d  expected=%d  got=%d", a, b, expected, res);
                    #10 $finish();                     
                end

                @(posedge clk);
                #1;
            end 
        end

        $display("Test PASSED");
        #10 $finish;
    end

    initial begin
        #1_000_000 $display("TIME OUT");
        $finish();
    end
endmodule
