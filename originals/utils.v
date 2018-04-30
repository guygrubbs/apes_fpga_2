// @@@@@@@@@@@@@@@@@@@ THIS MODULE MUST BE COMPILED FIRST @@@@@@@@@@@@@@@@@@@ //
// !!!!!!!!!!!! THIS MODULE REQUIRES SYSTEM VERILOG TO COMPILE !!!!!!!!!!!!!! //
// SystemVerilog Module I/O & Type Defines -------------------------------------
timeunit 1ns; timeprecision 100ps;     // `timescale

package Types;                         //  Create a typedef file: Types.sv
  typedef logic [15:0] a32x16[31:0];   // 32 by 16 Array
  typedef logic [15:0] a18x16[17:0];   
  typedef logic [15:0] a98x16[97:0];   // 98 by 16 Array
  typedef logic [15:0] a52x16[51:0];   // 51 by 16 Array
  typedef logic [9:0]  a52x10[51:0];   // 51 by 10 Array (Data)
  typedef logic [9:0]  a10x10[9:0];   // 10 by 10 Array (HK)

endpackage


//-------1---------2---------3---------4---------5---------6---------7---------8
// Pulse Generator
// Revision: -
//
// Created  10/05/09:  Mark Johnson  210-522-2419  majohnson@swri.edu
//
// Comments: Verilog 2001 must be enabled!
//   Generates synchronous pulse from i/p pulse < 1 clock period in length

module pulse_gen (
input         clock,         // Clock
              reset_n,       // Reset not
              pls_in,        // Input Pulse
output        pls_out);      // Output Pulse

parameter O=1'b0, l=1'b1;    // onetickbeemyass

reg    [ 2:0] pls_shft;      // Pulse Shift reg

always @(posedge clock or posedge pls_in or negedge reset_n) // -- LSB async set
  if (!reset_n)         pls_shft[0] <= O;        // async reset
  else if (pls_in)      pls_shft[0] <= l;        // async set
  else                                           // clocked
    if (pls_shft[2])    pls_shft[0] <= O;        // last bit set: reset 1st bit

always @(posedge clock or negedge reset_n) // --------------------- Shift LSB in
  if (!reset_n)                                  // async reset
    pls_shft[2:1] <= {2{O}};

  else                                           // clocked
    if (!pls_shft[2])                            // last bit not set yet
      pls_shft[2:1] <= pls_shft[1:0];            // shift left
    else                                         // last bit set
      pls_shft[2:1] <= {2{O}};                   // reset shift reg

assign
  pls_out  = pls_shft[2];    // Output Pulse
endmodule
