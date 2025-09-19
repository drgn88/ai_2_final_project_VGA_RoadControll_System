// `timescale 1ns / 1ps


// module uart_reg (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       valid,
//     input  logic [9:0] x_min,
//     input  logic [9:0] x_max,
//     input  logic [9:0] y_min,
//     input  logic [9:0] y_max,
//     input  logic       traffic_light,
//     input  logic       human_violation,
//     input  logic       car_violation,
//     input  logic       traffic_amount,
//     output logic       uart_start,
//     output logic [9:0] x_min_o,
//     output logic [9:0] x_max_o,
//     output logic [9:0] y_min_o,
//     output logic [9:0] y_max_o,
//     output logic       traffic_light_o,
//     output logic       human_violation_o,
//     output logic       car_violation_o,
//     output logic       traffic_amount_o
// );

//     logic valid_dly1, valid_dly2, valid_dly3, valid_dly4;



//     // posedge_detect U_POS_DETEC(
//     //     .clk(clk),
//     //     .reset(reset),
//     //     .in_siganl(valid_dly4),
//     //     .edge_detec(uart_start)
//     // );

//     assign uart_start = valid_dly4;



//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             x_min_o           <= 0;
//             x_max_o           <= 0;
//             y_min_o           <= 0;
//             y_max_o           <= 0;
//             traffic_light_o   <= 0;
//             human_violation_o <= 0;
//             car_violation_o   <= 0;
//             traffic_amount_o  <= 0;
//         end else begin
//             if (valid) begin
//                 x_min_o           <= x_min;
//                 x_max_o           <= x_max;
//                 y_min_o           <= y_min;
//                 y_max_o           <= y_max;
//                 traffic_light_o   <= traffic_light;
//                 human_violation_o <= human_violation;
//                 car_violation_o   <= car_violation;
//                 traffic_amount_o  <= traffic_amount;
//             end
//         end
//     end



//     always_ff @(posedge clk, posedge reset) begin : blockName
//         if (reset) begin
//             valid_dly1 <= 0;
//             valid_dly2 <= 0;
//             valid_dly3 <= 0;
//             valid_dly4 <= 0;
//         end else begin
//             valid_dly1 <= valid;
//             valid_dly2 <= valid_dly1;
//             valid_dly3 <= valid_dly1;
//             valid_dly4 <= valid_dly1;
//         end

//     end


// endmodule



// module posedge_detect (
//     input  logic clk,
//     input  logic reset,
//     input  logic in_siganl,
//     output logic edge_detec
// );

//     logic pre_signal;

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             pre_signal <= 0;
//             edge_detec <= 0;
//         end else begin
//             pre_signal <= in_siganl;
//             if ((pre_signal != in_siganl) && (in_siganl)) begin
//                 edge_detec <= 1'b1;
//             end else begin
//                 edge_detec <= 1'b0;
//             end
//         end
//     end

// endmodule


`timescale 1ns / 1ps


module uart_reg (
    input  logic       clk,
    input  logic       reset,
    input  logic       fix_coord_valid,
    input  logic       tr_light_valid,
    input  logic       val_warn_car,
    input  logic       val_warn_human,
    input  logic       tick_sec,
    input  logic [9:0] x_min,
    input  logic [9:0] x_max,
    input  logic [9:0] y_min,
    input  logic [9:0] y_max,
    input  logic [4:0] red_left_time,
    input  logic [4:0] green_left_time,
    input  logic       traffic_light,
    input  logic       traffic_amount,
    output logic       uart_start,
    output logic [9:0] x_min_o,
    output logic [9:0] x_max_o,
    output logic [9:0] y_min_o,
    output logic [9:0] y_max_o,
    output logic [4:0] red_left_time_o,
    output logic [4:0] green_left_time_o,
    output logic       traffic_light_o,
    output logic       human_violation_o,
    output logic       car_violation_o,
    output logic       traffic_amount_o
);

    logic
        valid,
        valid_dly1,
        valid_dly2,
        valid_dly3,
        valid_dly4,
        flag_term,
        warn_human_data,
        warn_car_data;

    assign valid = fix_coord_valid | tr_light_valid | val_warn_car | val_warn_human | tick_sec;

    assign uart_start = valid_dly4;

    assign human_violation_o = warn_human_data;
    assign car_violation_o = warn_car_data;



    clk_wait_30 U_30_WAIT_HU (
        .clk(clk),
        .reset(reset),
        .in_siganl(val_warn_human),
        .term_valid(warn_human_data)
    );




    clk_wait_30 U_30_WAIT_CA (
        .clk(clk),
        .reset(reset),
        .in_siganl(val_warn_car),
        .term_valid(warn_car_data)
    );





    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            x_min_o           <= 0;
            x_max_o           <= 0;
            y_min_o           <= 0;
            y_max_o           <= 0;
        end else begin
            if (fix_coord_valid) begin
                x_min_o <= x_min;
                x_max_o <= x_max;
                y_min_o <= y_min;
                y_max_o <= y_max;
            end
        end
    end




    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            traffic_light_o  <= 0;
            traffic_amount_o <= 0;
        end else begin
            if (tr_light_valid) begin
                traffic_light_o  <= traffic_light;
                traffic_amount_o <= traffic_amount;
            end
        end
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            red_left_time_o   <= 0;
            green_left_time_o <= 0;
        end else begin
            if (tick_sec) begin
                red_left_time_o   <= red_left_time;
                green_left_time_o <= green_left_time;
            end
        end
    end





    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            valid_dly1 <= 0;
            valid_dly2 <= 0;
            valid_dly3 <= 0;
            valid_dly4 <= 0;
        end else begin
            valid_dly1 <= valid;
            valid_dly2 <= valid_dly1;
            valid_dly3 <= valid_dly2;
            valid_dly4 <= valid_dly3;
        end

    end






endmodule





module clk_wait_30 (
    input  logic clk,
    input  logic reset,
    input  logic in_siganl,
    output logic term_valid
);


    typedef enum {
        IDLE,
        WAIT,
        FREE
    } state_e;
    logic [4:0] clk_cnt, clk_cnt_n;
    state_e state, state_n;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            clk_cnt <= 0;
        end else begin
            state <= state_n;
            clk_cnt <= clk_cnt_n;
        end
    end


    always_comb begin
        clk_cnt_n = clk_cnt;
        state_n   = state;
        term_valid = 0;
        case (state)
            IDLE: begin
                term_valid = 0;
                clk_cnt_n = 0;
                if (in_siganl) state_n = WAIT;
            end

            WAIT: begin
                term_valid = 1;
                if (clk_cnt == 29) begin
                    state_n = IDLE;
                end
                clk_cnt_n = clk_cnt + 1;
            end
        endcase
    end

endmodule
