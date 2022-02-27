/*  This file is part of JTSDRAM.
    JTSDRAM program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTSDRAM program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTSDRAM.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-2-2022 */

module jtldtest_sdram(
    input           clk,
    input           LVBL,
    output          game_led,

    input           downloading,
    output          dwnld_busy,
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,

    output          bad,
    output          ba0_bad,
    output          ba1_bad,
    output          ba2_bad,
    output          ba3_bad,

    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_rdy,
    input           prog_ack,

    output reg [3:0] ba_rd,
    input    [ 3:0] ba_rdy,
    input    [ 3:0] ba_ack,
    input    [ 3:0] ba_dst,
    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output          ba0_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    output   [21:0] ba1_addr,
    output   [21:0] ba2_addr,
    output   [21:0] ba3_addr,

    input   [15:0]  data_read,
    output          refresh_en
//    input   [ 7:0]  st_addr,
//    output  [ 7:0]  st_dout
);

wire       do_dwn, sdram_ack, sdram_req,
           data_rdy, data_dst, slot_ok;
wire [1:0] ba_sel;
reg  [3:0] pre_bad=0;
wire [7:0] saved;
reg  [7:0] cmp_data;
reg [24:0] ioctl_addr_l;
reg  [1:0] slot_good;
reg        check_good, phase=0, dwn_l=0,
           compare, LVBLl, odd_frame=0, wrl;
wire       addr_chg;

assign ba0_bad = pre_bad[0];
assign ba1_bad = pre_bad[1];
assign ba2_bad = pre_bad[2];
assign ba3_bad = pre_bad[3];

assign do_dwn   = downloading & ~phase;
assign ba_sel   = ioctl_addr[24:23];
assign sdram_ack= |ba_ack;
assign data_dst = |ba_dst;
assign data_rdy = |ba_rdy;
assign ba0_wr   = 0;
assign ba0_din  = 0;
assign ba0_din_m= 3;
assign ba1_addr = ba0_addr;
assign ba2_addr = ba0_addr;
assign ba3_addr = ba0_addr;
assign bad      = ba0_bad | ba1_bad | ba2_bad | ba3_bad;
assign dwnld_busy = do_dwn;
assign refresh_en = ~downloading;
assign game_led = phase;
assign addr_chg = ioctl_addr != ioctl_addr_l;

always @(posedge clk) begin
    dwn_l <= downloading;
    wrl <= ioctl_wr;
    LVBLl <= LVBL;
    if( !LVBL && LVBLl ) odd_frame <= ~odd_frame;
    slot_good <= (!downloading || addr_chg || !slot_ok) ? 2'b0 : { slot_good[0], slot_ok };
    if( downloading && ioctl_wr && !wrl && phase ) begin
        cmp_data <= ioctl_dout;
        ioctl_addr_l <= ioctl_addr;
        if( ioctl_addr!=0 && cmp_data != saved && slot_ok )
            pre_bad[ba_sel] <= 1;
    end
    if( !phase && ioctl_wr ) begin
        pre_bad <= 0;
    end
    if( dwn_l && !downloading ) begin
        phase   <= ~phase;
    end
end

always @* begin
    ba_rd = 0;
    ba_rd[ ioctl_addr_l[24:23] ] = sdram_req;
end

jtframe_dwnld #(
    .BA1_START   ( 25'h080_0000 ),
    .BA2_START   ( 25'h100_0000 ),
    .BA3_START   ( 25'h180_0000 ),
    .SWAB        ( 1            )
) u_dwnld(
    .clk         ( clk          ),
    .downloading ( do_dwn       ),
    .ioctl_addr  ( ioctl_addr   ),
    .ioctl_dout  ( ioctl_dout   ),
    .ioctl_wr    ( ioctl_wr     ),
    .prog_addr   ( prog_addr    ),
    .prog_data   ( prog_data    ),
    .prog_mask   ( prog_mask    ), // active low
    .prog_we     ( prog_we      ),
    .prog_rd     ( prog_rd      ),
    .prog_ba     ( prog_ba      ),
    .prom_we     (              ),
    .header      (              ),
    .sdram_ack   ( prog_ack     )
);

jtframe_rom_1slot #(
    .SLOT0_AW    ( 23           )
) u_read(
    .rst         ( ~phase       ),
    .clk         ( clk          ),

    .slot0_addr  ( ioctl_addr_l[22:0] ),

    //  output data
    .slot0_dout  ( saved        ),

    .slot0_cs    ( 1'b1         ),
    .slot0_ok    ( slot_ok      ),
    // SDRAM controller interface
    .sdram_ack   ( sdram_ack    ),
    .sdram_req   ( sdram_req    ),
    .sdram_addr  ( ba0_addr     ),
    .data_dst    ( data_dst     ),
    .data_rdy    ( data_rdy     ),
    .data_read   ( data_read    )
);

endmodule