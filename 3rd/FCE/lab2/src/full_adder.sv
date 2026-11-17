module full_adder (
    input  logic a_i,
    input  logic b_i,
    input  logic c_i,
    output logic s_o,
    output logic c_o
);

    logic ab_s, ab_c;
    half_adder ab_adder (
        .a_i(a_i),
        .b_i(b_i),
        .s_o(ab_s),
        .c_o(ab_c)
    );

    logic c_ab_s, c_ab_c;
    half_adder c_ab_adder (
        .a_i(c_i),
        .b_i(ab_s),
        .s_o(c_ab_s),
        .c_o(c_ab_c)
    );

    assign s_o = c_ab_s;
    assign c_o = ab_c | c_ab_c;

endmodule
