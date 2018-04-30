/******************************************************************************
*
* Module:       apes_adc
* Description:  Emulator ADC interface
*
* Organization: SwRI - Space Science and Engineering Divsion (15)
* Author:       John R. Dickinson
* Phone:        210-522-5826
* email:        john.dickinson@swri.edu
*
* Comments:
*   This module controls the analog telemetry chain on the APES Board 
*    .
*
*  child of:    
* parent of:
*
* Revisions:  - Base, 05/17/2012, J. Dickinson, SwRI
*                 Initial release.
*                 11/27/2012, J. Trevino, SwRI
*                 modified to work for DSCB
*                 06/02/2013, J. Trevino, SwRI
*                 modified to control two ADCs 
*                 
*
******************************************************************************/

`timescale 1 ns / 100 ps

module apes_adc ( clk, rst_n, regw_pls, 
  Lcla, Lcld, 
  Adc_sclk, Adc_din, Adc_dout, Adc_csn1, Adc_csn2,
  adccs_rg,  adc_int, sm_adc,
  val_adc0, val_adc1, val_adc2, val_adc3,
  val_adc4, val_adc5, val_adc6, val_adc7, adc_oshft_out
 );


input         clk;                   // 50 MHz Clock
input         rst_n;                   
input         regw_pls;                // write pulse
input  [ 8:0] Lcla;                    // Register Address
input  [31:0] Lcld;                    // Local Write Data
output        Adc_sclk;                // ADC clock out
output        Adc_din;                 // ADC data in (w.r.t. ADC)
output        Adc_csn1;                 // ADC chip select
output        Adc_csn2;
input         Adc_dout;                // ADC data out (w.r.t. ADC)
output [ 1:0] sm_adc;
output [31:0] adccs_rg;                // reg ADC Control/Status Register
output [11:0] val_adc0;                // ADC Data 0
output [11:0] val_adc1;                // ADC Data 1
output [11:0] val_adc2;                // ADC Data 2
output [11:0] val_adc3;                // ADC Data 3
output [11:0] val_adc4;                // ADC Data 4
output [11:0] val_adc5;                // ADC Data 5
output [11:0] val_adc6;                // ADC Data 6
output [11:0] val_adc7;                // ADC Data 7
output [ 3:0] adc_oshft_out;
output        adc_int;                 // ADC interrupt


integer       i;             // Index
reg    [ 1:0] cnt_dclk,      // ADC Clock
              sm_adc;        // ADC State Machine
reg           sm_ctrl,       // ADC Control state machine
              conv_en,       // Single Conversion enable
              adc_en,        // ADC enable
              adc_ien,       // ADC interrupt enable
              adc_int,       // ADC interrupt
              adc_csn;       // ADC chip select not
reg    [ 3:0] adc_oshft;     // ADC data output shift register
reg    [ 3:0] adc_oshft_temp;
reg    [11:0] adc_ishft;     // ADC data input shift register
reg    [ 3:0] cnt_shft;      // Shift Counter
reg    [ 5:0] cnt_amux;      // MUX index
reg    [11:0] adc_aray[7:0];// ADC Data Array //changed to 15->7
reg    [15:0] cnt_wait,      // ADC between convert wait count
              wtcnt_rld;     // Wait count reload value

//  IRAP ADC State Machine
always @(posedge clk or negedge rst_n) 
 if (!rst_n) begin
  cnt_dclk  <= 2'b00;                               
  sm_adc    <= 2'b00;
  sm_ctrl   <= 1'b0;
  adc_oshft <= 4'b0;
  adc_oshft_temp <= 4'b0;
  adc_ishft <= 12'b0;
  cnt_shft  <= 4'h0;
  conv_en   <= 1'b0;
  adc_en    <= 1'b0;
  cnt_amux  <= 6'b0;
  adc_ien   <= 1'b0;
  adc_int   <= 1'b0;
  adc_csn   <= 1'b1;
  for (i=0;i<8;i=i+1)    //changed to 16->8
    adc_aray[i] <= 12'h000;
  cnt_wait  <= 16'h0;
  wtcnt_rld <= 16'hFFF;

end 
else 
begin                                   

  cnt_dclk <= cnt_dclk + 1'b1;                      // inc adc clock
  
  if (regw_pls  && Lcla==9'h01C) begin            // write adc control/status
    adc_en   <= Lcld[16];                        // load adc enable
    adc_ien  <= Lcld[23];                        // load adc interrupt enable
    wtcnt_rld<= Lcld[15:0];                      // load wait count reload value
  end
  
  if (sm_adc==2'b10 && cnt_amux==6'h7)             // EXIT state / last in array   //changed to 23->15
    adc_int  <= 1'b1;                               // set adc interrupt
  else if (regw_pls && Lcla==9'h01C &&           // write adc control/status
           Lcld[31])                             // bit = 1
    adc_int  <= 1'b0;                               // reset adc interrupt

  case (sm_ctrl)                                 // adc state machine

    1'b0: begin                                     // WAIT
      cnt_wait  <= wtcnt_rld;                    // rst wait cnt for count down

      if (adc_en) begin                          // when en'd by SW wr
        conv_en <= 1'b1;                            // begin conversion
        sm_ctrl <= 1'b1;                            // goto CONVERT
      end

    end

    1'b1: begin                                     // CONVERT
      if ((sm_adc==2'b11) && &cnt_shft) begin       // after every ADC conversion
        conv_en <= 1'b0;                            // disable ADC
      end
      
      if (~conv_en)                              // when conversion is complete
        cnt_wait <= cnt_wait - 1'b1;                // begin 81.84us count down
      
      sm_ctrl <= |cnt_wait;                      // countdown ends, GOTO WAIT

    end
  endcase

  case (sm_adc)                                  // adc state machine

    2'b00: begin                                    // WAIT
      if (conv_en && (cnt_dclk==2'b11)) begin   // en'd; next cycle: adc clk hi
        cnt_shft <= cnt_shft + 1'b1;                // shift bit 15
        
        sm_adc[0] <= 1'b1;                          // goto CONVERT
        adc_csn   <= 1'b0;                          // chip select assert

      end else
        adc_csn   <= 1'b1;                          // chip select deassert

    end

    2'b01: begin                                    // CONVERT
      if (cnt_dclk==2'b11) begin                    // shift out on falling edge
        cnt_shft <= cnt_shft + 1'b1;                // shift bit 14
 
        adc_oshft <= adc_oshft_temp;            // shift data: msb 1st

        sm_adc[1] <= 1'b1;                          // goto SHIFT
      end
    end

    2'b11: begin                                    // SHIFT bits 13:0
      if (cnt_dclk==2'b01) begin                    // next cycle: adc clk hi
        adc_ishft <= {adc_ishft[10:0], Adc_dout}; // shift data: msb 1st
      
      end else if (cnt_dclk==2'b11) begin           // shift out on falling edge
        cnt_shft <= cnt_shft + 1'b1;                // inc shift counter

        adc_oshft <= {adc_oshft[ 2:0], 1'b0};       // shift data: msb 1st

        if (&cnt_shft)                           // shift counter expired
          sm_adc[0] <= 1'b0;                        // goto EXIT
      end
    end

    2'b10: begin                                    // EXIT/SHIFT bit 15
      if (cnt_dclk==2'b01) begin                    // next cycle: adc clk hi
        adc_ishft <= {adc_ishft[10:0], Adc_dout}; // shift data: msb 1st
 
      end else if (cnt_dclk==2'b11) begin           // next cycle: adc clk lo
        cnt_shft <= cnt_shft + 1'b1;                // inc shift counter
        
        adc_aray[cnt_amux] <= adc_ishft;        // register indexed adc data
       
        if (cnt_amux<6'h7)   begin                   // not last mux address count //changed to 23->15
          cnt_amux <= cnt_amux + 1'b1;              // inc mux address counter
          adc_oshft_temp <=  adc_oshft_temp + 1'b1;  // added
         
        end else  begin                                   // last mux address count
          cnt_amux <= 6'h00;                     // reset mux address count
          adc_oshft_temp <= 4'b0000;
        end


        if (conv_en)
          sm_adc    <= 2'b01;                       // goto CONVERT
        else begin
          sm_adc[1] <= 1'b0;                        // goto WAIT
          cnt_shft <= 4'h0;                        // reset counts
        end

      end
    end
  endcase
  
end

// Assign I/Os -----------------------------------------------------------------
assign
  adccs_rg   = {adc_int, 1'b0, cnt_amux,         // ADC Control Status
              adc_ien, 3'b000, 3'b000, adc_en, wtcnt_rld},
  val_adc0  = adc_aray[0],                             // GSE ADC Array
  val_adc1  = adc_aray[1],                             // GSE ADC Array
  val_adc2  = adc_aray[2],                             // GSE ADC Array
  val_adc3  = adc_aray[3],                             // GSE ADC Array
  val_adc4  = adc_aray[4],                             // GSE ADC Array
  val_adc5  = adc_aray[5],                             // GSE ADC Array
  val_adc6  = adc_aray[6],                             // GSE ADC Array
  val_adc7  = adc_aray[7];                             // GSE ADC Array


assign #10
  Adc_sclk         = cnt_dclk[1],                
  Adc_din          = adc_oshft[3],               
  Adc_csn1         = ~cnt_amux[3] ? adc_csn : 1'b1, // ADC chip select
  Adc_csn2         = 1'b1,//cnt_amux[3] ? adc_csn : 1'b1,  // ADC chip select
  adc_oshft_out    = adc_oshft; 

endmodule