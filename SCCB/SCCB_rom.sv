`timescale 1ns / 1ps

module SCCB_rom (
    input  logic        clk,
    input  logic [ 7:0] addr,
    output logic [15:0] dout
);
    //FFFF is end of rom, FFF0 is delay
    always_ff @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  // COM7  reset
            1: dout <= 16'h12_14;  // COM7  QVGA
            2: dout <= 16'h40_d0;  // COM15 RGB565
            3: dout <= 16'h13_e7;  // COM8  AEC / AWB / AGC enable
            4: dout <= 16'h55_78;  // Brightness
            default: dout <= 16'hFF_FF;  //mark end of ROM
        endcase

    end
endmodule
/*
            0:  dout <= 16'h12_80;  //reset
            1:  dout <= 16'hFF_F0;  //delay
            2:  dout <= 16'h12_14;  // COM7,  
            3:  dout <= 16'h11_80;  // CLKRC  
            4:  dout <= 16'h0C_04;  // COM3,  
            5:  dout <= 16'h3E_19;  // COM14, 
            6:  dout <= 16'h04_00;  // COM1,  
            7:  dout <= 16'h40_10;  //COM15,  
            8:  dout <= 16'h3a_04;  //TSLB    
            9:  dout <= 16'h14_18;  //COM9    
            10: dout <= 16'h4F_B3;  //MTX1   
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17: dout <= 16'h3D_C0;

            18: dout <= 16'h17_15;  //HSTART
            19: dout <= 16'h18_03;
            20: dout <= 16'h32_00;  //HREF  
            21: dout <= 16'h19_02;  //VSTART
            22: dout <= 16'h1A_7A;  //VSTOP 
            23: dout <= 16'h03_00;  //VREF  

            24: dout <= 16'h0F_41;  //COM6  
            25: dout <= 16'h1E_00;  //MVFP  
            26: dout <= 16'h33_0B;  //CHLF  
            27: dout <= 16'h3C_78;  //COM12 
            28: dout <= 16'h69_00;  //GFIX  
            29: dout <= 16'h74_00;  //REG74 
            30: dout <= 16'hB0_84;  //RSVD  
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD  
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_f1;
            38: dout <= 16'ha2_02;
            //gamma curve values
            39: dout <= 16'h7a_20;
            40: dout <= 16'h7b_10;
            41: dout <= 16'h7c_1e;
            42: dout <= 16'h7d_35;
            43: dout <= 16'h7e_5a;
            44: dout <= 16'h7f_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8f;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_a3;
            51: dout <= 16'h86_af;
            52: dout <= 16'h87_c4;
            53: dout <= 16'h88_d7;
            54: dout <= 16'h89_e8;
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC
            57: dout <= 16'h10_00;  //set ARCJ reg to 0
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit
            60: dout <= 16'ha5_05;  //BD50MAX
            61: dout <= 16'hab_07;  //DB60MAX
            62: dout <= 16'h24_95;  //AGC upper limit
            63: dout <= 16'h25_33;  //AGC lower limit
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2
            67: dout <= 16'ha1_03;  //magic
            68: dout <= 16'ha6_d8;  //HAECC3
            69: dout <= 16'ha7_d8;  //HAECC4
            70: dout <= 16'ha8_f0;  //HAECC5
            71: dout <= 16'ha9_90;  //HAECC6
            72: dout <= 16'haa_94;  //HAECC7
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            74: dout <= 16'h69_07;
*/
