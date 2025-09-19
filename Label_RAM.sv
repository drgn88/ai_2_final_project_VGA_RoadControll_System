`timescale 1ns / 1ps

module Label_RAM (
    input  logic        wclk,
    //write side
    input  logic        we,
    input  logic [16:0] w_addr,
    input  logic [ 2:0] write_data,
    //read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] r_addr,
    output logic [ 2:0] read_data
);

    logic [2:0] mem[0:((320*240)-1)];

    always_ff @(posedge wclk) begin
        if (we) begin
            mem[w_addr] <= write_data;
        end
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            read_data <= mem[r_addr];
        end
    end
endmodule
