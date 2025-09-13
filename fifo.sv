`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/27 14:10:49
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo (
    input  wire       clk,
    input  wire       reset,
    input  wire       push,
    input  wire       pop,
    input  wire [7:0] push_data,
    output wire       full,
    output wire       empty,
    output wire [7:0] pop_data

);

    wire [3:0] w_w_ptr, w_r_ptr;


    register_file #(
        .DEPTH(16),
        .WIDTH(4)
    ) U_REG_FILE (
        .clk(clk),
        .wr_en(push & (~full)),
        .wdata(push_data),
        .w_ptr(w_w_ptr),  //write address
        .r_ptr(w_r_ptr),  //read address
        .rdata(pop_data)
    );




    fifo_cu U_FIFOCU (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .w_ptr(w_w_ptr),
        .r_ptr(w_r_ptr),
        .full (full),
        .empty(empty)

    );







endmodule









module register_file #(
    parameter DEPTH = 16,
    WIDTH = 4
) (
    input  wire             clk,
    input  wire             wr_en,
    input  wire [      7:0] wdata,
    input  wire [WIDTH-1:0] w_ptr,  //write address
    input  wire [WIDTH-1:0] r_ptr,  //read address
    output wire [      7:0] rdata
);

    reg [7:0] mem[0:DEPTH-1];  // mem[0:2**WIDTH-1]

    assign rdata = mem[r_ptr];//bram을 사용하지 않고 combinational logic으로.

    always @(posedge clk) begin
        if (wr_en) begin
            mem[w_ptr] <= wdata;
        end
    end


endmodule




module fifo_cu (
    input  wire       clk,
    input  wire       reset,
    input  wire       push,
    input  wire       pop,
    output wire [3:0] w_ptr,
    output wire [3:0] r_ptr,
    output wire       full,
    output wire       empty

);


    reg [3:0] w_ptr_reg, w_ptr_next, r_ptr_reg, r_ptr_next;
    reg full_reg, full_next, empty_reg, empty_next;


    assign w_ptr = w_ptr_reg;
    assign r_ptr = r_ptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;

        end
    end


    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            pop, push
        })
            2'b01: begin
                if (full_reg == 1'b0) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                    if (w_ptr_next == r_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end

            2'b10: begin
                if (empty_reg == 1'b0) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                    if (r_ptr_next == w_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end

            2'b11: begin
                if (empty_reg == 1'b1) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                end else begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                end
            end

        endcase
    end




endmodule
