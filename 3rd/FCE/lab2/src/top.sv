module top (
    input logic clk_i,
    input logic rst_n_i,

    input logic start_i,
    //input wire [15:0] a_i,
    //input wire [15:0] b_i,
    output wire tx_wire_o
);

    logic [7:0] data = 8'd131;
    wire busy;



    uart_tx #() uart_tx0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .data_i(data),
        .start_i(~start_i),
        .tx_wire_o(tx_wire_o),
        .busy_o(busy)
    );


    
endmodule
