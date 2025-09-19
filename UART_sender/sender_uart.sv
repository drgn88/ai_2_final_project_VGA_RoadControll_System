// `timescale 1ns / 1ps

// module sender_uart (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       start,            // 송신 시작 신호
//     input  logic [9:0] x_min,
//     input  logic [9:0] x_max,
//     input  logic [9:0] y_min,
//     input  logic [9:0] y_max,
//     input  logic       traffic_light,    // 0=green,1=red
//     input  logic       human_violation,  // 0:없음,1:발생
//     input  logic       car_violation,    // 0:없음,1:발생
//     input  logic        traffic_amount,   // 0:적음,1:보통,2:많음
//     output logic       tx,
//     output logic       rx_done,
//     input  logic       rx,
//     output logic [7:0] rx_pop_data
// );

//     // FSM 상태
//     logic [1:0] c_state, n_state;
//     logic [7:0] send_data_reg, send_data_next;
//     logic send_reg, send_next;
//     logic [3:0] send_cnt_reg, send_cnt_next;  // 0~8까지 9바이트 전송

//     // UART 인터페이스
//     logic w_tx_full, tx_done;

//     uart_controller U_UART_CTRL (
//         .clk(clk),
//         .reset(reset),
//         .tx_push_data(send_data_reg),
//         .rx(rx),
//         .tx_push(send_reg),
//         .rx_pop(),
//         .rx_done(rx_done),
//         .rx_empty(),
//         .tx_done(tx_done),
//         .tx_full(w_tx_full),
//         .rx_pop_data(rx_pop_data),
//         .tx(tx),
//         .tx_busy()
//     );

//     // FSM 레지스터
//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             c_state       <= 0;
//             send_data_reg <= 0;
//             send_reg      <= 0;
//             send_cnt_reg  <= 0;
//         end else begin
//             c_state       <= n_state;
//             send_data_reg <= send_data_next;
//             send_reg      <= send_next;
//             send_cnt_reg  <= send_cnt_next;
//         end
//     end

//     // FSM combinational
//     always_comb begin
//         n_state        = c_state;
//         send_data_next = send_data_reg;
//         send_next      = 0;
//         send_cnt_next  = send_cnt_reg;

//         case (c_state)
//             0: begin
//                 if (start) begin
//                     n_state = 1;
//                     send_cnt_next = 0;
//                 end
//             end
//             1: begin
//                 if (~w_tx_full) begin
//                     send_next = 1'b1;
//                     case (send_cnt_reg)
//                         0: send_data_next = x_min[9:8];
//                         1: send_data_next = x_min[7:0];
//                         2: send_data_next = x_max[9:8];
//                         3: send_data_next = x_max[7:0];
//                         4: send_data_next = y_min[9:8];
//                         5: send_data_next = y_min[7:0];
//                         6: send_data_next = y_max[9:8];
//                         7: send_data_next = y_max[7:0];
//                         8:
//                         send_data_next = {
//                             traffic_light,
//                             human_violation,
//                             car_violation,
//                             traffic_amount,
//                             4'b0000
//                         };
//                         // 남은 2비트는 reserved
//                     endcase

//                     if (send_cnt_reg < 8) send_cnt_next = send_cnt_reg + 1;
//                     else n_state = 0;  // 끝나면 idle
//                 end
//             end
//         endcase
//     end

// endmodule

`timescale 1ns / 1ps

module sender_uart (
    input logic       clk,
    input logic       reset,
    input logic       start,            // 송신 시작 신호
    input logic [9:0] x_min,
    input logic [9:0] x_max,
    input logic [9:0] y_min,
    input logic [9:0] y_max,
    input logic [4:0] red_left_time,
    input logic [4:0] green_left_time,
    input logic       traffic_light,    // 1=green,0=red
    input logic       human_violation,  // 0:없음,1:발생
    input logic       car_violation,    // 0:없음,1:발생
    input logic       traffic_amount,   // 0:적음,1많음
    output logic      tx,
    output logic      rx_done,
    input  logic      rx,
    output logic [7:0] rx_pop_data
);

    // FSM 상태
    logic [1:0] c_state, n_state;
    logic [7:0] send_data_reg, send_data_next;
    logic send_reg, send_next;
    logic [3:0] send_cnt_reg, send_cnt_next;  // 0~11까지 12바이트 전송

    // UART 인터페이스
    logic w_tx_full, tx_done;

    uart_controller U_UART_CTRL (
        .clk(clk),
        .reset(reset),
        .tx_push_data(send_data_reg),
        .rx(rx),
        .tx_push(send_reg),
        .rx_pop(),
        .rx_done(rx_done),
        .rx_empty(),
        .tx_done(tx_done),
        .tx_full(w_tx_full),
        .rx_pop_data(rx_pop_data),
        .tx(tx),
        .tx_busy()
    );

    // FSM 레지스터
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state       <= 0;
            send_data_reg <= 0;
            send_reg      <= 0;
            send_cnt_reg  <= 0;
        end else begin
            c_state       <= n_state;
            send_data_reg <= send_data_next;
            send_reg      <= send_next;
            send_cnt_reg  <= send_cnt_next;
        end
    end

    // FSM combinational
    always_comb begin
        n_state        = c_state;
        send_data_next = send_data_reg;
        send_next      = 0;
        send_cnt_next  = send_cnt_reg;

        case (c_state)
            0: begin
                if (start) begin
                    n_state = 1;
                    send_cnt_next = 0;
                end
            end

            1: begin
                if (~w_tx_full) begin
                    send_next = 1'b1;
                    case (send_cnt_reg)
                        0:  send_data_next = 8'hAB;  // header
                        1:  send_data_next = {3'b000, red_left_time - 1};
                        2:  send_data_next = {3'b000, green_left_time - 1};
                        3:  send_data_next = x_min[9:8];
                        4:  send_data_next = x_min[7:0];
                        5:  send_data_next = x_max[9:8];
                        6:  send_data_next = x_max[7:0];
                        7:  send_data_next = y_min[9:8];
                        8:  send_data_next = y_min[7:0];
                        9:  send_data_next = y_max[9:8];
                        10: send_data_next = y_max[7:0];
                        11: send_data_next = {
                                traffic_light,
                                human_violation,
                                car_violation,
                                traffic_amount,
                                4'b0000
                             };
                        // 남은 2비트는 reserved
                    endcase



                    if (send_cnt_reg < 11) send_cnt_next = send_cnt_reg + 1;
                    else begin
                            n_state = 0;  // 끝나면 idle
                    end
                end
            end
        endcase
    end

endmodule
