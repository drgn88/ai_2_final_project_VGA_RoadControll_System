`timescale 1ns / 1ps

module VGA_Camera_Display (
    input  logic       clk,
    input  logic       reset,
    input  logic       sw_gray,
    input   logic       start,//uart wire
    // ov7670 side
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,

    // external port
    output logic h_sync,
    output logic v_sync,

    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    output logic tx,
    input logic rx
);

    logic        ov7670_we;
    logic [16:0] ov7670_wAddr;
    logic [15:0] ov7670_wData;

    logic        vga_pclk;
    logic [ 9:0] vga_x_pixel;
    logic [ 9:0] vga_y_pixel;
    logic        vga_DE;

    logic        vga_den;
    logic [16:0] vga_rAddr;
    logic [15:0] vga_rData;

    logic [3:0] vga_r, gray_r;
    logic [3:0] vga_g, gray_g;
    logic [3:0] vga_b, gray_b;

    /////////////uart_wire//////////////////////////////////
    logic start_edge, start_edge_dly;
    logic [15:0] x_min;
    logic [15:0] x_max;
    logic [15:0] y_min;
    logic [15:0] y_max;
    logic        traffic_light;        // 0=green,1=red
    logic [1:0]  human_violation;     // 0:없음,1:주의,2:발생
    logic        car_violation;       // 0:없음,1:발생
    logic [1:0]  traffic_amount;      // 0:적음,1:보통,2:많음


    assign ov7670_xclk = vga_pclk;

    VGA_Decoder U_VGA_Decoder (
        .clk    (clk),
        .reset  (reset),
        .pclk   (vga_pclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .DE     (vga_DE)
    );

    OV7670_MemController U_OV7670_MemController (
        .clk        (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .vsync      (ov7670_vsync),
        .ov7670_data(ov7670_data),
        .we         (ov7670_we),
        .wAddr      (ov7670_wAddr),
        .wData      (ov7670_wData)
    );

    frame_buffer U_FrameBuffer (
        .wclk (ov7670_pclk),
        .we   (ov7670_we),
        .wAddr(ov7670_wAddr),
        .wData(ov7670_wData),
        .rclk (vga_pclk),
        .oe   (vga_den),
        .rAddr(vga_rAddr),
        .rData(vga_rData)
    );

    VGA_MemController U_VGAMemController (
        .DE     (vga_DE),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .den    (vga_den),
        .rAddr  (vga_rAddr),
        .rData  (vga_rData),
        .r_port (vga_r),
        .g_port (vga_g),
        .b_port (vga_b)
    );

    GrayScaleFilter U_GRAY (
        .i_r(vga_r),
        .i_g(vga_g),
        .i_b(vga_b),
        .o_r(gray_r),
        .o_g(gray_g),
        .o_b(gray_b)
    );

    mux_2x1 U_MUX (
        .sel     (sw_gray),
        .vga_rgb ({vga_r, vga_g, vga_b}),
        .gray_rgb({gray_r, gray_g, gray_b}),
        .rgb     ({r_port, g_port, b_port})
    );





////////////////////Logic for test uart////////////////////////


button_detector btn_detec(
    .clk(clk),
    .reset(reset),
    .in_button(start),
    .rising_edge(start_edge),
    .falling_edge(),
    .both_edge()
);



sender_uart U_SEND_UART(
    .clk(clk),
    .reset(reset),
    .start(start_edge),                 // 송신 시작 신호
    .x_min(10'd1),
    .x_max(10'd240),
    .y_min(10'd111),
    .y_max(10'd200),
    .traffic_light(1'b1),        // 0=green,1=red
    .human_violation(2'd1),     // 0:없음,1:주의,2:발생
    .car_violation(1'b0),       // 0:없음,1:발생
    .traffic_amount(2'd2),      // 0:적음,1:보통,2:많음
    .tx(tx),
    .rx_done(),
    .rx(rx),
    .rx_pop_data()
);




// logic [45:0] tx_data_reg;
// logic [2:0]  tx_data_sel;

// always_ff @(posedge clk or posedge reset) begin
//     if (reset) begin
//         tx_data_sel <= 0;
//     end else if (start_edge) begin
//         tx_data_sel <= tx_data_sel + 1;
//         case(tx_data_sel)
//             0: tx_data_reg <= 46'h066666666666;  // 첫 번째 버튼 값
//             1: tx_data_reg <= 46'h033333333333;  // 두 번째 버튼 값
//             2: tx_data_reg <= 46'h055555555555;  // 세 번째 버튼 값
//             3: tx_data_reg <= 46'h0AAAAAAAAAAA;  // 네 번째 버튼 값
//             4: tx_data_reg <= 46'h022222222222;  // 다섯 번째 버튼 값
//             5: tx_data_reg <= 46'h0BBBBBBBBBBB;  // 여섯 번째 버튼 값
//             6: tx_data_reg <= 46'h011111111111;  // 일곱 번째 버튼 값
//             7: tx_data_reg <= 46'h0CCCCCCCCCCC;  // 여덟 번째 버튼 값
//             default: tx_data_reg <= 46'h0000;
//         endcase
//     end
// end

// always_ff @( posedge clk ) begin : blockName
//     if (reset) begin
//         start_edge_dly <= 1'b0;
//     end else begin
//         start_edge_dly <= start_edge;
//     end
// end





endmodule




module mux_2x1 (
    input  logic        sel,
    input  logic [11:0] vga_rgb,
    input  logic [11:0] gray_rgb,
    output logic [11:0] rgb
);
    always_comb begin
        case (sel)
            1'b0: rgb = vga_rgb;
            1'b1: rgb = gray_rgb;
        endcase
    end
endmodule




module button_detector (
    input  logic clk,
    input  logic reset,
    input  logic in_button,
    output logic rising_edge,
    output logic falling_edge,
    output logic both_edge
);
    logic clk_1khz;
    logic debounce;
    logic [7:0] sh_reg;
    logic [$clog2(100_000)-1 : 0] div_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            clk_1khz <= 1'b0;
        end else begin
            if (div_counter == 100_000 - 1) begin
                div_counter <= 0;
                clk_1khz <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                clk_1khz <= 1'b0;
            end
        end
    end

    shift_register U_Shift_Register (
        .clk     (clk_1khz),
        .reset   (reset),
        .in_data (in_button),
        .out_data(sh_reg)
    );

    assign debounce = &sh_reg;
    //assign out_button = debounce;

    logic [1:0] edge_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 0;
        end else begin
            edge_reg[0] <= debounce;
            edge_reg[1] <= edge_reg[0];
        end
    end

    assign rising_edge = edge_reg[0] & ~edge_reg[1];
    assign falling_edge = ~edge_reg[0] & edge_reg[1];
    assign both_edge = rising_edge | falling_edge;
endmodule



module shift_register (
    input  logic       clk,
    input  logic       reset,
    input  logic       in_data,
    output logic [7:0] out_data
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            out_data <= 0;
        end else begin
            out_data <= {in_data, out_data[7:1]};  // right shift
            //out_data <= {out_data[6:0], in_data}; // left shift
        end
    end
endmodule
