// hk_readout.v
/******************************************************************************
*
* Module:       hk_readout
*
* Organization: NASA-GSFC
* Author:       Salman Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   
*
*  child of:     
* parent of:
*
* Revisions:  - Base, 09/29/2017, S. Sheikh

*                 
*
******************************************************************************/

`timescale 1 ns / 100 ps


module hk_readout ( clk50, rst_n, words_in, hk_in, increment);
 
import        Types::*;                // import typedefs

input         clk50;                   // 50 MHz Clock
input         rst_n;
input         increment;
output [9:0] hk_in;
input a10x10 words_in;


reg [ 4:0] word_count;
reg [ 1:0] incre_reg;
reg [9:0] hk_in;

always @(posedge clk50 or negedge rst_n)  
 if (!rst_n) 
 begin
  hk_in  <= 10'h0;    //first 16'bits that gets transmitted out 
  incre_reg <= 2'b00;
  word_count <= 5'b0;
 end 
 else 
 begin
   incre_reg <= {incre_reg[0], increment};

   if (incre_reg == 2'b01) 
   begin 
     hk_in  <= words_in[word_count];
     word_count <= word_count +1;

     if (word_count == 10) 
     begin
       hk_in  <= 10'h000;
       word_count <= 5'b0;
     end
   end
 end

endmodule
