`timescale 1ns/1ps


module uart_combined #(parameter CYCLES_PER_BIT = 434, parameter DATA_BITS = 8)
(
    input clk,
    input rst_n,
    input start_tx,
    input [DATA_BITS-1:0] data_in,
    output reg tx_line,
    output reg tx_busy,
    input rx_in,
    output reg [DATA_BITS-1:0] data_out,
    output reg rx_ready
);

// TX state machine
localparam TX_IDLE = 0, TX_START = 1, TX_SEND = 2, TX_STOP = 3;
reg [1:0] tx_state;
reg [31:0] tx_clk_count;
reg [3:0] tx_bit_no;
reg [DATA_BITS-1:0] tx_shift_reg;

// RX state machine
localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
reg [1:0] rx_state;
reg [31:0] rx_clk_count;
reg [3:0] rx_bit_idx;
reg [DATA_BITS-1:0] rx_shift_reg;

// Double flop synchronizer for rx_in to avoid metastability
reg r0, r1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r0 <= 1'b1;
        r1 <= 1'b1;
    end else begin
        r0 <= rx_in;
        r1 <= r0;
    end
end

// TX logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state <= TX_IDLE;
        tx_clk_count <= 0;
        tx_bit_no <= 0;
        tx_line <= 1'b1;
        tx_busy <= 1'b0;
        tx_shift_reg <= 0;
    end else begin
        case (tx_state)
            TX_IDLE: begin
                tx_line <= 1'b1;
                tx_busy <= 1'b0;
                tx_clk_count <= 0;
                tx_bit_no <= 0;
                if (start_tx) begin
                    tx_shift_reg <= data_in;
                    tx_busy <= 1'b1;
                    tx_state <= TX_START;
                end
            end
            TX_START: begin
                tx_line <= 1'b0;
                if (tx_clk_count < CYCLES_PER_BIT - 1)
                    tx_clk_count <= tx_clk_count + 1;
                else begin
                    tx_clk_count <= 0;
                    tx_state <= TX_SEND;
                end
            end
            TX_SEND: begin
                tx_line <= tx_shift_reg[tx_bit_no];
                if (tx_clk_count < CYCLES_PER_BIT - 1)
                    tx_clk_count <= tx_clk_count + 1;
                else begin
                    tx_clk_count <= 0;
                    if (tx_bit_no < DATA_BITS - 1)
                        tx_bit_no <= tx_bit_no + 1;
                    else
                        tx_state <= TX_STOP;
                end
            end
            TX_STOP: begin
                tx_line <= 1'b1;
                if (tx_clk_count < CYCLES_PER_BIT - 1)
                    tx_clk_count <= tx_clk_count + 1;
                else begin
                    tx_clk_count <= 0;
                    tx_state <= TX_IDLE;
                    tx_busy <= 1'b0;
                end
            end
            default: tx_state <= TX_IDLE;
        endcase
    end
end

// RX logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_state <= RX_IDLE;
        rx_clk_count <= 0;
        rx_bit_idx <= 0;
        data_out <= 0;
        rx_ready <= 1'b0;
        rx_shift_reg <= 0;
    end else begin
        case (rx_state)
            RX_IDLE: begin
                rx_ready <= 1'b0;
                rx_clk_count <= 0;
                rx_bit_idx <= 0;
                if (r1 == 1'b0)  // Start bit detected
                    rx_state <= RX_START;
            end
            RX_START: begin
                if (rx_clk_count < (CYCLES_PER_BIT / 2) - 1)
                    rx_clk_count <= rx_clk_count + 1;
                else begin
                    rx_clk_count <= 0;
                    if (r1 == 1'b0)
                        rx_state <= RX_DATA;
                    else
                        rx_state <= RX_IDLE;
                end
            end
            RX_DATA: begin
                if (rx_clk_count < CYCLES_PER_BIT - 1)
                    rx_clk_count <= rx_clk_count + 1;
                else begin
                    rx_clk_count <= 0;
                    rx_shift_reg[rx_bit_idx] <= r1;
                    if (rx_bit_idx < DATA_BITS - 1)
                        rx_bit_idx <= rx_bit_idx + 1;
                    else
                        rx_state <= RX_STOP;
                end
            end
            RX_STOP: begin
                if (rx_clk_count < CYCLES_PER_BIT - 1)
                    rx_clk_count <= rx_clk_count + 1;
                else begin
                    rx_clk_count <= 0;
                    data_out <= rx_shift_reg;
                    rx_ready <= 1'b1;
                    rx_state <= RX_IDLE;
                end
            end
            default: rx_state <= RX_IDLE;
        endcase
    end
end

endmodule
