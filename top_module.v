`timescale 1ns / 1ps

module top_module(
    input clk,
    input reset,
    input rx,
    output tx,
    input en,
    output [7:0] cdata,
    input [7:0] odata,
    output empty
    );

    reg [7:0] pipeline;

    wire [7:0] w_rx_data;
    wire [7:0] w_tx_data_1;
    wire [7:0] w_tx_data_2;
    wire [7:0] w_data;
    wire rx_done2wr;
    wire empty2start;
    wire done2rd;
    wire full;

    assign w_tx_data_2 = w_tx_data_1;

    fifo tx_fifo(
        .clk(clk),
        .reset(reset),
        .wr(en & (!full)),
        .rd(!done2rd),
        .wdata(odata),
        .rdata(w_tx_data_1),
        .full(full),
        .empty(empty2start)
    );

    fifo rx_fifo(
        .clk(clk),
        .reset(reset),
        .wr(rx_done2wr),
        .rd(~empty),
        .wdata(w_rx_data),
        .rdata(cdata),
        //.full(),
        .empty(empty)
    );

    uart u_uart(
        .clk(clk),
        .rst(reset),
    // tx
        .btn_start(!empty2start),
        .data_in(w_tx_data_2),
        .tx(tx),
        .tx_done(done2rd),
    // rx
        .rx(rx),
        .rx_done(rx_done2wr),
        .rx_data(w_rx_data)
    );

endmodule
