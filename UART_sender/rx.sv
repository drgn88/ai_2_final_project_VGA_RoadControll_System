`timescale 1ns / 1ps



module uart_rx (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       b_tick,
    output logic       o_rx_done,
    output logic [7:0] o_dout
);


    localparam IDLE = 0, START = 1, DATA = 2, DATA_READ = 3, STOP = 4;

    logic [2:0] c_state, n_state;
    logic [3:0] b_cnt_reg, b_cnt_next;
    logic [3:0] data_cnt_reg, data_cnt_next;
    logic [7:0] dout_reg, dout_next;
    logic rx_done_reg, rx_done_next;


    assign o_dout = dout_reg;
    assign o_rx_done = rx_done_reg;



    ////==================== state logic ==========================
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state      <= IDLE;
            b_cnt_reg    <= 0;
            data_cnt_reg <= 0;
            dout_reg     <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state      <= n_state;
            b_cnt_reg    <= b_cnt_next;
            data_cnt_reg <= data_cnt_next;
            dout_reg    <= dout_next;
            rx_done_reg <= rx_done_next;
        end
    end




    /// 

    always_comb begin
        n_state       = c_state;
        b_cnt_next    = b_cnt_reg;
        data_cnt_next = data_cnt_reg;
        dout_next     = dout_reg;
        rx_done_next = rx_done_reg;

        case (c_state)
            IDLE: begin
                b_cnt_next = 0;
                data_cnt_next = 0;
                rx_done_next = 0;
                if (b_tick) begin
                    if (rx == 0) begin
                        n_state = START;
                    end
                end
            end


            START: begin
                if (b_tick) begin
                    if (b_cnt_reg == 11) begin
                        n_state = DATA_READ;
                        b_cnt_next = 0;
                    end else b_cnt_next = b_cnt_reg + 1;
                end
            end


            DATA_READ: begin
                dout_next = {rx, dout_reg[7:1]};
                n_state   = DATA;
            end


            DATA: begin
                if (b_tick) begin
                    if (b_cnt_reg == 7) begin
                        if (data_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            data_cnt_next = data_cnt_reg + 1;
                            b_cnt_next = 0;
                            n_state = DATA_READ;
                        end
                    end
                    else b_cnt_next = b_cnt_reg + 1;
                end 
            end


            STOP: begin
                if (b_tick) begin
                    n_state = IDLE;
                    rx_done_next = 1;
                end
            end

        endcase

    end


endmodule
