`timescale 1ns / 1ps

module OV7670_Setting (
    input logic clk,
    input logic reset,

    output logic sccb_clk,
    inout  logic io_sio_d
);

    logic        i_start;
    logic        o_done;
    logic        ack_error;
    logic [ 7:0] rom_addr;
    logic [15:0] dout;

    SCCB_Master U_SCCB_Master (
        .*,
        .i_sccb_addr(dout[15:8]),
        .i_sccb_data(dout[7:0])
    );

    SCCB_rom U_SCCB_rom (
        .clk (clk),
        .addr(rom_addr),
        .dout(dout)
    );

    always_ff @(posedge sccb_clk or posedge reset) begin
        if (reset) begin
            rom_addr <= 0;
            i_start  <= 0;
        end else begin
            if (o_done) begin
                rom_addr <= rom_addr + 1;
            end
            if (rom_addr < 5) begin
                i_start <= 1;
            end else begin
                i_start <= 0;
            end
        end
    end
endmodule
