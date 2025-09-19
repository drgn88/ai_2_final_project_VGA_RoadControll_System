`timescale 1ns / 1ps

module VGA_MemController (
    // VGA side
    input  logic        DE,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [ 9:0] x_min,
    input  logic [ 9:0] y_min,
    input  logic [ 9:0] x_max,
    input  logic [ 9:0] y_max,
    // Label RAM side
    output logic        den,
    output logic [16:0] rAddr,
    input  logic [ 2:0] rData,
    // export side
    output logic [ 3:0] r_port,
    output logic [ 3:0] g_port,
    output logic [ 3:0] b_port
);

    // 000: ROAD            --- 검정
    // 001: WALKROAD       --- 흰색
    // 010: BACKGROUN색     
    // 011: CAR             --- 빨간색
    // 100: HUMAN           --- 초록색

    assign den   = DE && (x_pixel < 320) && (y_pixel < 240);  // QVGA Area
    assign rAddr = den ? (y_pixel * 320 + x_pixel) : 17'bz;

    always_comb begin
        if (den) begin
            if((x_pixel > x_min) && (x_pixel < x_min+20) && (y_pixel > y_min) && (y_pixel < y_min+20)) begin
                {r_port, g_port, b_port} = 12'hF0F;
            end
            else if((x_pixel < x_max) && (x_pixel > x_max-20) && (y_pixel < y_max) && (y_pixel > y_max-20)) begin
                {r_port, g_port, b_port} = 12'hFF0;
            end else begin
                {r_port, g_port, b_port} = 12'h000;
                case (rData)
                    3'b000: {r_port, g_port, b_port} = 12'hF00;
                    3'b001: {r_port, g_port, b_port} = 12'h0F0;
                    3'b010: {r_port, g_port, b_port} = 12'h00F;
                    3'b011: {r_port, g_port, b_port} = 12'hFFF;
                    3'b100: {r_port, g_port, b_port} = 12'h000;
                endcase
            end
        end else begin
            {r_port, g_port, b_port} = 12'h000;
        end
    end

endmodule
