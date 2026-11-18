`timescale 1ns/1ps

module cbrt_tb;

    localparam W = 16;
    localparam R_W = 6;
    localparam C = int'($pow(2, W));

    logic clk = 1'b0;
    logic rst_n = 1'b1;

    logic [W-1:0] x = 0;
    logic start = 1'd0;

    wire [R_W-1:0] res;
    wire is_busy;
    wire is_done;


    cbrt #(
    ) dut (
         .clk_i    (clk),
         .rst_n_i  (rst_n),
         .x_i      (x),
         .start_i  (start),
         .res_o    (res),
         .is_busy_o(is_busy),
         .is_done_o(is_done)
     ); 

   // Iverilog output for gtkwave 
   initial begin  
       $dumpfile("cbrt_tb.vcd"); 
       $dumpvars(0, cbrt_tb); 
    end  

    // Clock with freq (100 MHz)
    initial begin  
        forever begin  
            #10 clk = ~clk; 
        end 
    end 

    integer x_i, expected;
    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;

        for (x_i = 0; x_i < C; x_i += 1) begin
            $display("Testing cbrt [%d / %d]...", x_i, C-1);

            x = x_i[W-1:0];
            expected = int'($floor(real'(x_i) ** (1.0/3.0) + 1.0e-9));

            start = 1'b1;
            @(posedge clk);
            #1;
            start = 1'b0;

            wait (is_done === 1'b1);
            #1

            if (res != expected[W:0]) begin
                $display("ERROR: x=%d  expected=%d  got=%d", x, expected, res);
                #10 $finish();                     
            end

            @(posedge clk);
            #1;
        end

        $display("Test PASSED");
        #10 $finish;
    end

    initial begin
        #150_000_000 $display("TIME OUT");
        $finish();
    end
endmodule
