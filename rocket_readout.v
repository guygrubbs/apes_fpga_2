/******************************************************************
*
* Module:       rocket_readout
* Description:  rocket_readout 
*
* Organization: NASA-GSFC
* Author:       Salman Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   Controls the FE board for the APES instrument. 
*   
*
* FPGA: A3P1000L-FG256I
******************************************************/

`timescale 1 ns / 100 ps 

module rocket_readout (
     clk50, rst_n, collect_done, Counts, Hk_words,
     Cnt_Gtclk, Cnt_Invload, Cnt_Data, 
     Hk_Gtclk, Hk_Invload, Hk_Data,
     cnt_start, cnt_clr);

input         clk50;           
input         rst_n;               
input         collect_done;
input  [9:0]  Counts[52:0];
input  [9:0]  Hk_words[9:0];


// Rocket interface signals
input         Cnt_Gtclk;       
input         Cnt_Invload;     
output        Cnt_Data;    
input         Hk_Gtclk;        
input         Hk_Invload;     
output        Hk_Data;      

output        cnt_start;
output        cnt_clr;

wire   [9:0]  dbus_in_cnt;
wire   [9:0]  dbus_out_cnt;
wire   [9:0]  dbus_in_hk;

wire   increment_cnt, increment_hk;

sync sync_gclk1 (
  .clk            (clk50),         
  .rst_n          (rst_n),       
  .async_in       (Cnt_Gtclk),      
  .sync_out       (Cnt_Gtclk_sync)       
);

syncn syncn_loadn1 (
  .clk            (clk50),      
  .rst_n          (rst_n),    
  .async_in       (Cnt_Invload), 
  .sync_out       (Cnt_Invload_sync)       
);

sync sync_gclk2 (
  .clk            (clk50),  
  .rst_n          (rst_n), 
  .async_in       (Hk_Gtclk), 
  .sync_out       (Hk_Gtclk_sync)       
);

syncn syncn_loadn2 (
  .clk            (clk50),  
  .rst_n          (rst_n), 
  .async_in       (Hk_Invload), 
  .sync_out       (Hk_Invload_sync)       
);

hk_readout hk_readout( 
  .clk50          (clk50), 
  .rst_n          (rst_n), 
  .words_in       (Hk_words), 
  .hk_in          (dbus_in_hk), 
  .increment      (increment_hk)
);

parallel_shifter #(     // Increments readout module and transmits out data 
  .n            (9))    // Serial based on Gtclk and Invload
  HK_shifter (
  .clk50         (clk50),  
  .rst_n         (rst_n),
  .enable        (1'b1),  // allowing the rocket to pull off data
  .gclk          (Hk_Gtclk_sync), 
  .loadn         (Hk_Invload_sync), 
  .dbus_in       (dbus_in_hk), 
  .increment     (increment_hk), 
  .serial_out    (Hk_Data)
  );

//HVPS Control Voltage
//0->3.3V produces 0->5.0V at the HVPS input which 0->4kV
//We need to set to 2000V or 1.65V decmal 2047

wire en_rocket_rd;

apes_fsm  fsm(       
  .clk50         (clk50), 
  .rst_n         (rst_n), 
  .collect_done  (collect_done),  
  .en_rocket_rd  (en_rocket_rd),      // enables readout of words_out
  .rdout_done    (rdout_done),    // indicates rocket tx complete  
  .cnt_start     (cnt_start),       
  .cnt_clr       (cnt_clr)       
);

/*input  [9:0] DATA;
output [9:0] Q;
input  WE;
input  RE;
input  WCLOCK;
input  RCLOCK;
output FULL;
output EMPTY;
input  RESET;
output AEMPTY;
output AFULL;*/

wire full, empty, aempty, afull;

fifo u_cnt_fifo(
  .DATA(dbus_in_cnt),
  .Q(dbus_out_cnt),
  .WE(~rdout_done),
  .RE(~en_rocket_rd),
  .WCLOCK(clk50),
  .RCLOCK(Cnt_Gtclk_sync),
  .FULL(full),
  .EMPTY(empty),
  .RESET(rst_n),
  .AEMPTY(aempty),
  .AFULL(afull)
);

cnt_readout u_cnt_readout( // put words on Rocket txbus one at a time
  .clk50         (clk50),
  .rst_n         (rst_n), 
  .clr_rdout     (cnt_clr),
  .increment     (increment_cnt),     
  .words_in      (Counts),   
  .cnt_in        (dbus_in_cnt),
  .rdout_done    (rdout_done)
);


parallel_shifter #(// Increments readout and Tx Cntdata 
  .n            (9)) 
  shifter (
  .clk50         (clk50),
  .rst_n         (rst_n),
  .enable        (en_rocket_rd),  // allows rocket to pull data
  .gclk          (Cnt_Gtclk_sync), 
  .loadn         (Cnt_Invload_sync), 
  .dbus_in       (dbus_out_cnt), 
  .increment     (increment_cnt), 
  .serial_out    (Cnt_Data)
  );


/*wire full, afull, aempty, empty;

fifo u_cnt_fifo
(.DATA(Counts[0]),
 .Q(Count_Out),
 .WE(Sync),
 .RE(Sync),
 .WCLOCK(clk50),
 .RCLOCK(clk50),
 .FULL(full),
 .AFULL(afull),
 .EMPTY(empty),
 .AEMPTY(aempty),
 .RESET(1'b0));

fifo u_hk_fifo
(.DATA(Counts[0]),
 .Q(Count_Out),
 .WE(Sync),
 .RE(Sync),
 .WCLOCK(clk50),
 .RCLOCK(clk50),
 .FULL(full),
 .AFULL(afull),
 .EMPTY(empty),
 .AEMPTY(aempty),
 .RESET(1'b0));*/

endmodule
