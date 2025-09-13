`timescale 1ns / 1ps

module baud_rate (
    input  logic clk,
    input  logic reset,
    output logic baud_tick
);

    parameter BAUD = 9600;
    parameter BAUD_COUNT = 100_000_000 / (BAUD * 8);
    logic [$clog2(BAUD_COUNT)-1 : 0] count_reg, count_next;//baud rate 1200일 때 가장 큰 countreg가 필요하므로 20bit를 defalut로
    logic baud_tick_reg, baud_tick_next;



    assign baud_tick = baud_tick_reg;




    always @(posedge clk, posedge reset) begin
        if (reset) begin 
            count_reg <= 0;
            baud_tick_reg <= 0;
        end
        else begin
            count_reg <= count_next;
            baud_tick_reg <= baud_tick_next;
        end
    end




    always @(*) begin
        count_next = count_reg;
        baud_tick_next = 0;
        if(count_reg == BAUD_COUNT - 1)begin
            count_next = 0;
            baud_tick_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
            baud_tick_next = 1'b0;
        end

    end

endmodule
