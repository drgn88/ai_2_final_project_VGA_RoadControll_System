`timescale 1ns / 1ps

module tick_sec (

    input logic   clk,
    input logic   reset,
    output logic  tick_sec


);

    parameter F_COUNT = 100_000_000;  // 1초 
    logic [$clog2(F_COUNT)-1:0] r_counter;


    always_ff @(posedge clk, posedge reset) begin

        if (reset) begin
            r_counter  <= 0;
            tick_sec <= 0;
        end else begin

            if (r_counter == F_COUNT - 1) begin

                tick_sec <= 1'b1;
                r_counter  <= 0;
            end else begin
                tick_sec <= 1'b0;

                r_counter  <= r_counter + 1;
            end
        end
    end
endmodule

module mux_2x1 (
    input  logic traffic_sel,
    input  logic [4:0] a,
    input  logic [4:0] b,
    output logic [4:0] cnt_y

);

    always_comb begin
         cnt_y = a;
        case (traffic_sel)
            1'b0: begin
                cnt_y = a;

            end

            1'b1: begin
                cnt_y = b;
            end
           
        endcase


    end

endmodule



module TrafficLight_FSM (
    input logic clk,
    input logic tick_sec,
    input logic reset,
    input logic [4:0] howmany_count_red,
    input logic [4:0] howmany_count_green,
    input logic traffic_sel, //영상처리 유동랑 상태에 따른 SEL,
    output logic o_tr_light,  //신호 상태 
    output logic [1:0] o_tr_state,  //유동량 상태
    output logic tr_valid,
    output logic light_valid




);




    logic [4:0] red_count_reg, red_count_next;
    logic [4:0] green_count_reg, green_count_next;
    logic temp_tr_reg, temp_tr_next;
    logic tr_valid_reg, tr_valid_next;
    logic light_valid_reg, light_valid_next;

    assign o_tr_state = temp_tr_reg;
    assign tr_valid = tr_valid_reg;
    assign light_valid = light_valid_reg;

    

    typedef enum {
        RED,
        GREEN,
        UPDATE
    } signal_state;

    signal_state state, state_next;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state           <= UPDATE;
            red_count_reg   <= 0;
            green_count_reg <= 0;
            temp_tr_reg     <= 0;
            light_valid_reg <= 0;
            tr_valid_reg <= 0;

        end else begin
            state           <= state_next;
            red_count_reg   <= red_count_next;
            green_count_reg <= green_count_next;
            temp_tr_reg     <= temp_tr_next;
            light_valid_reg <= light_valid_next;
            tr_valid_reg    <= tr_valid_next;

        end
    end

    always_comb begin
        state_next = state;
        red_count_next = red_count_reg;
        green_count_next = green_count_reg;
        temp_tr_next = temp_tr_reg;
        light_valid_next = light_valid_reg;
        tr_valid_next = tr_valid_reg;
    
        case (state)

            UPDATE: begin
                red_count_next = 0;
                green_count_next = 0;
                o_tr_light = 1'b1;
                
                temp_tr_next = traffic_sel;
                tr_valid_next    = 1'b1; 
                light_valid_next = 1'b1; 
                
                
                state_next = RED;
 

            end

            RED: begin
                o_tr_light = 1'b0;  // 빨간불
                tr_valid_next = 1'b0; //valid 내려줌
                
                light_valid_next = 1'b0;
                if (red_count_reg == howmany_count_red) begin
                    state_next = GREEN;
     
                    light_valid_next = 1'b1;
                end
                else begin
                    if (tick_sec) red_count_next = red_count_reg + 1;
                end


            end


            GREEN: begin
                o_tr_light = 1'b1; // 초록불
                light_valid_next = 1'b0; //valid 내려줌
                if (green_count_reg == howmany_count_green) 
                    state_next = UPDATE;
                else begin
                    if (tick_sec) green_count_next = green_count_reg + 1;
                end
            end



        endcase
    end

 

endmodule
