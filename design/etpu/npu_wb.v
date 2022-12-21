/*
 * dffram_wb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2022  Camilo Soto
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

module npu_wb #(
    parameter   [31:0]  W_ADDRESS    = 24'h3000_00,        // base address
    parameter   [31:0]  S_ADDRESS    = 24'h3000_01,        // base address
    parameter   [31:0]  R_ADDRESS    = 24'h3000_02,        // base address
    parameter DWIDTH = 24,
    parameter AWIDTH = 7
  )(
    // CaravelBus peripheral ports
    input wire          wb_clk_i,       // clock, runs at system clock
    input wire          wb_rst_i,       // main system reset
    input wire          wb_stb_i,       // write strobe
    input wire          wb_cyc_i,       // cycle
    input wire          wb_we_i,        // write enable
    input wire  [3:0]   wb_sel_i,       // write word select
    input wire  [31:0]  wb_dat_i,       // data in
    input wire  [31:0]  wb_adr_i,       // address
    output reg          wb_ack_o,       // ack
    output reg  [31:0]  wb_dat_o,       // data out
    // debug
    output reg [15:0] out1,
    output reg[3:0] load_end,
    output reg en

  );

  wire clk = wb_clk_i;
  wire rst = wb_rst_i;
  // memories weights, input stream, out data
  reg [DWIDTH-1:0] w [0:(2**AWIDTH)-1];
  reg [DWIDTH-1:0] IN [0:(2**AWIDTH)-1];
  reg [DWIDTH-1:0] out_m [0:(2**AWIDTH)-1];
  reg [7:0] in1,in2,in3;
  reg [7:0] in1_,in2_,in3_;

  reg [23:0] debug = 24'b0;
  reg [7:0] debug_a = 8'b0;
  reg[3:0] count = 4'd0;
  always @(posedge clk)
  begin
    if(rst)
    begin
      load_end <= 0;
    end
    if(wb_stb_i && wb_cyc_i && wb_we_i)
    begin
      if(wb_adr_i[31:8] == W_ADDRESS)
        w[wb_adr_i[7:0]] <= wb_dat_i;
      else if(wb_adr_i[31:8] == S_ADDRESS)
      begin
        load_end<= wb_dat_i[28:24];
        IN[count] <= wb_dat_i[23:0];
        count <= count + 1;
        if (load_end==4)
          count<=0;
      end
    end
    else if(wb_stb_i && wb_cyc_i && !wb_we_i && wb_adr_i[31:8] == R_ADDRESS)
    begin
      debug_a <= wb_adr_i[7:0];
      wb_dat_o <= out_m[wb_adr_i[7:0]];
    end
  end

  // CaravelBus acks
  always @(posedge clk)
  begin
    if(rst)
    begin
      wb_ack_o <= 0;
    end
    else
      wb_ack_o <= (wb_stb_i && (wb_adr_i[31:8] == W_ADDRESS || wb_adr_i[31:8] == R_ADDRESS || wb_adr_i[31:8] == S_ADDRESS));
  end
  // gather new data in memory as input to the array
  reg [3:0] mem_addr;
  always @(posedge clk)
  begin
    if (rst)
    begin
      en<=0;
      mem_addr <= 0;
    end
    else if (load_end==3 && mem_addr < 12)
    begin
      //wishbone value stays longer
      mem_addr <= mem_addr + 2;
      in1 <= IN[mem_addr][7:0];
      in2 <= IN[mem_addr][15:8];
      in3 <= IN[mem_addr][23:16];
      en<=1;
    end
    else if (load_end==4)
    begin
      mem_addr<=0;
      en<=0;
    end
  end

  reg [15:0] zero = 15'b0;
  reg [32:0] memout_addr = 32'd0;
  wire [7:0] r_11, r_12, r_13 ;
  wire [15:0] d_11, d_12, d_13 ;

  // 1
  pe pe_11(.clk(clk), .rst(rst), .en(en), .up(zero), .left(in1), .w(w[0*4][7:0]), .right(r_11), .down(d_11));
  pe pe_12(.clk(clk), .rst(rst), .en(en), .up(zero), .left(r_11), .w(w[1*4][7:0]), .right(r_12), .down(d_12));
  pe pe_13(.clk(clk), .rst(rst), .en(en), .up(zero), .left(r_12), .w(w[2*4][7:0]), .right(r_13), .down(d_13));

  //  2
  wire [7:0] r_21, r_22, r_23 ;
  wire [15:0] d_21, d_22, d_23 ;
  pe pe_21(.clk(clk), .rst(rst), .en(en), .up(d_11), .left(in2), .w(w[3*4][7:0]), .right(r_21), .down(d_21));
  pe pe_22(.clk(clk), .rst(rst), .en(en), .up(d_12), .left(r_21), .w(w[4*4][7:0]), .right(r_22), .down(d_22));
  pe pe_23(.clk(clk), .rst(rst), .en(en), .up(d_13), .left(r_22), .w(w[5*4][7:0]), .right(r_23), .down(d_23));
  //  3
  wire [7:0] r_31, r_32, r_33 ;
  wire [15:0] o_1, o_2, o_3 ;
  pe pe_31(.clk(clk), .rst(rst), .en(en), .up(d_21), .left(in3), .w(w[6*4][7:0]), .right(r_31), .down(o_1));
  pe pe_32(.clk(clk), .rst(rst), .en(en), .up(d_22), .left(r_31), .w(w[7*4][7:0]), .right(r_32), .down(o_2));
  pe pe_33(.clk(clk), .rst(rst), .en(en), .up(d_23), .left(r_32), .w(w[8*4][7:0]), .right(r_33), .down(o_3));
  // prepare the output of the systolic array
  always @(posedge clk)
  begin
    if (en)
    begin
      memout_addr<= memout_addr + 3;
      out_m[(memout_addr * 4)] <= o_1;
      out_m[(memout_addr + 1) * 4] <= o_2;
      out_m[(memout_addr + 2) * 4] <= o_3;
      out1<=o_1;
    end
    else if (load_end==4)
      memout_addr<=0;
  end

endmodule






