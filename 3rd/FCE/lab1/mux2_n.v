module mux2_n #(
    parameter N = 8
) (
    input  wire[N-1:0] a,
    input  wire[N-1:0]  b,
    input  wire         sel,
    output wire[N-1:0]  y
);
 
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_mux2 
            mux2_assign m (
                .a(a[i]),
                .b(b[i]),
                .sel(sel),
                .y(y[i])
            );
        end
    endgenerate

endmodule
