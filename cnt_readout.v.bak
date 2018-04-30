// cnt_readout.v
/******************************************************************************
*
* Module:       cnt_readout
*
* Organization: NASA-GSFC
* Author:       Salman Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   
*  child of:     
* parent of:
*
* Revisions:  - Base, 09/29/2017, S. Sheikh 

*                 
*
******************************************************************************/



module cnt_readout ( 
     clk50, rst_n, clr_rdout, increment, words_in, 
     cnt_in, rdout_done);
 
import        Types::*;                // import typedefs

input         clk50;                   
input         rst_n;
input         clr_rdout;
input         increment;
input  a52x10 words_in; 

output  [9:0] cnt_in;
output        rdout_done;

reg [6:0] word_count;
reg [1:0] incre_reg;
reg [9:0] cnt_in;
reg       rdout_done;

always @(posedge clk50 or negedge rst_n)
if (!rst_n) 
   begin
     cnt_in  <= 10'h234;    //first 10'bits that gets transmitted out 
     incre_reg <= 2'b00;
     word_count <= 7'b0;
     rdout_done <= 1'b0;
   end 
else 
begin
     incre_reg <= {incre_reg[0], increment};

     if (clr_rdout) 
         rdout_done <= 1'b0;

     if (incre_reg == 2'b01) 
       begin 
         cnt_in  <= words_in[word_count];
         word_count <= word_count + 1;
         rdout_done <= 1'b0;
       end
     if (word_count == 52) 
       begin  
         cnt_in  <= 10'h2BF;
         word_count <= 7'b0;
         rdout_done <= 1'b1;
      end
end

endmodule
