`timescale 1ns/1ps

module tb ();

    parameter N = 8;
    parameter C = 15;

    reg          clk = 1'b0;
    reg          rst = 1'b1;
    reg  [N-1:0] a;
    reg  [N-1:0] b;
    reg          sel;
    wire [N-1:0] y;

    main #(.N(N)) dut (
        .clk(clk), .rst(rst), .a(a), .b(b), .sel(sel), .y(y)
    ); 

	 // Iverilog output for gtkwave
    initial begin
        $dumpfile("mux2.vcd");
        $dumpvars(0, tb);
    end

	 // Clock with freq (100 MHz) 
    initial begin
        forever begin
            #5 clk = ~clk;
        end
    end

    integer i;
    reg [N-1:0] expected;
    initial begin
        a = 0;
        b = 0;
        sel = 0;
        #6 rst = 0; // 6 cuz first posedge 0->1 (5ns) + 1ns to stabilize

        for (i = 0; i < C; i = i + 1) begin
            a = $random;
            b = $random;
            sel = $random;

            expected = sel ? b : a;

            @(posedge clk); // Wait for clk 0->1 and 1ns to update values
            #1;

            if (y !== expected)
                $display("Error sel=%b a=%d b=%d expected=%d got=%d", sel, a, b, expected, y);
            else
                $display("Ok: sel=%b a=%d b=%d y=%d", sel, a, b, y); 
        end

        // Rst check 
        rst = 1;
        @(posedge clk);
        #1;
        if (y !== 0)
            $display("Error: rst");
        else
            $display("Ok: rst");

        #10 $finish;
    end

endmodule
