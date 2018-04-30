module clk_div(clk_50mhz, rst_n, clk_100khz);
   input clk_50mhz, rst_n;
   output      clk_100khz;
   reg         clk_100khz;
   
   reg [7:0]  counter;

   always @(posedge clk_50mhz or negedge rst_n) begin
      if (!rst_n) begin
         counter <= 8'h00;
         clk_100khz <= 1'b0;
      end else begin
        if (counter == 8'hf9) begin
           counter <= 8'h00;
           clk_100khz <= ~clk_100khz;
        end else begin
           counter <= counter + 1'b1;
        end
      end // else: !if(!rst_n)
   end // always @ (posedge clk_50mhz or negedge rst_n)
endmodule // clk_div
