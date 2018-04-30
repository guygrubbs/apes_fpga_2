// syncn.v
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*  Synchronizer - synchronous output from asynchronous input                   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
module syncn (
input         clk,           // Clock
              rst_n,           // Reset
              async_in,      // Asynchronous Input
output        sync_out);     // Synchronized Output

//localparam    O=1'b0,l=1'b1; // onetickbeemyass
reg    [ 1:0] shift;         // Shift reg

always @(negedge clk or negedge rst_n)
  if (~rst_n) shift[0] <= 1;    // async reset
  else shift[0] <= async_in; // clocked: sync input
always @(posedge clk or negedge rst_n)
  if (~rst_n) shift[1] <= 1;    // async reset
  else shift[1] <= shift[0]; // shift left

assign sync_out = shift[1];  // Synchronized Output

endmodule
