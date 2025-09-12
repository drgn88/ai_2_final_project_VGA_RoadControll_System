`timescale 1ns / 1ps


module tb_Signal_CU();

  
    logic clk;
    logic reset;
    logic [1:0] traffic_sel;
    logic o_tr_light;
    logic [1:0] o_tr_state;
    logic tr_valid;
    logic light_valid;


    Signal_CU DUT (
        .clk(clk),
        .reset(reset),
        .traffic_sel(traffic_sel),
        .o_tr_light(o_tr_light),
        .o_tr_state(o_tr_state),
        .tr_valid(tr_valid),
        .light_valid(light_valid)


    );
    initial clk = 0;
    always #5 clk=~clk;
     initial begin
    
 

   
    reset = 1;
    #20;
    reset = 0;
    
    
    traffic_sel = 2'b00;  // 유동량 보통
    #5000;
    traffic_sel = 2'b01; // 유동량 적음(차)
    #5000;
    traffic_sel = 2'b10; // 유동령 많

    

  
    
  end

  
endmodule
