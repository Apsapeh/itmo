module main #(
    parameter N = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire[N-1:0] a,
    input  wire[N-1:0] b,
    input  wire        sel,
    output reg[N-1:0]  y                  // flip-flop
);

    wire[N-1:0] y_w;
    mux2_n #(.N(N)) mux (
        .a(a), .b(b), .sel(sel), .y(y_w)
    );

	 
    always @(posedge clk) begin
        if (rst)
            y <= 0;
        else
            y <= y_w;
    end
    
endmodule
