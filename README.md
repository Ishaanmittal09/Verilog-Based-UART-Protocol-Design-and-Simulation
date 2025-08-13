# Verilog-Based-UART-Protocol-Design-and-Simulation

This repository contains a Verilog implementation of a UART communication system with both transmitter (TX) and receiver (RX) logic combined into a single module. The design is parameterized for easy adjustment of baud rate and data bits.

## Project Contents

- `uart_combined.v` — Combined UART TX and RX module in Verilog.
- `uart_combined_tb.v` — Basic testbench to simulate UART transmission and reception with loopback.

## How to simulate

1. Open the testbench file `uart_combined_tb.v` in your simulator (Vivado, ModelSim, etc.).
2. Run simulation and observe `tx_line` output transmitting data serially.
3. The receiver monitors `tx_line` as input and captures received data on `data_out`.
4. `rx_ready` signal indicates when valid data has been received.
5. Use waveform viewer to check timing, start/stop bits, and data correctness.
