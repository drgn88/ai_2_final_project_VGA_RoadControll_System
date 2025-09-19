`timescale 1ns / 1ps

module Label_Gen (
    input  logic [7:0] s_data,
    input  logic [7:0] v_data,
    input  logic [1:0] r_g_decision,
    output logic [2:0] label_data
);
    //0: 빨간색-차 1: 초록색-사람 2: 아무것도 아님

    localparam ROAD = 0;
    localparam WALK_ROAD = 1;
    localparam BACKGROUND = 2;
    localparam CAR = 3;
    localparam HUMAN = 4;

    //V: Brightness S: Saturation
    localparam ROAD_V_THRESHOLD = 38;
    localparam ROAD_S_THRESHOLD = 77;
    localparam WALK_V_THRESHOLD = 179;
    localparam WALK_S_THRESHOLD = 51;

    always_comb begin
        if (r_g_decision == 0) begin
            label_data = CAR;
        end 
        else if (r_g_decision == 1) begin
            label_data = HUMAN;
        end 
        else if ((v_data >= WALK_V_THRESHOLD) && (s_data <= WALK_S_THRESHOLD)) begin
            label_data = WALK_ROAD;
        end
        else if((v_data <= ROAD_V_THRESHOLD) && (s_data <= ROAD_S_THRESHOLD)) begin
            label_data = ROAD;
        end 
        else begin
            label_data = BACKGROUND;
        end
    end
endmodule
