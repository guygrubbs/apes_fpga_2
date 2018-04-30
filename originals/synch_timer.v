// synch_timer.v

`timescale 1 ns / 100 ps
module synch_timer 
  ( clk50, rst_n, enable, clr, collect_enable);

input         clk50;                   
input         rst_n;
input         clr;                  
input         enable;                 
            
output reg    collect_enable;

reg  [14:0] counter;
reg  [7:0]  div_count;
reg         div_clk;

always @(posedge clk50 or negedge rst_n) 
  if (!rst_n) 
  begin
    div_count <= 8'b0;
    div_clk <= 1'b0;
  end 
  else 
  begin
    div_count <= div_count + 1;
    div_clk <= div_count[7]; //Flip div_clk every 2^8 cycles
  end 

always @(posedge div_clk or negedge rst_n or posedge clr) 
if (!rst_n) 
  begin
    counter  <= 15'h0000;
   end 
else if (clr) 
     begin           
       counter <=  15'h0000; 
     end  
else
     if (enable) 
     begin
       counter <= counter + 1; 
     end
//   end

always @(posedge clk50 or negedge rst_n) 
  if (!rst_n) 
  begin
     collect_enable <= 1'b0;    
  end 
  else 
  begin
    if (counter < 380) //Collect time = counter*2^8*2E-8 (s)
      collect_enable <= 1'b0;
    else
      collect_enable <= 1'b1;
  end

endmodule
