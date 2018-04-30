// apes_fsm.v
/******************************************************************************
*
* Module:       apes_fsm
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
* Revisions:  - Base, 09/09/2013, J. Trevino, SwRI

*
*
******************************************************************************/
// Set simulator time unit / resolution

`timescale 1 ns / 100 ps

module apes_fsm ( clk50, rst_n, collect_done, en_rocket_rd,
              rdout_done, cnt_start, cnt_clr);

input        clk50;
input        rst_n;
input        collect_done;
input        rdout_done;
output       en_rocket_rd;
output       cnt_start;
output       cnt_clr;

reg    [1:0] state;
reg          en_rocket_rd;
reg          cnt_start;
reg          cnt_clr;


always @(posedge clk50 or negedge rst_n)
if (!rst_n) begin
  cnt_start   <= 1'b0;
  cnt_clr     <= 1'b1;
  state         <= 2'b0;
  en_rocket_rd  <= 1'b0;
end else begin
  case (state)
    2'b00: begin
      cnt_clr <= 1'b0;
	  cnt_start <= 1'b1;
        state     <= 3'b01;
      end

    2'b01: begin
       if (collect_done)
       begin
          cnt_start <= 1'b0;
          state       <= 2'b10;
          end
       end

    2'b10: begin
        en_rocket_rd <= 1'b1;
        if(rdout_done)
           state <= 2'b11;
        end

    2'b11: begin
      en_rocket_rd <= 1'b0;
      cnt_clr  <= 1'b1;
      state <= 2'b00;
    end
  endcase
end


endmodule