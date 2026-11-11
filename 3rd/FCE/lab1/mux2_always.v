module mux2_always (
    input  wire a,
    input  wire b,
    input  wire sel,
    output reg y 
);

    always @* begin
        if (sel)
            y = b;
        else
            y = a;
    end

endmodule
