`default_nettype none
`timescale 1ns/1ns


module edu_tpu #(

    parameter   [31:0]  W_ADDRESS    = 24'h3000_00        // base address
  )(
    // CaravelBus peripheral ports
    input wire          caravel_wb_clk_i,       // clock, runs at system clock
    input wire          caravel_wb_rst_i,       // main system reset
    input wire          caravel_wb_stb_i,       // write strobe
    input wire          caravel_wb_cyc_i,       // cycle
    input wire          caravel_wb_we_i,        // write enable
    input wire  [3:0]   caravel_wb_sel_i,       // write word select
    input wire  [31:0]  caravel_wb_dat_i,       // data in
    input wire  [31:0]  caravel_wb_adr_i,       // address
    output           caravel_wb_ack_o,       // ack
    output   [31:0]  caravel_wb_dat_o,      // data out
    output wire [15:0] out1,
    output wire [3:0] load_end,
    output wire en
  );

  // rename some signals

  wire clk_npu;
  wire clk, rst, valid;
  reg				ready;
  assign clk 	= caravel_wb_clk_i;
  assign rst	= caravel_wb_rst_i;

  assign valid 	= caravel_wb_cyc_i & caravel_wb_stb_i;


  always@(posedge clk)
    if(rst | ready)
      ready <= 0;
    else if(valid & ~ready)
      ready <= 1;


  npu_wb ram_wb(
           .wb_clk_i(caravel_wb_clk_i),
           .wb_rst_i(caravel_wb_rst_i),
           .wb_stb_i(caravel_wb_stb_i),
           .wb_cyc_i(caravel_wb_cyc_i),
           .wb_we_i (caravel_wb_we_i ),
           .wb_sel_i(caravel_wb_sel_i),
           .wb_dat_i(caravel_wb_dat_i),
           .wb_adr_i(caravel_wb_adr_i),
           .wb_ack_o(caravel_wb_ack_o),
           .wb_dat_o(caravel_wb_dat_o),
           .out1(out1),
           .load_end(load_end),
           .en(en)
         );


endmodule
