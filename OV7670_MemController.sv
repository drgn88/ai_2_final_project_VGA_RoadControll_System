`timescale 1ns / 1ps

module OV7670_MemController (
    input  logic        clk,
    input  logic        reset,
    // ov7670 side
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] ov7670_data,
    // memory side
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData,
    output logic        camera_dp_en,
    output logic        v_finish_camera,
    output logic [ 9:0] x_pixel_camera,
    output logic [ 9:0] y_pixel_camera
);
    logic [15:0] pixel_data;
    logic [ 9:0] h_counter;  // 320 * 2 = 640 (320 pixel)
    logic [ 9:0] v_counter;  // 240 line

    assign wAddr = v_counter * 320 + h_counter[9:1];
    assign wData = pixel_data;
    assign x_pixel_camera = h_counter / 2;
    assign y_pixel_camera = v_counter;
    assign camera_dp_en = ((x_pixel_camera < 320) && (y_pixel_camera < 240));

    // negedge_detect U_V_FINISH (
    //     .clk(clk),
    //     .reset(reset),
    //     .x(vsync),
    //     .o_tick(v_finish_camera)
    // );

    // ila_1 U_ila_1 (
    //     .clk(clk),
    //     .probe0(href),
    //     .probe1(camera_dp_en)
    // );


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            h_counter  <= 0;
            pixel_data <= 0;
            we         <= 1'b0;
        end else begin
            if (href) begin
                h_counter <= h_counter + 1;
                if (h_counter[0] == 0) begin
                    pixel_data[15:8] <= ov7670_data;
                    we               <= 1'b0;
                end else begin
                    pixel_data[7:0] <= ov7670_data;
                    we              <= 1'b1;
                end
            end else begin
                h_counter <= 0;
                we        <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (vsync) begin
                v_counter <= 0;
            end else begin
                if (h_counter == (320 * 2 - 1)) begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
    logic v_sync_flag;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_sync_flag <= 0;
            v_finish_camera <= 0;
        end else if (vsync) begin
            if (!v_sync_flag) begin
                v_sync_flag <= 1;
                v_finish_camera <= 1;
            end else begin
                v_finish_camera <= 0;
            end
        end else begin
            v_sync_flag <= 0;
            v_finish_camera <= 0;
        end
    end
endmodule

module negedge_detect (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic o_tick
);

    logic tmp_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tmp_reg <= 0;
        end else begin
            tmp_reg <= x;
        end
    end

    assign o_tick = (~x) & tmp_reg;
endmodule
