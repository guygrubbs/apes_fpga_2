// apes_counter.v
/******************************************************************************
*
* Module:       apes_counter
* Description:   
*
* Organization: SwRI - Space Science and Engineering Divsion (15)
* Author:       John A. Trevino
* Phone:        210-522-3837
* email:        john.trevino@swri.edu
*
* Comments:
*   
*
*  child of:     
* parent of:
*
* Revisions:  - Base, 09/12/2013, J. Trevino, SwRI

*                 
*
******************************************************************************/

// Set simulator time unit / resolution
`timescale 1 ns / 100 ps

module apes_counter 
       (clk, rst_n, enable,
        clr, d, q);
parameter     n = 10;

input         clk;                   
input         rst_n;
input         clr;                  
input         enable;
input         d;

output   [(n-1):0]     q;
 
reg [(n-1):0] q = 0;
reg [1:0] d_shft;       //d shift in

 
always @(posedge clk or negedge rst_n) 
 if (!rst_n) 
 begin
   q <= 0;
   d_shft <= 2'b00;
 end 
 else 
 begin 
   d_shft <= {d_shft[0], d};
   
   if (clr) 
     q <= 0;
   else if (enable)
   begin
     if (d_shft == 2'b01)
        q <= q + 1;
    end
  end

endmodule
