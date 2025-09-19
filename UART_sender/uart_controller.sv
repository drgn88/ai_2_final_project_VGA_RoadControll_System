`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/22 11:24:16
// Design Name: 
// Module Name: uart_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_controller (
    input logic       clk,
    input logic       reset,
    input logic [7:0] tx_push_data,
    input logic       rx,
    input logic       tx_push,

    input  logic       rx_pop,
    output logic       rx_done,
    output logic       rx_empty,
    output logic       tx_done,
    output logic       tx_full,
    output logic [7:0] rx_pop_data,
    output logic       tx,
    output logic       tx_busy

);


    logic w_bd_tick, w_rx_done, w_tx_busy, w_tx_start;
    logic [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data;
    assign rx_done = w_rx_done;
    assign rx_data = w_rx_data;
    assign tx_busy = w_tx_busy;

    baud_rate U_BR (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_bd_tick)
    );


    uart_tx U_TX (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_bd_tick),
        .start(~w_tx_start),
        .din(w_tx_pop_data),
        .o_tx_done(tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );


    uart_rx U_RX (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .b_tick(w_bd_tick),
        .o_rx_done(w_rx_done),
        .o_dout(w_rx_data)
    );




    //===============================FIFO==================================
    fifo U_RX_FIFO (
        .clk      (clk),
        .reset    (reset),
        .push     (w_rx_done),
        .pop      (~rx_empty),   //rx fifo pop
        .push_data(w_rx_data),   //==============8bit
        .full     (),            //don't use
        .empty    (rx_empty),    //rx fifo empty
        .pop_data (rx_pop_data)  // pop data

    );




    fifo U_TX_FIFO (
        .clk(clk),
        .reset(reset),
        .push(tx_push),
        .pop(~w_tx_busy),
        .push_data(tx_push_data),
        .full(tx_full),
        .empty(w_tx_start),  //empty가 아니면 계속 보내겠다.
        .pop_data(w_tx_pop_data)

    );



endmodule
