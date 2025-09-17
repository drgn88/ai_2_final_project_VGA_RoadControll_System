`timescale 1ns / 1ps



module Signal_CU(
    input logic clk,
    input logic reset,
    input logic traffic_sel,
    output logic o_tr_light,
    output logic o_tr_state,
    output logic tr_valid,
    output logic light_valid


    );

    logic [4:0] w_count_red, w_count_green;
    logic w_tick_sec;

 tick_sec U_TICK_SEC(

    .clk(clk),
    .reset(reset),
    .tick_sec(w_tick_sec)


);

 mux_2x1 U_MUX_FOR_RED_CNT(
    .traffic_sel(o_tr_state),
     .a(30),
     .b(10),
    
     .cnt_y(w_count_red)

);
 mux_2x1 U_MUX_FOR_GREEN_CNT(
    .traffic_sel(o_tr_state),
     .a(10),
     .b(30),
    
    .cnt_y(w_count_green)

);

TrafficLight_FSM U_TR_FSM(
    .clk(clk),
    .tick_sec(w_tick_sec),
    .reset(reset),
    .howmany_count_red(w_count_red),
    .howmany_count_green(w_count_green),
    .traffic_sel(traffic_sel), //영상처리 유동랑 상태에 따른 SEL,
    .o_tr_light(o_tr_light),  //신호 상태 
    .o_tr_state(o_tr_state),  //유동량 상태
    .tr_valid(tr_valid),
    .light_valid(light_valid)




);




endmodule
