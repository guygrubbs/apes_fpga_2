// parallel_shifter.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SwRI
// Engineer: John A. Trevino
// 
// Create Date:    14:49:30 08/07/2010 
// Design Name:    Greece Ebox Ctrl for handshaking
// Module Name:    counter_xbits 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This module takes in a parallel data bus and transmits out 
// serially 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module parallel_shifter #(
  parameter n = 9) 
  
  (clk50,  rst_n,
  gclk, loadn, enable, 
  dbus_in, increment, serial_out);

input         clk50,                   // 50 MHz Clock
              gclk,                    // 10 MHz Gated Clock from Wallops
              rst_n,                   // Reset not
              enable,
              loadn;                   // latch data   
input  [ n:0] dbus_in;                 // parallel data bus input
output        increment;
output        serial_out;              // serial output data


// Signals ---------------------------------------------------------------------
reg    [n:0] data_shft = 10'h000;   // Data Shift Register
reg          increment;
reg    [1:0] gclk_reg;



always @(posedge clk50 or negedge rst_n) 
if (!rst_n) 
 begin
  increment <= 0;
  data_shft <= 16'b0;
  gclk_reg <= 2'b0;
 end 
else 
 begin
  if (enable) 
  begin
    gclk_reg <= {gclk_reg[0],gclk};
    if (~loadn) 
    begin
      data_shft <=  dbus_in;
      increment <= 1;
    end
    else if (gclk_reg[1:0] == 2'b01) 
    begin
      data_shft <= {data_shft[(n-1):0], 1'b0};
      increment <= 0;
    end
  end
  else
  begin
    increment <= 0;
    data_shft <= 16'b0;
    gclk_reg <= 2'b0;
  end
end
 
// Assign I/Os -----------------------------------------------------------------

assign serial_out = data_shft[n];             // Serial data shift register  


endmodule
