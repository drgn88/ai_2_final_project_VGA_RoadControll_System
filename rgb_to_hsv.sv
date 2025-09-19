// `timescale 1ns / 1ps

// module rgb_to_hsv (
//     input  logic [4:0] r_data,
//     input  logic [5:0] g_data,
//     input  logic [4:0] b_data,
//     output logic [1:0] r_g_decision,    //0: 빨간색 1: 초록색 2: 아무것도 아님
//     output logic [7:0] s_data,
//     output logic [7:0] v_data
// );


//     // PURE GREEN 임계값 (R과 B는 낮고 G는 매우 높음)
//     localparam GREEN_R_MAX_THRESHOLD = 25;
//     localparam GREEN_G_MIN_THRESHOLD = 45;
//     localparam GREEN_B_MAX_THRESHOLD = 25;

//     // PURE RED 임계값 (G와 B는 낮고 R은 매우 높음)
//     localparam RED_R_MIN_THRESHOLD = 28;
//     localparam RED_G_MAX_THRESHOLD = 23;
//     localparam RED_B_MAX_THRESHOLD = 15;

//     //RGB565 -> RGB888
//     logic [7:0] r_8b;
//     logic [7:0] g_8b;
//     logic [7:0] b_8b;
//     logic [7:0] max_val;
//     logic [7:0] min_val;

//     assign r_8b = {r_data, r_data[4:2]};
//     assign g_8b = {g_data, g_data[5:4]};
//     assign b_8b = {b_data, b_data[4:2]};

//     always_comb begin
//         if ((g_data >= GREEN_G_MIN_THRESHOLD) && (r_data <= GREEN_R_MAX_THRESHOLD) && (b_data <= GREEN_B_MAX_THRESHOLD)) begin
//             r_g_decision = 1;
//         end
//         else if ((r_data >= RED_R_MIN_THRESHOLD) && (g_data <= RED_G_MAX_THRESHOLD) && (b_data <= RED_B_MAX_THRESHOLD)) begin
//             r_g_decision = 0;
//         end else begin
//             r_g_decision = 2;
//         end
//     end

//     find_max_val U_MAX_VAL (
//         .x1 (r_8b),
//         .x2 (g_8b),
//         .x3 (b_8b),
//         .max(max_val)
//     );

//     find_min_val U_MIN_VAL (
//         .x1 (r_8b),
//         .x2 (g_8b),
//         .x3 (b_8b),
//         .min(min_val)
//     );

//     assign v_data = max_val;

//     always_comb begin
//         if (!max_val) begin
//             s_data = 0;
//         end else begin
//             //s_data = (max_val - min_val) / max_val;
//             s_data = ((max_val - min_val) * 255) / max_val;
//         end
//     end


// endmodule

// module find_max_val (
//     input  logic [7:0] x1,
//     input  logic [7:0] x2,
//     input  logic [7:0] x3,
//     output logic [7:0] max
// );

//     logic [7:0] temp_max;

//     assign temp_max = (x1 > x2) ? x1 : x2;
//     assign max = (temp_max > x3) ? temp_max : x3;

// endmodule

// module find_min_val (
//     input  logic [7:0] x1,
//     input  logic [7:0] x2,
//     input  logic [7:0] x3,
//     output logic [7:0] min
// );

//     logic [7:0] temp_min;

//     assign temp_min = (x1 < x2) ? x1 : x2;
//     assign min = (temp_min < x3) ? temp_min : x3;

// endmodule

`timescale 1ns / 1ps

module rgb_to_hsv (
    input  logic [4:0] r_data,
    input  logic [5:0] g_data,
    input  logic [4:0] b_data,
    output logic [1:0] r_g_decision,    //0: 빨간색 1: 초록색 2: 아무것도 아님
    output logic [7:0] s_data,
    output logic [7:0] v_data
);


    // PURE GREEN 임계값 (R과 B는 낮고 G는 매우 높음)
    localparam GREEN_R_MAX_THRESHOLD = 120;
    localparam GREEN_G_MIN_THRESHOLD = 180;
    localparam GREEN_B_MAX_THRESHOLD = 120;

    // PURE RED 임계값 (G와 B는 낮고 R은 매우 높음)
    localparam RED_R_MIN_THRESHOLD = 190;
    localparam RED_G_MAX_THRESHOLD = 100;
    localparam RED_B_MAX_THRESHOLD = 100;

    //RGB565 -> RGB888
    logic [7:0] r_8b;
    logic [7:0] g_8b;
    logic [7:0] b_8b;
    logic [7:0] max_val;
    logic [7:0] min_val;

    assign r_8b = {r_data, r_data[4:2]};
    assign g_8b = {g_data, g_data[5:4]};
    assign b_8b = {b_data, b_data[4:2]};

    always_comb begin
        if ((g_8b >= GREEN_G_MIN_THRESHOLD) && (r_8b <= GREEN_R_MAX_THRESHOLD) && (b_8b <= GREEN_B_MAX_THRESHOLD)) begin
            r_g_decision = 1;
        end
        else if ((r_8b >= RED_R_MIN_THRESHOLD) && (g_8b <= RED_G_MAX_THRESHOLD) && (b_8b <= RED_B_MAX_THRESHOLD)) begin
            r_g_decision = 0;
        end else begin
            r_g_decision = 2;
        end
    end

    find_max_val U_MAX_VAL (
        .x1 (r_8b),
        .x2 (g_8b),
        .x3 (b_8b),
        .max(max_val)
    );

    find_min_val U_MIN_VAL (
        .x1 (r_8b),
        .x2 (g_8b),
        .x3 (b_8b),
        .min(min_val)
    );

    assign v_data = max_val;

    always_comb begin
        if (!max_val) begin
            s_data = 0;
        end else begin
            //s_data = (max_val - min_val) / max_val;
            s_data = ((max_val - min_val) * 255) / max_val;
        end
    end


endmodule

module find_max_val (
    input  logic [7:0] x1,
    input  logic [7:0] x2,
    input  logic [7:0] x3,
    output logic [7:0] max
);

    logic [7:0] temp_max;

    assign temp_max = (x1 > x2) ? x1 : x2;
    assign max = (temp_max > x3) ? temp_max : x3;

endmodule

module find_min_val (
    input  logic [7:0] x1,
    input  logic [7:0] x2,
    input  logic [7:0] x3,
    output logic [7:0] min
);

    logic [7:0] temp_min;

    assign temp_min = (x1 < x2) ? x1 : x2;
    assign min = (temp_min < x3) ? temp_min : x3;

endmodule
