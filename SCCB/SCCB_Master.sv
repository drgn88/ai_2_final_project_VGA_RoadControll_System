`timescale 1ns / 1ps

module SCCB_Master (
    input logic       clk,
    input logic       reset,
    input logic       i_start,
    input logic [7:0] i_sccb_addr,
    input logic [7:0] i_sccb_data,

    output logic sccb_clk,
    output logic o_done,
    output logic ack_error,
    inout  logic io_sio_d
);

    SCCB_clk_gen_100kHz U_SCCB_clk_gen (
        .clk  (clk),
        .reset(reset),
        .o_clk(sccb_clk)
    );

    logic [2:0] idx_couter_reg, idx_couter_next;
    logic [7:0] send_data_reg, send_data_next;
    logic sccb_data_out;
    logic sccb_data_in;  //ack
    logic o_en;

    assign io_sio_d     = o_en ? sccb_data_out : 1'bz;
    assign sccb_data_in = io_sio_d;  //ack

    typedef enum {
        IDLE,
        START,
        SEND_ID_ADDR,
        WAIT_ACK1,
        SEND_REG_ADDR,
        WAIT_ACK2,
        SEND_W_DATA,
        STOP,
        ERROR
    } s_state;

    s_state state, state_next;

    always_ff @(posedge sccb_clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            send_data_reg  <= 0;
            idx_couter_reg <= 0;
        end else begin
            state          <= state_next;
            send_data_reg  <= send_data_next;
            idx_couter_reg <= idx_couter_next;
        end
    end

    always_comb begin
        state_next      = state;
        send_data_next  = send_data_reg;
        idx_couter_next = idx_couter_reg;
        sccb_data_out   = 1'b1;
        ack_error       = 1'b0;
        o_done          = 1'b0;
        o_en            = 1'b1;
        case (state)
            IDLE: begin
                if (i_start) state_next = START;
            end
            START: begin
                sccb_data_out   = 1'b0;
                o_en            = 1'b1;
                state_next      = SEND_ID_ADDR;
                send_data_next  = 8'h42;
                idx_couter_next = 0;
            end
            SEND_ID_ADDR: begin
                sccb_data_out = send_data_reg[7-idx_couter_reg];
                o_en = 1'b1;
                if (idx_couter_reg == 7) begin
                    state_next = WAIT_ACK1;
                end else begin
                    idx_couter_next = idx_couter_reg + 1;
                end
            end
            WAIT_ACK1: begin
                sccb_data_out = 1'b1;
                o_en = 1'b0;
                if (sccb_data_in == 0) begin
                    state_next      = SEND_REG_ADDR;
                    send_data_next  = i_sccb_addr;
                    idx_couter_next = 0;
                end else begin
                    state_next = ERROR;
                end
            end
            SEND_REG_ADDR: begin
                sccb_data_out = send_data_reg[7-idx_couter_reg];
                o_en = 1'b1;
                if (idx_couter_reg == 7) begin
                    state_next = WAIT_ACK2;
                end else begin
                    idx_couter_next = idx_couter_reg + 1;
                end
            end
            WAIT_ACK2: begin
                sccb_data_out = 1'b1;
                o_en = 1'b0;
                if (sccb_data_in == 0) begin
                    state_next      = SEND_W_DATA;
                    send_data_next  = i_sccb_data;
                    idx_couter_next = 0;
                end else begin
                    state_next = ERROR;
                end
            end
            SEND_W_DATA: begin
                sccb_data_out = send_data_reg[7-idx_couter_reg];
                o_en = 1'b1;
                if (idx_couter_reg == 7) begin
                    state_next = STOP;
                end else begin
                    idx_couter_next = idx_couter_reg + 1;
                end
            end
            STOP: begin
                sccb_data_out = 1'b1;
                o_en          = 1'b1;
                if (sccb_clk) begin
                    state_next = IDLE;
                    o_done     = 1'b1;
                end
            end
            ERROR: begin
                ack_error  = 1'b1;
                state_next = IDLE;
            end
        endcase
    end

endmodule


module SCCB_clk_gen_100kHz (
    input  logic clk,
    input  logic reset,
    output logic o_clk
);

    logic [9:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            o_clk   <= 0;
        end else begin
            if (counter == 1000 - 1) begin
                counter <= 0;
                o_clk   <= 1'b1;
            end else begin
                counter <= counter + 1;
                o_clk   <= 1'b0;
            end
        end
    end
endmodule

/*
module sccb_master
#(
  parameter SYS_CLK_HZ = 100_000_000,
  parameter SCCB_CLK_HZ = 100_000
)
(
  input  logic clk,
  input  logic rst_n,
  input  logic i_start,
  input  logic [7:0] i_sccb_addr,
  input  logic [7:0] i_sccb_data,
  
  output logic o_sio_c,
  output logic o_sio_d,
  output logic o_sio_d_en,
  output logic o_done,
  output logic o_ack_error,
  inout  logic io_sio_d
);

  // --- Parameter & Local Parameter Declarations ---
  localparam [2:0]
    IDLE          = 3'd0,
    START         = 3'd1,
    SEND_ADDR     = 3'd2,
    WAIT_ACK1     = 3'd3,
    SEND_REG_ADDR = 3'd4,
    WAIT_ACK2     = 3'd5,
    SEND_DATA     = 3'd6,
    WAIT_ACK3     = 3'd7,
    STOP          = 3'd8,
    ERROR         = 3'd9;

  localparam CLK_COUNT = SYS_CLK_HZ / (SCCB_CLK_HZ * 2);

  // --- Internal Signals ---
  logic [3:0] current_state;
  logic [3:0] next_state;

  logic [7:0] data_to_send;
  logic [2:0] bit_cnt;

  logic clk_toggle;
  logic [15:0] clk_counter;

  logic sccb_clk;
  logic sccb_data_out;
  logic sccb_data_in;
  logic sccb_data_en;
  
  logic start_pulse;
  logic start_d1;
  logic start_d2;
  
  logic ack_ok;
  logic ack_error;

  // --- Bidirectional I/O for SIO_D ---
  assign io_sio_d = sccb_data_en ? sccb_data_out : 'z;
  assign sccb_data_in = io_sio_d;

  // --- Clock Divider to generate 100kHz SCCB Clock ---
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_counter <= 0;
      sccb_clk <= 0;
    end else begin
      if (clk_counter == CLK_COUNT - 1) begin
        clk_counter <= 0;
        sccb_clk <= ~sccb_clk;
      end else begin
        clk_counter <= clk_counter + 1;
      end
    end
  end

  assign o_sio_c = sccb_clk;
  
  // --- Edge Detector for START signal ---
  always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        start_d1 <= 1'b0;
        start_d2 <= 1'b0;
      end else begin
        start_d1 <= i_start;
        start_d2 <= start_d1;
      end
  end
  assign start_pulse = start_d1 & ~start_d2;

  // --- State Machine Logic (Combinational) ---
  always_comb begin
    next_state = current_state;
    sccb_data_en = 1'b0;
    sccb_data_out = 1'b1;
    ack_ok = 1'b0;
    ack_error = 1'b0;
    o_done = 1'b0;
    
    unique case (current_state)
      IDLE: begin
        if (start_pulse) begin
          next_state = START;
        end
      end
      
      START: begin
        // Start Condition: SIO_D goes from HIGH to LOW while SIO_C is HIGH
        sccb_data_out = 1'b0;
        sccb_data_en = 1'b1;
        if (sccb_clk) begin
            next_state = SEND_ADDR;
        end
      end

      SEND_ADDR: begin
        sccb_data_out = data_to_send[7-bit_cnt];
        sccb_data_en = 1'b1;
        if (clk_toggle) begin
          if (bit_cnt == 7) begin
            next_state = WAIT_ACK1;
          end else begin
            bit_cnt = bit_cnt + 1;
          end
        end
      end

      WAIT_ACK1: begin
        sccb_data_en = 1'b0; // Release SIO_D for slave
        if (clk_toggle) begin
          if (sccb_data_in == 1'b0) begin
            ack_ok = 1'b1;
            next_state = SEND_REG_ADDR;
          end else begin
            ack_error = 1'b1;
            next_state = ERROR;
          end
        end
      end

      SEND_REG_ADDR: begin
        sccb_data_out = data_to_send[7-bit_cnt];
        sccb_data_en = 1'b1;
        if (clk_toggle) begin
          if (bit_cnt == 7) begin
            next_state = WAIT_ACK2;
          end else begin
            bit_cnt = bit_cnt + 1;
          end
        end
      end

      WAIT_ACK2: begin
        sccb_data_en = 1'b0;
        if (clk_toggle) begin
          if (sccb_data_in == 1'b0) begin
            ack_ok = 1'b1;
            next_state = SEND_DATA;
          end else begin
            ack_error = 1'b1;
            next_state = ERROR;
          end
        end
      end

      SEND_DATA: begin
        sccb_data_out = data_to_send[7-bit_cnt];
        sccb_data_en = 1'b1;
        if (clk_toggle) begin
          if (bit_cnt == 7) begin
            next_state = STOP;
          end else begin
            bit_cnt = bit_cnt + 1;
          end
        end
      end
      
      STOP: begin
        // Stop Condition: SIO_D goes from LOW to HIGH while SIO_C is HIGH
        sccb_data_out = 1'b1;
        sccb_data_en = 1'b1;
        if (sccb_clk) begin
            next_state = IDLE;
            o_done = 1'b1;
        end
      end

      ERROR: begin
        o_ack_error = 1'b1;
        next_state = IDLE;
      end
      
      default: next_state = IDLE;
    endcase
  end

  // --- State Register & Data Register ---
  always_ff @(posedge sccb_clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
      data_to_send <= 8'h00;
      bit_cnt <= 0;
    end else begin
      current_state <= next_state;
      case (next_state)
        START: begin
          data_to_send <= {8'h42, i_sccb_addr, i_sccb_data}[23:16];
          bit_cnt <= 0;
        end
        SEND_REG_ADDR: begin
          data_to_send <= {8'h42, i_sccb_addr, i_sccb_data}[15:8];
          bit_cnt <= 0;
        end
        SEND_DATA: begin
          data_to_send <= {8'h42, i_sccb_addr, i_sccb_data}[7:0];
          bit_cnt <= 0;
        end
      endcase
    end
  end

endmodule
*/
