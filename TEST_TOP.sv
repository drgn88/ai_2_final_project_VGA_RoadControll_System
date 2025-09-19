`timescale 1ns / 1ps

module TEST_TOP (
    input  logic       clk,
    input  logic       reset,
    // ov7670 side
    input  logic       sccb_start,
    output logic       scl,
    output logic       sda,
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,
    // external port
    output logic       h_sync,
    output logic       v_sync,

    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    output logic tx,
    input logic rx,
    input logic sw_sel,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont,
    output logic led_traffic,
    output logic led_test_car_warn,
    output logic led_test_human_warn
);

    logic        vga_pclk;
    logic [ 9:0] vga_x_pixel;
    logic [ 9:0] vga_y_pixel;
    logic        vga_DE;

    logic        ov7670_we;
    logic [16:0] ov7670_wAddr;
    logic [15:0] ov7670_wData;

    logic [ 1:0] r_g_decision;
    logic [ 7:0] s_data;
    logic [ 7:0] v_data;
    logic [ 2:0] label_data;

    logic        vga_den;
    logic [16:0] vga_rAddr;
    logic [ 2:0] vga_rData;

    logic        camera_dp_en;
    logic        v_finish_camera;
    logic [ 9:0] x_pixel_camera;
    logic [ 9:0] y_pixel_camera;

    logic tr_light_tick, tr_light;
    logic tick_sec;

    logic car_detection_en, human_detection_en;
    logic [14:0] test_flow_count;

    fndController U_fndController (
        .clk(clk),
        .rst(reset),
        .number(test_flow_count[13:0]),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
    assign led_traffic = tr_light;

    ///////////////////////// motion detection/////////////////////////////////
    logic val_warn_car, val_warn_human, valid_flow;





    ///////////////////////Pedestrian Crosswalk Coordinate//////////////////////////
    logic [9:0] x_min_final;
    logic [9:0] x_max_final;
    logic [9:0] y_min_final;
    logic [9:0] y_max_final;

    logic [9:0] x_min_traffic;
    logic [9:0] x_max_traffic;
    logic [9:0] y_min_traffic;
    logic [9:0] y_max_traffic;
    logic       coord_valid;




    ////////////////////////////UART_signal////////////////////////////////////
    logic [9:0] x_min_uart;
    logic [9:0] x_max_uart;
    logic [9:0] y_min_uart;
    logic [9:0] y_max_uart;

    logic [4:0] red_left_time, green_left_time;
    logic [4:0] red_left_time_uart, green_left_time_uart;


    logic       human_violation;
    logic       car_violation;
    logic       traffic_amount;

    logic       uart_start;
    logic       traffic_light_uart;
    logic       human_violation_uart;
    logic       car_violation_uart;
    logic       traffic_amount_uart;

    logic       uart_data_update;
    logic       fix_coord_valid;

    // assign led_traffic = traffic_light_uart;

    // assign uart_data_update =  fix_coord_valid | tr_light_tick | val_warn_car | val_warn_human | valid_flow;
    //////////////////////////////////////////////////////////////////////////////




    logic btn_startSig;

    assign ov7670_xclk = vga_pclk;

    // ila_0 U_ila_0 (
    //     .clk(clk),
    //     .probe0(ov7670_pclk),
    //     .probe1(uart_data_update),
    //     .probe2(tr_light_tick),
    //     .probe3(tr_light)
    // );








    button_detector U_button_detector (
        .clk(clk),
        .rst(reset),
        .in_button(sccb_start),
        .rising_edge(btn_startSig),
        .falling_edge(),
        .both_edge()
    );

    SCCB_intf U_SCCB (
        .clk(clk),
        .reset(reset),
        .startSig(btn_startSig),
        .SCL(scl),
        .SDA(sda)
    );

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

    // OV7670_MemController U_OV7670_MemController (
    //     .clk        (ov7670_pclk),
    //     .reset      (reset),
    //     .href       (ov7670_href),
    //     .vsync      (ov7670_vsync),
    //     .ov7670_data(ov7670_data),
    //     .we         (ov7670_we),
    //     .wAddr      (ov7670_wAddr),
    //     .wData      (ov7670_wData)
    // );

    OV7670_MemController U_OV7670_MemController (
        .clk            (ov7670_pclk),
        .reset          (reset),
        .href           (ov7670_href),
        .vsync          (ov7670_vsync),
        .ov7670_data    (ov7670_data),
        .we             (ov7670_we),
        .wAddr          (ov7670_wAddr),
        .wData          (ov7670_wData),
        .camera_dp_en   (camera_dp_en),
        .v_finish_camera(v_finish_camera),
        .x_pixel_camera (x_pixel_camera),
        .y_pixel_camera (y_pixel_camera)
    );


    ////////////////////////////////////////////////////////////////////////
    //                      Traffic light Control FSM
    ////////////////////////////////////////////////////////////////////////
    // Signal_CU U_Traffic_Sig_CU (
    //     .clk(clk),
    //     .reset(reset),
    //     .traffic_sel(1'b0),
    //     .o_tr_light(tr_light),
    //     .o_tr_state(),
    //     .tr_valid(),  //유동량
    //     .light_valid(tr_light_tick)  //신호등
    // );

    Signal_CU U_Traffic_Sig_CU (
        .clk(clk),
        .reset(reset),
        .traffic_sel(1'b0),
        .o_tr_light(tr_light),
        .o_tr_state(),
        .tr_valid(),  //유동량
        .light_valid(tr_light_tick),  //신호등
        .red_left_time(red_left_time),
        .green_left_time(green_left_time),
        .tick_sec(tick_sec)
    );


    ////////////////////////////////////////////////////////////////////////
    //                      Motion Detection
    ////////////////////////////////////////////////////////////////////////
    motion_detect U_Motion_Detect (
        .clk(clk),
        .pclk(ov7670_pclk),
        .reset(reset),
        .traffic_light(tr_light),
        .frame_done(v_finish_camera),
        .car_detection_en(car_detection_en),
        .human_detection_en(human_detection_en),
        .label_data(label_data),
        .valid_flow(valid_flow),
        .flow_decision(traffic_amount),
        .val_warn_car_tick(val_warn_car),
        .warn_car(car_violation),
        .val_warn_human_tick(val_warn_human),
        .warn_human(human_violation),
        .test_flow_count(test_flow_count)
    );


    // ila_0 U_ila_0 (
    //     .clk(clk),
    //     .probe0(ov7670_pclk),
    //     .probe1(valid_flow),
    //     .probe2(traffic_amount),
    //     .probe3(car_violation)
    // );


    ////////////////////////////////////////////////////////////////////////
    //               Pedestrian CrossWalk Decision Module
    ////////////////////////////////////////////////////////////////////////
    Decision_CrossWalk U_Decision_CrossWalk (
        .clk(clk),
        .pclk(ov7670_pclk),
        .reset(reset),
        .imgShow(camera_dp_en),
        .v_finish(v_finish_camera),
        .label_data(label_data),
        .x_pixel(x_pixel_camera),
        .y_pixel(y_pixel_camera),
        .x_min_fix(x_min_final),
        .x_max_fix(x_max_final),
        .y_min_fix(y_min_final),
        .y_max_fix(y_max_final),
        //.coord_valid(coord_valid),
        //For Detect Moving module
        .tr_light_tick(tr_light_tick),  //값 받아야 좌표가 나옴
        .tr_light(tr_light),
        .x_min_traffic(x_min_traffic),
        .x_max_traffic(x_max_traffic),
        .y_min_traffic(y_min_traffic),
        .y_max_traffic(y_max_traffic),
        .car_detection_en(car_detection_en),
        .human_detection_en(human_detection_en),
        .sw_sel(sw_sel),
        .fix_coord_valid(fix_coord_valid)
    );


    rgb_to_hsv U_rgb_to_hsv (
        .r_data(ov7670_wData[15:11]),
        .g_data(ov7670_wData[10:5]),
        .b_data(ov7670_wData[4:0]),
        .s_data(s_data),
        .v_data(v_data),
        .r_g_decision(r_g_decision)
    );


    Label_Gen U_Label_Gen (
        .r_g_decision(r_g_decision),
        .s_data      (s_data),
        .v_data      (v_data),
        .label_data  (label_data)
    );


    Label_RAM U_Label_RAM (
        .wclk      (ov7670_pclk),
        .we        (ov7670_we),
        .w_addr    (ov7670_wAddr),
        .write_data(label_data),
        .rclk      (vga_pclk),
        .oe        (vga_den),
        .r_addr    (vga_rAddr),
        .read_data (vga_rData)
    );


    VGA_MemController U_VGA_MemController (
        .x_min  (x_min_final),
        .y_min  (y_min_final),
        .x_max  (x_max_final),
        .y_max  (y_max_final),
        .DE     (vga_DE),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .den    (vga_den),
        .rAddr  (vga_rAddr),
        .rData  (vga_rData),
        .r_port (r_port),
        .g_port (g_port),
        .b_port (b_port)
    );




    /////////////////////////////////////////////////////////////////////////////
    //                              uart module area
    /////////////////////////////////////////////////////////////////////////////


    // uart_reg U_REG (
    //     .clk(clk),
    //     .reset(reset),
    //     .valid(uart_data_update),  //need to or-ing all valid signals of each data
    //     .x_min(x_min_traffic),
    //     .x_max(x_max_traffic),
    //     .y_min(y_min_traffic),
    //     .y_max(y_max_traffic),
    //     .traffic_light(tr_light),
    //     .human_violation(human_violation),
    //     .car_violation(car_violation),
    //     .traffic_amount(traffic_amount),
    //     .uart_start(uart_start),
    //     .x_min_o(x_min_uart),
    //     .x_max_o(x_max_uart),
    //     .y_min_o(y_min_uart),
    //     .y_max_o(y_max_uart),
    //     .traffic_light_o(traffic_light_uart),
    //     .human_violation_o(human_violation_uart),
    //     .car_violation_o(car_violation_uart),
    //     .traffic_amount_o(traffic_amount_uart)
    // );

    uart_reg U_REG (
        .clk(clk),
        .reset(reset),
        .fix_coord_valid(fix_coord_valid),
        .tr_light_valid(tr_light_tick),
        .val_warn_car(val_warn_car),
        .val_warn_human(val_warn_human),
        .tick_sec(tick_sec),
        .x_min(x_min_final),
        .x_max(x_max_final),
        .y_min(y_min_final),
        .y_max(y_max_final),
        .red_left_time(red_left_time),
        .green_left_time(green_left_time),
        .traffic_light(tr_light),
        .traffic_amount(traffic_amount),
        .uart_start(uart_start),
        .x_min_o(x_min_uart),
        .x_max_o(x_max_uart),
        .y_min_o(y_min_uart),
        .y_max_o(y_max_uart),
        .red_left_time_o(red_left_time_uart),
        .green_left_time_o(green_left_time_uart),
        .traffic_light_o(traffic_light_uart),
        .human_violation_o(human_violation_uart),
        .car_violation_o(car_violation_uart),
        .traffic_amount_o(traffic_amount_uart)
    );


    // sender_uart U_ART_SENDER (
    //     .clk(clk),
    //     .reset(reset),
    //     .start(uart_start),  // 송신 시작 신호
    //     .x_min(x_min_uart),
    //     .x_max(x_max_uart),
    //     .y_min(y_min_uart),
    //     .y_max(y_max_uart),
    //     .traffic_light(traffic_light_uart),  // 0=green,1=red    -> traffic_light_uart
    //     .human_violation(human_violation_uart),  // 0:없음,1:발생    -> human_violation_uart
    //     .car_violation(car_violation_uart),  // 0:없음,1:발생    -> car_violation_uart
    //     .traffic_amount(traffic_amount_uart),  // 0:적음,1:많음    -> traffic_amount_uart
    //     .tx(tx),
    //     .rx_done(),
    //     .rx(rx),
    //     .rx_pop_data()
    // );

    sender_uart U_ART_SENDER (
        .clk(clk),
        .reset(reset),
        .start(uart_start),  // 송신 시작 신호
        .x_min(x_min_uart),
        .x_max(x_max_uart),
        .y_min(y_min_uart),
        .y_max(y_max_uart),
        .red_left_time(red_left_time_uart),
        .green_left_time(green_left_time_uart),
        .traffic_light(traffic_light_uart),  // 0=green,1=red    -> traffic_light_uart
        .human_violation(human_violation_uart),  // 0:없음,1:발생    -> human_violation_uart
        .car_violation(car_violation_uart),  // 0:없음,1:발생    -> car_violation_uart
        .traffic_amount(traffic_amount_uart),  // 0:적음,1:많음    -> traffic_amount_uart
        .tx(tx),
        .rx_done(),
        .rx(rx),
        .rx_pop_data()
    );





    // always_ff @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         led_test_car_warn <= 0;
    //     end else if (val_warn_car) begin
    //         led_test_car_warn <= ~led_test_car_warn;
    //     end
    // end

    // always_ff @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         led_test_human_warn <= 0;
    //     end else if (val_warn_human) begin
    //         led_test_human_warn <= ~led_test_human_warn;
    //     end
    // end


    assign led_test_car_warn = car_violation_uart;
    assign led_test_human_warn = human_violation_uart;




endmodule
