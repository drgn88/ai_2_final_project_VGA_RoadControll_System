`timescale 1ns / 1ps

module Decision_CrossWalk (
    input  logic       clk,
    input  logic       pclk,
    input  logic       reset,
    input  logic       imgShow,
    input  logic       v_finish,
    input  logic [2:0] label_data,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [9:0] x_min_fix,
    output logic [9:0] x_max_fix,
    output logic [9:0] y_min_fix,
    output logic [9:0] y_max_fix,
    //output logic       coord_valid,
    //For Detect Moving module
    input  logic       tr_light_tick,
    input  logic       tr_light,
    output logic [9:0] x_min_traffic,
    output logic [9:0] x_max_traffic,
    output logic [9:0] y_min_traffic,
    output logic [9:0] y_max_traffic,
    output logic       car_detection_en,
    output logic       human_detection_en,
    input  logic       sw_sel,
    output logic       fix_coord_valid
);

    logic       counter_valid;

    logic [9:0] x_min_find;
    logic [9:0] x_max_find;
    logic [9:0] y_min_find;
    logic [9:0] y_max_find;
    logic       find_done;

    logic [9:0] x_min_final;
    logic [9:0] x_max_final;
    logic [9:0] y_min_final;
    logic [9:0] y_max_final;

    logic       o_valid;

    assign fix_coord_valid = o_valid;

    Counter_Crosswalk U_Counter_Crosswalk (
        .pclk      (pclk),          //pclk
        .reset     (reset),
        .imgShow   (imgShow),
        .label_data(label_data),
        .valid     (counter_valid)
    );

    find_coord U_find_coord (
        .pclk      (pclk),           //pclk
        .reset     (reset),
        .imgShow   (imgShow),
        .valid     (counter_valid),
        .v_finish  (v_finish),
        .label_data(label_data),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .x_min     (x_min_find),
        .x_max     (x_max_find),
        .y_min     (y_min_find),
        .y_max     (y_max_find),
        .done      (find_done)
    );

    final_coord_out U_final_coord_out (
        .clk(clk),
        .pclk(pclk),
        .reset(reset),
        .valid(find_done),
        .v_finish(v_finish),
        .x_min(x_min_find),
        .x_max(x_max_find),
        .y_min(y_min_find),
        .y_max(y_max_find),
        .x_min_final(x_min_final),
        .x_max_final(x_max_final),
        .y_min_final(y_min_final),
        .y_max_final(y_max_final),
        .coord_valid(coord_valid)
    );

    // ila_1 U_ila_1 (
    //     .clk(clk),
    //     .probe0(pclk),
    //     .probe1(coord_valid)
    // );

    switch_sel_coord U_switch_sel_coord (
        .clk(clk),
        .reset(reset),
        .sw_sel(sw_sel),
        .valid(coord_valid),
        .x_min(x_min_final),
        .x_max(x_max_final),
        .y_min(y_min_final),
        .y_max(y_max_final),
        .x_min_fix(x_min_fix),
        .x_max_fix(x_max_fix),
        .y_min_fix(y_min_fix),
        .y_max_fix(y_max_fix),
        .o_valid(o_valid)
    );


    detection_cnt_en U_detection_cnt_en (
        .clk(clk),
        .reset(reset),
        .tr_light_tick(tr_light_tick),
        .tr_light(tr_light),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .x_min(x_min_fix),
        .x_max(x_max_fix),
        .y_min(y_min_fix),
        .y_max(y_max_fix),
        .x_min_traffic(x_min_traffic),
        .x_max_traffic(x_max_traffic),
        .y_min_traffic(y_min_traffic),
        .y_max_traffic(y_max_traffic),
        .car_detection_en(car_detection_en),
        .human_detection_en(human_detection_en)
    );

endmodule

module Counter_Crosswalk (
    input  logic       pclk,        //pclk
    input  logic       reset,
    input  logic       imgShow,
    input  logic [2:0] label_data,
    output logic       valid
);

    //localparam THRESHOLD_CROSSWALKLABEL = 85;
    localparam THRESHOLD_CROSSWALKLABEL = 85;
    localparam CROSSWALK = 1;
    // localparam CROSSWALK = 2;  //TEST
    logic [8:0] cw_label_count;
    logic decision;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            cw_label_count <= 0;
        end else begin
            if (imgShow) begin
                if (label_data == CROSSWALK) begin
                    cw_label_count <= cw_label_count + 1;
                end
            end else begin
                cw_label_count <= 0;
            end
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            decision <= 0;
            valid <= 0;
        end else if (!imgShow) begin
            decision <= 0;
            valid <= decision;
        end else if (cw_label_count >= THRESHOLD_CROSSWALKLABEL) begin
            decision <= 1;
        end
    end

endmodule

module find_coord (
    input  logic       pclk,        //pclk
    input  logic       reset,
    input  logic       imgShow,
    input  logic       valid,
    input  logic       v_finish,
    input  logic [2:0] label_data,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [9:0] x_min,
    output logic [9:0] x_max,
    output logic [9:0] y_min,
    output logic [9:0] y_max,
    output logic       done
);

    localparam CROSSWALK = 1;

    logic find_crosswalk;
    logic first_catch_xy;
    logic first_val_line;
    logic [9:0] x_min_tmp, y_min_tmp;
    logic [9:0] x_min_final, y_min_final;

    logic [9:0] x_max_tmp, y_max_tmp;
    logic [9:0] x_max_final, y_max_final;

    assign find_crosswalk = (imgShow && (label_data == CROSSWALK)) ? 1 : 0;

    assign x_min = x_min_final;
    assign y_min = y_min_final;
    assign x_max = x_max_final;
    assign y_max = y_max_final;

    //     /******************************************************************************/
    //     /******************************FIND MIN COORD***********************/
    //     /******************************************************************************/

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            first_catch_xy <= 0;
            x_min_tmp <= 0;
            y_min_tmp <= 0;
        end else if (!first_catch_xy && find_crosswalk) begin
            first_catch_xy <= 1;
            x_min_tmp <= x_pixel;
            y_min_tmp <= y_pixel;
        end else if (!imgShow) begin
            first_catch_xy <= 0;
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            first_val_line <= 0;
            x_min_final    <= 0;
            y_min_final    <= 0;
        end else if (!first_val_line && valid) begin
            first_val_line <= 1;
            x_min_final    <= x_min_tmp;
            y_min_final    <= y_min_tmp;
        end else if (v_finish) begin
            first_val_line <= 0;
        end
    end

    //     /******************************************************************************/
    //     /******************************FIND MAX COORD***********************/
    //     /******************************************************************************/

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            x_max_tmp <= 0;
            y_max_tmp <= 0;
        end else if (find_crosswalk) begin
            x_max_tmp <= x_pixel;
            y_max_tmp <= y_pixel;
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            x_max_final <= 0;
            y_max_final <= 0;
        end else if (valid) begin
            if (y_max_final <= y_max_tmp) begin
                x_max_final <= x_max_tmp;
                y_max_final <= y_max_tmp;
            end
        end else if (done) begin
            x_max_final <= 0;
            y_max_final <= 0;
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            done <= 0;
        end else if (v_finish) begin
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule

module final_coord_out (
    input  logic       clk,
    input  logic       pclk,
    input  logic       reset,
    input  logic       valid,
    input  logic       v_finish,
    input  logic [9:0] x_min,
    input  logic [9:0] x_max,
    input  logic [9:0] y_min,
    input  logic [9:0] y_max,
    output logic [9:0] x_min_final,
    output logic [9:0] x_max_final,
    output logic [9:0] y_min_final,
    output logic [9:0] y_max_final,
    output logic       coord_valid
);

    // 90프레임마다 좌표 업데이트
    localparam FRAME_MAX = 90;

    logic [6:0] frame_cnt;
    logic [9:0] x_min_tmp, y_min_tmp, x_max_tmp, y_max_tmp;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            frame_cnt <= 0;
        end else if (v_finish) begin
            if (frame_cnt == (FRAME_MAX - 1)) begin
                frame_cnt <= 0;
            end else begin
                frame_cnt <= frame_cnt + 1;
            end
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            x_min_tmp <= 0;
            y_min_tmp <= 0;
            x_max_tmp <= 0;
            y_max_tmp <= 0;
        end else if (valid) begin
            if (frame_cnt == (FRAME_MAX - 2)) begin
                x_min_tmp <= x_min;
                y_min_tmp <= y_min;
                x_max_tmp <= x_max;
                y_max_tmp <= y_max;
            end
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            x_min_final <= 0;
            x_max_final <= 0;
            y_min_final <= 0;
            y_max_final <= 0;
        end else if (frame_cnt == (FRAME_MAX - 1)) begin
            x_min_final <= x_min_tmp;
            x_max_final <= x_max_tmp;
            y_min_final <= y_min_tmp;
            y_max_final <= y_max_tmp;
        end
    end

    logic coord_valid_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            coord_valid_flag <= 0;
            coord_valid <= 0;
        end else if (frame_cnt == (FRAME_MAX - 1)) begin
            if (!coord_valid_flag) begin
                coord_valid_flag <= 1;
                coord_valid <= 1;
            end else begin
                coord_valid <= 0;
            end
        end else begin
            coord_valid_flag <= 0;
            coord_valid <= 0;
        end
    end
endmodule

module switch_sel_coord (
    input  logic       clk,
    input  logic       reset,
    input  logic       sw_sel,
    input  logic       valid,
    input  logic [9:0] x_min,
    input  logic [9:0] x_max,
    input  logic [9:0] y_min,
    input  logic [9:0] y_max,
    output logic       o_valid,
    output logic [9:0] x_min_fix,
    output logic [9:0] x_max_fix,
    output logic [9:0] y_min_fix,
    output logic [9:0] y_max_fix
);

    //sw == 0이면 계속 업데이트 1이면 캡쳐

    always_ff @(posedge clk or posedge reset) begin : blockName
        if (reset) begin
            x_min_fix <= 0;
            x_max_fix <= 0;
            y_min_fix <= 0;
            y_max_fix <= 0;
        end else if (sw_sel) begin
            x_min_fix <= x_min_fix;
            x_max_fix <= x_max_fix;
            y_min_fix <= y_min_fix;
            y_max_fix <= y_max_fix;

        end else begin
            x_min_fix <= x_min;
            x_max_fix <= x_max;
            y_min_fix <= y_min;
            y_max_fix <= y_max;
        end
    end

    logic val_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            o_valid <= 0;
        end else if (sw_sel && !val_flag) begin
            val_flag <= 1;
            o_valid  <= 1;
        end else if (!sw_sel) begin
            val_flag <= 0;
        end else begin
            o_valid <= 0;
        end
    end

endmodule

module detection_cnt_en (
    input logic clk,
    input logic reset,
    input logic tr_light_tick,
    input logic tr_light,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [9:0] x_min,
    input logic [9:0] x_max,
    input logic [9:0] y_min,
    input logic [9:0] y_max,
    output logic [9:0] x_min_traffic,
    output logic [9:0] x_max_traffic,
    output logic [9:0] y_min_traffic,
    output logic [9:0] y_max_traffic,
    output logic car_detection_en,
    output logic human_detection_en
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_min_traffic <= 0;
            x_max_traffic <= 0;
            y_min_traffic <= 0;
            y_max_traffic <= 0;
        end else if (tr_light_tick) begin
            x_min_traffic <= x_min;
            x_max_traffic <= x_max;
            y_min_traffic <= y_min;
            y_max_traffic <= y_max;
        end
    end

    //tr_light: 1 == green  // 0 == red
    assign car_detection_en = (tr_light) && (x_pixel >= x_min_traffic) && (x_pixel <= x_max_traffic) && (y_pixel >= y_min_traffic) && (y_pixel <= y_max_traffic);
    assign human_detection_en = (!tr_light) && (x_pixel >= x_min_traffic) && (x_pixel <= x_max_traffic) && (y_pixel >= y_min_traffic) && (y_pixel <= y_max_traffic);

endmodule
