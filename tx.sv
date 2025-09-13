`timescale 1ns / 1ps



module uart_tx (
    input  logic       clk,
    input  logic       reset,
    input  logic       baud_tick,
    input  logic       start,
    input  logic [7:0] din,
    output logic       o_tx_done,
    output logic       o_tx_busy,
    output logic       o_tx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;


    logic [1:0] c_state, n_state;
    logic tx_out_reg, tx_out_next;
    logic [2:0] data_count_reg, data_count_next;
    logic [3:0] b_cnt_reg, b_cnt_next;
    logic tx_done_reg, tx_busy_reg, tx_busy_next, tx_done_next;
    logic [7:0] tx_din_reg, tx_din_next;



    assign o_tx = tx_out_reg;
    assign o_tx_done = tx_done_reg;
    assign o_tx_busy = tx_busy_reg;




    ///================state reg===============
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state        <= 0;
            tx_out_reg     <= 1'b1;  //TX의 출력 초기값은 high
            data_count_reg <= 0;
            b_cnt_reg      <= 0;  //baud tick을 0부터 센다
            tx_done_reg    <= 1'b0;
            tx_busy_reg    <= 1'b0;
            tx_din_reg     <= 0;
        end else begin
            c_state        <= n_state;
            tx_out_reg     <= tx_out_next;
            data_count_reg <= data_count_next;
            b_cnt_reg      <= b_cnt_next;
            tx_done_reg    <= tx_done_next;
            tx_busy_reg    <= tx_busy_next;
            tx_din_reg     <= tx_din_next;
        end
    end





    //===============CL for next_state==============
    always_comb begin
        n_state         = c_state;
        tx_out_next     = tx_out_reg;
        data_count_next = data_count_reg;
        b_cnt_next      = b_cnt_reg;
        tx_done_next    = tx_done_reg;
        tx_busy_next    = tx_busy_reg;
        tx_din_next     = tx_din_reg;
        case (c_state)

            IDLE: begin
                b_cnt_next = 0;
                data_count_next = 0;
                tx_out_next = 1'b1;
                tx_done_next = 1'b0;
                tx_busy_next = 1'b0;
                if (start == 1'b1) begin
                    n_state = START;//상태에 따라 출력이 결정되도록 하려고 하면, tick을 기다리는 동작을 구현할 수 없음. state를 미리 이동시키고 tick은 나중에 check하는 방식으로 구현한다
                    tx_busy_next = 1'b1;
                    tx_din_next = din;
                end
            end

            START: begin
                if (baud_tick == 1'b1) begin
                    tx_out_next = 0;
                    if (b_cnt_reg == 8) begin
                        n_state = DATA;
                        data_count_next = 0;
                        b_cnt_next = 0;
                    end else begin
                        b_cnt_next = b_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_out_next = tx_din_reg[data_count_reg];  // LSB first
                if (baud_tick == 1'b1) begin
                    if (b_cnt_reg == 7) begin
                        if (data_count_reg == 3'd7) begin
                            n_state = STOP;
                        end
                        b_cnt_next = 0;
                        data_count_next = data_count_reg + 1;
                    end else begin
                        b_cnt_next = b_cnt_reg + 1;
                    end
                end
            end

            STOP:
            if (baud_tick == 1'b1) begin
                tx_out_next = 1'b1;
                if (b_cnt_reg == 7) begin
                    n_state = IDLE;
                    tx_done_next = 1'b1;
                    tx_busy_next = 1'b0;
                end else begin
                    b_cnt_next = b_cnt_reg + 1;
                end
            end


        endcase
    end





endmodule
