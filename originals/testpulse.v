// testpulse.v
/******************************************************************************
*
* Module:       testpulse
* Description:  APES test pulse module
*
* Organization: NASA-GSFC
* Author:       Salman I Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   
*
* Revisions:  - Base, 09/28/2017, S. Sheikh Code 564

*                 
*
******************************************************************************/

`timescale 1 ns / 100 ps

module testpulse ( clk50, rst_n, stim_en, stim_out);


input         clk50;                   
input         rst_n;                   
input         stim_en;
output        stim_out;    // ASIC Stim out


reg [7:0]  div;

reg        stim_out;

always @(posedge clk50 or negedge rst_n) if (!rst_n) 
  begin
    div <= 8'h0;
    stim_out <= 1'b0;
  end 
  else 
  begin  
   if (stim_en)
   begin
     stim_out <= div[7];
     div <= div +1;
   end
   else
     stim_out <= 1'b0;
  end 

endmodule
