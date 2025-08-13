`timescale 1ns/1ps


module uart_combined_tb;

    reg clk;
    reg rst_n;
    reg start_tx;
    reg [7:0] data_in;
    wire tx_line;
    wire tx_busy;
    wire [7:0] data_out;
    wire rx_ready;

    uart_combined #(.CYCLES_PER_BIT(16), .DATA_BITS(8)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_tx(start_tx),
        .data_in(data_in),
        .tx_line(tx_line),
        .tx_busy(tx_busy),
        .rx_in(tx_line),       
        .data_out(data_out),
        .rx_ready(rx_ready)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        start_tx = 0;
        data_in = 8'h00;
        #20;
        rst_n = 1;

        #20;
        data_in = 8'hA5;
        start_tx = 1;
        #10;
        start_tx = 0;

        wait (rx_ready);
        #20;

        data_in = 8'h3C;
        start_tx = 1;
        #10;
        start_tx = 0;

        wait (rx_ready);
        #40;

        $stop;
    end

endmodule
