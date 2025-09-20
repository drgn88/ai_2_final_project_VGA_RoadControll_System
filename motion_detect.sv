// `timescale 1ns / 1ps

// module motion_detect (
//     input  logic        clk,
//     input  logic        pclk,
//     input  logic        reset,
//     input  logic        traffic_light,
//     input  logic        frame_done,
//     input  logic        car_detection_en,
//     input  logic        human_detection_en,
//     input  logic [ 2:0] label_data,
//     output logic        valid_flow,
//     output logic        flow_decision,
//     output logic        val_warn_car,
//     output logic        warn_car,
//     output logic        val_warn_human,
//     output logic        warn_human,
//     //TEST VALUE
//     output logic [14:0] test_flow_count
// );
//     localparam CAR = 3;
//     localparam HUMAN = 4;
//     localparam FRAME_COUNT = 60;
//     localparam FLOW_COUNT_MAX_P_FRAME = 80;
//     localparam FLOW_COUNT_MAX = 4;
//     localparam CAR_COUNT_MAX = 80;
//     localparam HUMAN_COUNT_MAX = 80;

//     logic [14:0] frame_cnt;
//     logic [14:0] flow_label_tmp;
//     logic flow_arrive_threshold;
//     logic [14:0] flow_label_cnt;
//     logic [14:0] car_label_cnt;
//     logic [14:0] human_label_cnt;

//     //FND Test
//     assign test_flow_count = flow_label_cnt;

//     /*************************Update Frame Rate*************************/
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             frame_cnt <= 0;
//         end else if (frame_done) begin
//             if (frame_cnt == (FRAME_COUNT - 1)) begin
//                 frame_cnt <= 0;
//             end else begin
//                 frame_cnt <= frame_cnt + 1;
//             end
//         end
//     end

//     // ila_0 U_ila_0 (
//     //     .clk(clk),
//     //     .probe0(pclk),
//     //     .probe1(frame_done),
//     //     .probe2(frame_cnt),
//     //     .probe3(flow_arrive_threshold),
//     //     .probe4(flow_label_cnt)
//     // );

//     /*************************유동량 파악*************************/
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             flow_label_tmp <= 0;
//             flow_arrive_threshold <= 0;
//         end else if (frame_cnt == (FRAME_COUNT - 1)) begin
//             flow_label_tmp <= 0;
//             flow_arrive_threshold <= 0;
//         end else if (car_detection_en && (label_data == CAR)) begin
//             if (flow_label_tmp >= (FLOW_COUNT_MAX_P_FRAME - 1)) begin
//                 //flow_label_tmp <= (FLOW_COUNT_MAX_P_FRAME - 1);
//                 flow_arrive_threshold <= 1;
//             end else begin
//                 flow_label_tmp <= flow_label_tmp + 1;
//                 flow_arrive_threshold <= 0;
//             end
//         end
//     end

//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             flow_label_cnt <= 0;
//         end else if ((frame_cnt == (FRAME_COUNT - 1)) && (flow_arrive_threshold == 1)) begin
//             if (flow_label_cnt >= (FLOW_COUNT_MAX - 1)) begin
//                 flow_label_cnt <= (FLOW_COUNT_MAX - 1);
//             end else begin
//                 flow_label_cnt <= flow_label_cnt + flow_arrive_threshold;
//             end
//         end else if (!traffic_light) begin
//             flow_label_cnt <= 0;
//         end
//     end

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             flow_decision <= 0;
//         end else if (flow_label_cnt == (FLOW_COUNT_MAX - 1)) begin
//             flow_decision <= 1;
//         end else begin
//             flow_decision <= 0;
//         end
//     end

//     logic flow_val_flag;

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             flow_val_flag <= 0;
//         end else if (!flow_val_flag && (!traffic_light)) begin
//             flow_val_flag <= 1;
//         end else if (traffic_light) begin
//             flow_val_flag <= 0;
//         end
//     end

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             valid_flow <= 0;
//         end else if (!flow_val_flag && (!traffic_light)) begin
//             valid_flow <= 1;
//         end else begin
//             valid_flow <= 0;
//         end
//     end

//     /*************************차 무단횡단*************************/
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             car_label_cnt <= 0;
//         end else if (human_detection_en && (label_data == CAR)) begin
//             if (car_label_cnt < (CAR_COUNT_MAX - 1)) begin
//                 car_label_cnt <= car_label_cnt + 1;
//             end
//         end else if (frame_done) begin
//             car_label_cnt <= 0;
//         end
//     end
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             warn_car <= 0;
//         end else if (human_detection_en) begin
//             if (car_label_cnt == (CAR_COUNT_MAX - 1)) begin
//                 warn_car <= 1;
//             end else begin
//                 warn_car <= 0;
//             end
//         end else if (traffic_light) begin
//             warn_car <= 0;
//         end
//     end

//     logic val_warn_car_flag;

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             val_warn_car_flag <= 0;
//             val_warn_car <= 0;
//         end else if (!val_warn_car_flag && traffic_light) begin
//             val_warn_car_flag <= 1;
//             val_warn_car <= 1;
//         end else if (!traffic_light) begin
//             val_warn_car_flag <= 0;
//         end else begin
//             val_warn_car <= 0;
//         end
//     end

