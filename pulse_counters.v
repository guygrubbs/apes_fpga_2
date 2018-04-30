/******************************************************************************
*
* Module:       pulse_counters
* Description:   
*
* Organization: NASA - GSFC
* Author:       Salman Sheikh
* email:        salman.i.sheikh@nasa.gov
*
*
* Revisions:  - Base, 09/28/17, S. Sheikh, Code 564
******************************************************************************/

`timescale 1 ns / 100 ps

module pulse_counters (
        clk50, rst_n, 
        Inpulse, stim_cmd, cnt_start, cnt_clr, 
        cnt_done, Counts);

input         clk50;           
input         rst_n;              

// 50 Input pulses
input  [49:0] Inpulse;

input         stim_cmd;
input         cnt_start;
input         cnt_clr;
output        cnt_done;
output [9:0]  Counts[52:0];

 wire [49:0] clear_count;
 wire [49:0] start_count;
// wire clear_cnt;
 wire [49:0] inpulse;
 wire [49:0] stim_tp;
 wire stim_testpulse;


genvar i;
generate
for (i=0; i < 50; i=i+1) 
begin : asic_data_sync1
  assign clear_count[i] = cnt_clr;
  assign start_count[i] = cnt_start;
  assign stim_tp[i] = stim_testpulse;

  sync input_pulse_sync (
    .clk            (clk50),           
    .rst_n          (rst_n),
    .async_in       (Inpulse[i] | stim_tp[i]),      
    .sync_out       (inpulse[i])
  );

  apes_counter counter (
    .clk            (clk50), 
    .rst_n          (rst_n), 
    .enable         (start_count[i]),
    .clr            (clear_count[i]), 
    .d              (inpulse[i]), 
    .q              (Counts[i+2])
  );
end
endgenerate


synch_timer  sync_timer( 
  .clk50               (clk50), 
  .rst_n               (rst_n), 
  .enable              (cnt_start),
  .clr                 (cnt_clr),
  .collect_enable      (cnt_done)
  );

assign Counts[0]  = 10'h3BE;
assign Counts[1]  = 10'h2FB;
assign Counts[52] = 10'h2BF;

testpulse test_pulser( 
  .clk50               (clk50), 
  .rst_n               (rst_n), 
  .stim_en             (stim_cmd),
  .stim_out            (stim_testpulse) 
);

endmodule
