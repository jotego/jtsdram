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
    output reg      ba0_bad,
    output reg      ba1_bad,
    output reg      ba2_bad,
    output reg      ba3_bad,

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

wire       do_dwn, do_check, sdram_ack, sdram_req,
           data_rdy, data_dst, slot_ok;
wire [1:0] ba_sel;
reg  [3:0] pre_bad;
wire [7:0] rd_data;
reg  [7:0] cmp_data;
reg        check_good, rst=1, phase=0, dwn_l=0,
           compare, LVBLl, odd_frame=0;

assign do_dwn   = downloading & ~phase;
assign do_check = downloading &  phase;
assign ba_sel   = ioctl_addr[23:22];
assign sdram_ack= ba_ack[ba_sel];
assign data_dst = ba_dst[ba_sel];
assign data_rdy = ba_rdy[ba_sel];
assign ba0_wr   = 0;
assign ba0_din  = 0;
assign ba0_din_m= 3;
assign ba1_addr = ba0_addr;
assign ba2_addr = ba0_addr;
assign ba3_addr = ba0_addr;
assign bad      = ba0_bad | ba1_bad | ba2_bad | ba3_bad;
assign dwnld_busy = downloading;
assign refresh_en = ~downloading;
assign game_led = phase;

always @(posedge clk) begin
    rst <= 0;
    dwn_l <= downloading;
    LVBLl <= LVBL;
    if( !LVBL && LVBLl ) odd_frame <= ~odd_frame;
    if( do_dwn ) begin
        compare <= 0;
        pre_bad <= 0;
    end
    if( do_check ) begin
        if( ioctl_wr ) begin
            compare <= 1;
            cmp_data <= ioctl_dout;
        end
        if( slot_ok && compare ) begin
            if( cmp_data != rd_data ) begin
                pre_bad[ba_sel] <= 1;
            end
            compare <= 0;
        end
    end
    if( dwn_l && !downloading ) begin
        phase   <= ~phase;
        ba0_bad <= pre_bad[0];
        ba1_bad <= pre_bad[1];
        ba2_bad <= pre_bad[2];
        ba3_bad <= pre_bad[3];
    end
end

always @* begin
    ba_rd = 0;
    ba_rd[ba_sel] = sdram_req;
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
    .SLOT0_AW    ( 22           )
) u_read(
    .rst         ( do_dwn       ),
    .clk         ( clk          ),

    .slot0_addr  ( ioctl_addr[21:0] ),

    //  output data
    .slot0_dout  ( rd_data      ),

    .slot0_cs    ( do_check     ),
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