//     /*************************사람 무단횡단*************************/
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             human_label_cnt <= 0;
//         end else if (car_detection_en && (label_data == HUMAN)) begin
//             if (human_label_cnt < (HUMAN_COUNT_MAX - 1)) begin
//                 human_label_cnt <= human_label_cnt + 1;
//             end
//         end else if (frame_done) begin
//             human_label_cnt <= 0;
//         end
//     end
//     always_ff @(posedge pclk or posedge reset) begin
//         if (reset) begin
//             warn_human <= 0;
//         end else if (car_detection_en) begin
//             if (human_label_cnt == (HUMAN_COUNT_MAX - 1)) begin
//                 warn_human <= 1;
//             end else begin
//                 warn_human <= 0;
//             end
//         end else if (!traffic_light) begin
//             warn_human <= 0;
//         end
//     end

//     logic val_warn_human_flag;

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             val_warn_human_flag <= 0;
//             val_warn_human <= 0;
//         end else if (!val_warn_human_flag && (!traffic_light)) begin
//             val_warn_human_flag <= 1;
//             val_warn_human <= 1;
//         end else if (traffic_light) begin
//             val_warn_human_flag <= 0;
//         end else begin
//             val_warn_human <= 0;
//         end
//     end
// endmodule


`timescale 1ns / 1ps

module motion_detect (
    input  logic        clk,
    input  logic        pclk,
    input  logic        reset,
    input  logic        traffic_light,
    input  logic        frame_done,
    input  logic        car_detection_en,
    input  logic        human_detection_en,
    input  logic [ 2:0] label_data,
    output logic        valid_flow,
    output logic        flow_decision,
    output logic        val_warn_car_tick,
    output logic        warn_car,
    output logic        val_warn_human_tick,
    output logic        warn_human,
    //TEST VALUE
    output logic [14:0] test_flow_count
);
    localparam CAR = 3;
    localparam HUMAN = 4;
    localparam FRAME_COUNT = 60;
    localparam FLOW_COUNT_MAX_P_FRAME = 80;
    localparam FLOW_COUNT_MAX = 5;
    localparam CAR_COUNT_MAX = 80;
    localparam HUMAN_COUNT_MAX = 30;

    logic [14:0] frame_cnt;
    logic [14:0] flow_label_tmp;
    logic flow_arrive_threshold;
    logic [14:0] flow_label_cnt;
    logic [14:0] car_label_cnt;
    logic [14:0] human_label_cnt;
    logic val_warn_car;
    logic val_warn_human;

    //FND Test
    assign test_flow_count = flow_label_cnt;

    /*************************Update Frame Rate*************************/
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            frame_cnt <= 0;
        end else if (frame_done) begin
            if (frame_cnt == (FRAME_COUNT - 1)) begin
                frame_cnt <= 0;
            end else begin
                frame_cnt <= frame_cnt + 1;
            end
        end
    end

    // ila_0 U_ila_0 (
    //     .clk(clk),
    //     .probe0(pclk),
    //     .probe1(frame_done),
    //     .probe2(frame_cnt),
    //     .probe3(flow_arrive_threshold),
    //     .probe4(flow_label_cnt)
    // );

    /*************************유동량 파악*************************/
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            flow_label_tmp <= 0;
            flow_arrive_threshold <= 0;
        end else if (frame_cnt == (FRAME_COUNT - 1)) begin
            flow_label_tmp <= 0;
            flow_arrive_threshold <= 0;
        end else if (car_detection_en && (label_data == CAR)) begin
            if (flow_label_tmp >= (FLOW_COUNT_MAX_P_FRAME - 1)) begin
                //flow_label_tmp <= (FLOW_COUNT_MAX_P_FRAME - 1);
                flow_arrive_threshold <= 1;
            end else begin
                flow_label_tmp <= flow_label_tmp + 1;
                flow_arrive_threshold <= 0;
            end
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            flow_label_cnt <= 0;
        end else if ((frame_cnt == (FRAME_COUNT - 1)) && (flow_arrive_threshold == 1)) begin
            if (flow_label_cnt >= (FLOW_COUNT_MAX - 1)) begin
                flow_label_cnt <= (FLOW_COUNT_MAX - 1);
            end else begin
                flow_label_cnt <= flow_label_cnt + flow_arrive_threshold;
            end
        end else if (!traffic_light) begin
            flow_label_cnt <= 0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flow_decision <= 0;
        end else if (flow_label_cnt == (FLOW_COUNT_MAX - 1)) begin
            flow_decision <= 1;
        end else begin
            flow_decision <= 0;
        end
    end

    logic flow_val_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flow_val_flag <= 0;
        end else if (traffic_light) begin
            flow_val_flag <= 0;
        end else if (!flow_val_flag && (!traffic_light)) begin
            flow_val_flag <= 1;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_flow <= 0;
        end else begin
            valid_flow <= 0;
            if (!flow_val_flag && (!traffic_light)) begin
                valid_flow <= 1;
            end
        end
    end

    /*************************차 무단횡단*************************/
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            car_label_cnt <= 0;
        end else if (frame_done) begin
            car_label_cnt <= 0;
        end else if (human_detection_en && (label_data == CAR)) begin
            if (car_label_cnt < (CAR_COUNT_MAX - 1)) begin
                car_label_cnt <= car_label_cnt + 1;
            end
        end
    end
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            warn_car <= 0;
        end else if (human_detection_en) begin
            if (car_label_cnt == (CAR_COUNT_MAX - 1)) begin
                warn_car <= 1;
            end else begin
                warn_car <= 0;
            end
        end else if (traffic_light) begin
            warn_car <= 0;
        end
    end

    logic val_warn_car_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            val_warn_car <= 0;
            val_warn_car_flag <= 0;
        end else begin
            val_warn_car <= 0;
            if (!car_label_cnt) begin
                val_warn_car_flag <= 0;
            end
            if(human_detection_en && (car_label_cnt == (CAR_COUNT_MAX - 1)) && !val_warn_car_flag) begin
                val_warn_car <= 1;
                val_warn_car_flag <= 1;
            end
        end
    end

    // ila_0 U_ila_0 (
    //     .clk(clk),
    //     .probe0(ov7670_pclk),
    //     .probe1(traffic_light),
    //     .probe2(val_warn_car),
    //     .probe3(warn_car)
    // );

    // always_ff @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         val_warn_car_flag <= 0;
    //         val_warn_car <= 0;
    //     end else if (!val_warn_car_flag && !traffic_light) begin
    //         val_warn_car_flag <= 1;
    //         val_warn_car <= 1;
    //     end else if (!traffic_light) begin
    //         val_warn_car_flag <= 0;
    //     end else begin
    //         val_warn_car <= 0;
    //     end
    // end

    /*************************사람 무단횡단*************************/
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            human_label_cnt <= 0;
        end else if (frame_done) begin
            human_label_cnt <= 0;
        end else if (car_detection_en && (label_data == HUMAN)) begin
            if (human_label_cnt < (HUMAN_COUNT_MAX - 1)) begin
                human_label_cnt <= human_label_cnt + 1;
            end
        end
    end
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            warn_human <= 0;
        end else if (car_detection_en) begin
            if (human_label_cnt == (HUMAN_COUNT_MAX - 1)) begin
                warn_human <= 1;
            end else begin
                warn_human <= 0;
            end
        end else if (!traffic_light) begin
            warn_human <= 0;
        end
    end

    logic val_warn_human_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            val_warn_human <= 0;
            val_warn_human_flag <= 0;
        end else begin
            val_warn_human <= 0;
            if (!human_label_cnt) begin
                val_warn_human_flag <= 0;
            end
            if(car_detection_en && (human_label_cnt == (HUMAN_COUNT_MAX - 1)) && !val_warn_human_flag) begin
                val_warn_human <= 1;
                val_warn_human_flag <= 1;
            end
        end
    end


    // logic val_warn_human_flag;

    // always_ff @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         val_warn_human_flag <= 0;
    //         val_warn_human <= 0;
    //     end else if (!val_warn_human_flag && (traffic_light)) begin
    //         val_warn_human_flag <= 1;
    //         val_warn_human <= 1;
    //     end else if (traffic_light) begin
    //         val_warn_human_flag <= 0;
    //     end else begin
    //         val_warn_human <= 0;
    //     end
    // end

    wait_second U_OUT_WARN_CAR (
        .clk(clk),
        .reset(reset),
        .i_tick(val_warn_car),
        .o_tick(val_warn_car_tick)
    );

    wait_second U_OUT_WARN_HUMAN (
        .clk(clk),
        .reset(reset),
        .i_tick(val_warn_human),
        .o_tick(val_warn_human_tick)
    );
endmodule


module wait_second (
    input  logic clk,
    input  logic reset,
    input  logic i_tick,
    output logic o_tick
);

    localparam WAIT_SEC = 500_000_000;  //100Mhz -> 1sec
    //localparam WAIT_SEC = 30;  //100Mhz -> 1sec

    typedef enum {
        IDLE,
        SEND_TICK,
        WAIT
    } state_e;

    logic [31:0] cnt_reg, cnt_next;
    logic o_tick_reg, o_tick_next;

    state_e state, next_state;

    assign o_tick = o_tick_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cnt_reg <= 0;
            o_tick_reg <= 0;
        end else begin
            state <= next_state;
            cnt_reg <= cnt_next;
            o_tick_reg <= o_tick_next;
        end
    end

    always_comb begin
        next_state = state;
        cnt_next = cnt_reg;
        o_tick_next = o_tick_reg;
        case (state)
            IDLE: begin
                cnt_next = 0;
                if (i_tick) begin
                    next_state  = SEND_TICK;
                    o_tick_next = 1;
                end
            end
            SEND_TICK: begin
                o_tick_next = 0;
                next_state  = WAIT;
            end
            WAIT: begin
                if (cnt_reg == (WAIT_SEC - 1)) begin
                    next_state = IDLE;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
        endcase
    end
endmodule
