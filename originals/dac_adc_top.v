/******************************************************************
*
* Module:       dac_adc_top
* Description:  DAC ADC Top 
*
* Organization: NASA-GSFC
* Author:       Salman Sheikh
* email:        salman.i.sheikh@nasa.gov
*
* Comments:
*   This module interfaces/controls for the DAC & ADC
*   
******************************************************/

`timescale 1 ns / 1 ns 

module dac_adc_top (
     clk50, rst_n, 
     reset_cmd, hven_cmd, safe_cmd,dac_cmd,
     Dac1_sck, Dac1_sdi, Dac1_sync_n, 
     Mcp_dac_clk, Mcp_dac_sdi, Mcp_dac_cs, 
     Adc_sdo, Adc_cs1, Adc_cs2, Adc_clk, Adc_sdi,
     hk_words, hven);

input         clk50;           
input         rst_n;               
input         reset_cmd;
input         hven_cmd;
input         safe_cmd; 
input  [4:0]  dac_cmd;


//  Threshold DACs
output        Dac1_sck;
output        Dac1_sdi;
output        Dac1_sync_n;
// MCP HVPS DAC interface
output        Mcp_dac_clk;        // DAC Clock input            
output        Mcp_dac_sdi;        // DAC Serial Data input      
output        Mcp_dac_cs;        // DAC Chip Select  

// ADC interface
input         Adc_sdo;       // ADC SDO    
output        Adc_cs1;       // ADC CS1    
output        Adc_cs2;       // ADC CS2   
output        Adc_clk;       // ADC Clk   
output        Adc_sdi;       // ADC SDI  

output  [9:0] hk_words[9:0];
output        hven;


reg          hven;
reg   [ 7:0] clock_div;
reg          dac_pulse;
reg          dac_sm;
reg          dac_rst;
reg          sm_regw; 
reg          regw_pls;    
reg   [11:0] dac_set;
reg   [11:0] dac_data;
reg   [23:0] cnt_dac_24b;
wire  [11:0] val_adc[0:31];   // output 8 bit registers 
wire  [ 8:0] lcla;
wire  [31:0] lcld_i;
wire  [ 4:0] count_dac;


assign count_dac = dac_cmd[4:0];

always @(posedge clk50 or negedge rst_n) 
if (!rst_n) begin
  dac_data <= 12'h000;
end 
else begin
  case (count_dac)
     0: dac_data  <= 12'h010;
     1: dac_data  <= 12'h9B1;
     2: dac_data  <= 12'h4D8;
     3: dac_data  <= 12'h26C;
     4: dac_data  <= 12'h12C;
     5: dac_data  <= 12'h0C8;
     6: dac_data  <= 12'h064;
     7: dac_data  <= 12'h032;
     8: dac_data  <= 12'h019;
     9: dac_data  <= 12'h014;
    10: dac_data  <= 12'h013;
    11: dac_data  <= 12'h012;
    12: dac_data  <= 12'h4D8; 
    13: dac_data  <= 12'h010;
    14: dac_data  <= 12'h00F;
    15: dac_data  <= 12'h0FF;
    16: dac_data  <= 12'h00D;
    17: dac_data  <= 12'h00C;
    18: dac_data  <= 12'h00B;
    19: dac_data  <= 12'h00A;
    20: dac_data  <= 12'h009;
    21: dac_data  <= 12'h008;
    22: dac_data  <= 12'h007;
    23: dac_data  <= 12'h006;
    24: dac_data  <= 12'h005;
    25: dac_data  <= 12'h004;
    26: dac_data  <= 12'h003;
    27: dac_data  <= 12'h002;
    28: dac_data  <= 12'h001;
    29: dac_data  <= 12'h000;
    30: dac_data  <= 12'h000;
    31: dac_data  <= 12'h000;
  endcase
end 


apes_dac #(  
  .select           (0))
DAC1 (              // 50mV threshold DAC
  .clk50            (clk50),           
  .rst_n            (rst_n),           
  .dac_rst          (1'b0),              
  .regw_pls         (clk195khz),       
  .Lcla             (9'h008),            
  .Lcld             ({16'h0000,4'b0000, dac_data} ),  
  .Dac_clk          (Dac1_sck),        //  dac clk
  .Dac_dat          (Dac1_sdi),        //  dac data 
  .CTRL_ENn         (Dac1_sync_n),     //  dac sync
  .dac_reg          ( ),               
  .pa_sm_dac_out    ()
  );


apes_dac #(
  .select           (0))
start_mcp (                              // MCP DAC Control
  .clk50            (clk50),             
  .rst_n            (rst_n),             
  .dac_rst          (dac_rst),           // i DAC Reset
  .regw_pls         (dac_pulse),         // i Reg Write Pulse
  .Lcla             (9'h008),            // i Local Address
  .Lcld             ({20'h0, dac_set}),  // i Local Data
  .Dac_clk          (Mcp_dac_clk),       
  .Dac_dat          (Mcp_dac_sdi),       
  .CTRL_ENn         (Mcp_dac_cs),        
  .dac_reg          ( ),                 
  .pa_sm_dac_out    ()
  );


apes_adc hk_apes_adc (         
  .clk             (clk195khz),           
  .rst_n            (rst_n),          
  .regw_pls         (1'b1),          // i Reg Write Pulse
  .Lcla             (9'h1C),         // i Local Address
  .Lcld             (32'h10FFF),     // i Local Data
  .Adc_sclk         (Adc_clk),       
  .Adc_dout         (Adc_sdo),      // o ADC data out
  .Adc_din          (Adc_sdi ),     // i ADC cata In
  .Adc_csn1         (Adc_cs1 ),     // o ADC chip select 
  .Adc_csn2         (Adc_cs2 ),     // o ADC chip select
  .sm_adc           (),
  .adccs_rg         (),             // o reg ADC Control/Status Register
  .val_adc0         (val_adc[0]),   // o reg ADC data
  .val_adc1         (val_adc[1]),   // o reg ADC data
  .val_adc2         (val_adc[2]),   // o reg ADC data
  .val_adc3         (val_adc[3]),   // o reg ADC data
  .val_adc4         (val_adc[4]),   // o reg ADC data
  .val_adc5         (val_adc[5]),   // o reg ADC data
  .val_adc6         (val_adc[6]),   // o reg ADC data
  .val_adc7         (val_adc[7]),   // o reg ADC data
  .adc_int          (),             // o ADC interrupt
  .adc_oshft_out    () );

assign hk_words[0]  = 10'h3BE;
assign hk_words[1]  = 10'h2FB;
assign hk_words[2]  = val_adc[0];
assign hk_words[3]  = val_adc[1];
assign hk_words[4]  = val_adc[2];
assign hk_words[5]  = val_adc[3];
assign hk_words[6]  = val_adc[4];
assign hk_words[7]  = val_adc[5];
assign hk_words[8]  = val_adc[6];
assign hk_words[9]  = val_adc[7];


//HVPS Control Voltage
//0->3.3V produces 0->5.0V at the HVPS input which 0->4kV
//We need to set to 2000V or 1.65V decmal 2047

always @(posedge clk195khz or negedge rst_n)
if (!rst_n) 
  begin
     dac_set     <= 12'b0;
     dac_pulse    <= 1'b0;
     cnt_dac_24b  <= 24'h0;
     dac_sm       <= 1'b0;
     dac_rst      <= 1'b0;
     hven         <= 1'b0;
  end 
else 
begin 
case (dac_sm)

  1'b0: begin
      dac_rst <= 1'b0;
      if (hven_cmd & ~safe_cmd & ~reset_cmd) // hven low enables 
      begin
        dac_pulse <= 1'b0;
        hven <= 1'b1;
        cnt_dac_24b <= cnt_dac_24b + 1;
        
         if (cnt_dac_24b == 24'h000C2) 
         begin
            dac_set <= 12'd228;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h15315)
         begin
            dac_set <= 12'd456;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h2A62A)
         begin
            dac_set <= 12'd684;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h3F93F)
         begin
            dac_set <= 12'd912;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h54C54)
         begin
            dac_set <= 12'd1140;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h69F69)
         begin
            dac_set <= 12'd1368;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'h94593)
         begin
            dac_set <= 12'd1596;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'hAB128)
         begin
            dac_set <= 12'd1840;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'hC2B4D)
         begin
            dac_set <= 12'd2075;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'hBEBC2)
         begin
            dac_set <= 12'd2310;
            dac_pulse <= 1'b1;
         end
         else if ( cnt_dac_24b == 24'hC0000)
         begin
             dac_sm <= 1'b1;
         end
         else 
         begin
            dac_set <= 12'h000;
            dac_pulse <= 1'b0;
         end
       end
     end
  1'b1: begin
    if (reset_cmd) 
    begin
      dac_rst <= 1'b1;
      dac_sm <= 1'b0;
      hven <= 1'b0;
    end
  end
endcase
end   


always @(posedge clk50 or negedge rst_n)  
if (!rst_n) 
  clock_div <= 8'h00;
else 
  clock_div <= clock_div + 1;

CLKINT  clkb  (.A(clock_div[7]),  .Y(clk195khz));  


endmodule