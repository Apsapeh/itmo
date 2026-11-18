`timescale 1ns/1ps

module calc_tb;

    localparam C = 15;

    logic clk = 1'b0;
    logic rst_n = 1'b1;

    logic [15:0] a = 0;
    logic [15:0] b = 0;
    logic start = 1'd0;

    wire [8:0] res;
    wire is_busy;
    wire is_done;


    calc dut (
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
       $dumpfile("calc_tb.vcd"); 
       $dumpvars(0, calc_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #5 clk = ~clk; 
        end 
    end 

    localparam V_C = 5;
    logic [31:0] vec[V_C-1:0];

    initial begin
       vec[0] = {16'd0,        16'd0}; 
       vec[1] = {16'd1,        16'd1}; 
       vec[2] = {16'd0,        16'd65535}; 
       vec[3] = {16'd65535,    16'd0}; 
       vec[4] = {16'd65535,    16'd65535}; 
    end

    integer a_i, e_c, e_s, expected;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        for (a_i = 0; a_i < C; a_i += 1) begin
            if (a_i < C - V_C) begin
                a = $random;
                b = $random;        
            end else begin
                a = vec[a_i - (C - V_C)][31:16];
                b = vec[a_i - (C - V_C)][15:0];
            end

            e_c = int'($floor(real'(a) ** (1.0/3.0) + 1.0e-9));
            e_s = int'($floor($sqrt(real'(b))));
            expected = e_c + e_s;

            start = 1'b1;
            @(posedge clk);
            #1;
            start = 1'b0;

            wait (is_done === 1'b1);
            #1

            if (res != expected[8:0]) begin
                $display("ERROR: a=%d  b=%d  expected=%d  got=%d", a, b, expected, res);
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
