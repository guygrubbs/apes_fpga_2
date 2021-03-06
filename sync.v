/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*  Synchronizer - synchronous output from asynchronous input                   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
`timescale 1 ns / 100 ps
module sync (
input         clk,           // Clock
              rst_n,         // Reset
              async_in,      // Asynchronous Input
output        sync_out);     // Synchronized Output

reg    [ 1:0] shift;         // Shift reg

always @(negedge clk or negedge rst_n)
  if (~rst_n) shift[0] <= 0;    // async reset
  else shift[0] <= async_in; // clocked: sync input
always @(posedge clk or negedge rst_n)
  if (~rst_n) shift[1] <= 0;    // async reset
  else shift[1] <= shift[0]; // shift left

assign sync_out = shift[1];  // Synchronized Output

endmodule
