/******************************************************************************
*
* Module:       apes_dac1
* Description:  APES DAC interface
*
* Organization: NASA-GSFC
* Author:       Salman I Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   This module controls the DACs on the APES Board
*    
*
*  child of:    
* parent of:
*
* Revisions:  - Base, 05/17/2012, J. Dickinson, SwRI
*                 Initial release.
*  
*
******************************************************************************/

`timescale 1 ns / 100 ps
module apes_dac1 #(
  parameter select = 0)

( clk50, rst_n, dac_rst,
  regw_pls, Lcla, Lcld, 
  Dac_clk, Dac_dat, CTRL_ENn, 
  dac_reg, pa_sm_dac_out);


input         clk50;                   // 50 MHz Clock
input         rst_n;                   // Reset not
input         dac_rst;                 // DAC Reset
input         regw_pls;                // Reg Write Pulse
input  [ 8:0] Lcla;                    // Register Address
input  [31:0] Lcld;                    // Local Write Data
output        Dac_clk;                 // DAC Clock
output        Dac_dat;                 // DAC Data
output        CTRL_ENn;                // DAC Data
output [ 1:0] pa_sm_dac_out;
output [31:0] dac_reg;                 // DAC Register


reg    [ 5:0] pa_cnt_dclk;   // PA DAC Clock
reg    [ 1:0] pa_sm_dac;     // PA DAC State Machine
reg           pa_dac_init;   // DAC Initialize
reg    [14:0] pa_dac_shft;   // PA DAC Data Shift Register
reg           dac_en_n;      // DAC Enables not
reg    [ 3:0] pa_cnt_shft;   // PA Shift Counter



// DAC State Machine
always @(posedge clk50 or negedge rst_n) 
 if (!rst_n) 
 begin
  pa_cnt_dclk <= 6'b0;                         
  pa_sm_dac   <= 2'b00;
  pa_dac_init <= 1'b1;
  pa_dac_shft <= 16'h04D9;
  dac_en_n <= 1'b1;
  pa_cnt_shft <= 4'h0;

  end 
  else 
  begin                                   

  pa_cnt_dclk <= pa_cnt_dclk + 1'b1;                // inc dac clock

  case (pa_sm_dac)                               // dac state machine

    2'b00: begin                                    // IDLE
      if (pa_dac_init)                           // initialize dac
        pa_sm_dac[0] <= 1'b1;                       // goto ENABLE

      else if (dac_rst)                          // dac reset
        pa_dac_init <= 1'b1;                        // set dac initialize

      else if (regw_pls &&                       // fsw wr pa dac reg: allowed
          Lcla==9'h008 && Lcld[15:12] == select) begin
        pa_dac_shft <= {3'b000, Lcld[11:0]};        // load dac data
        pa_sm_dac[0] <= 1'b1;                       // goto ENABLE
      end
    end

    2'b01: begin                                    // ENABLE
      if (!pa_cnt_dclk[5] & &pa_cnt_dclk[4:0]) begin // next cycle: dac clock hi
        dac_en_n <= 1'b0;                        // set pa hvps enable
        pa_sm_dac[1] <= 1'b1;                       // goto SHIFT
      end
    end

    2'b11: begin                                    // SHIFT
      if (!pa_cnt_dclk[5] & &pa_cnt_dclk[4:0]) begin // next cycle: dac clock hi
        if (|pa_cnt_shft)                        // counts 1-15
          pa_dac_shft <= {pa_dac_shft[13:0], 1'b0}; // shift data: msb 1st
        if (&pa_cnt_shft) begin                  // shift counter expired
          dac_en_n   <= 1'b1;                    // reset dac enable

          pa_sm_dac[0]  <= 1'b0;                    // goto EXIT
        end
        pa_cnt_shft <= pa_cnt_shft + 1'b1;          // inc shift counter
      end
    end

    2'b10: begin                                    // EXIT
      if (!dac_rst) begin                        // dac reset released
        pa_dac_init <= 1'b0;                        // reset dac initialize
        if (!pa_dac_init)                        // initialize off
          pa_sm_dac[1] <= 1'b0;                     // goto IDLE
      end
    end
  endcase
end

assign
  dac_reg = {|pa_sm_dac, 3'b000, 4'h0, 8'h00,        // PA DAC Register
              4'h0, pa_dac_shft[11:0]};


assign #10
  Dac_clk       = pa_cnt_dclk[5],             // PA DAC Clock  
  Dac_dat       = pa_dac_shft[14],            // PA DAC Data   
  CTRL_ENn      = dac_en_n,                  // PA DAC Data   
  pa_sm_dac_out = pa_sm_dac;

endmodule
