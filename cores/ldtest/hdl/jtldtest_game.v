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

module jtsdram_game(
    input           rst,
    input           clk,      // 48   MHz
    // Video
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
    output          HS,
    output          VS,
    // LED
    output          game_led,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 5:0]  joystick1,
    input   [ 5:0]  joystick2,
    // SDRAM interface
    input           downloading,
    output          dwnld_busy,

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output          ba_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    input           ba0_rdy,
    input    [ 3:0] ba_ack,
    input    [ 3:0] ba_rdy,
    input    [ 3:0] ba_dst,
    input    [ 3:0] ba_dok,
    output   [ 3:0] ba_rd,
    output   [21:0] ba1_addr,
    output   [21:0] ba2_addr,
    output   [21:0] ba3_addr,
    input    [15:0] data_read,
    output          refresh_en,

    // RAM/ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_ack,
    input           prog_dok,
    input           prog_dst,
    input           prog_rdy,
    // DIP switches
    input   [31:0]  status,     // only bits 31:16 are looked at
    input           service,
    input           dip_pause,
    inout           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd,
    output          sample,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input    [ 3:0] gfx_en
);

wire LHBL, LVBL, bad;
wire [8:0] vdump;
wire       ba0_bad, ba1_bad, ba2_bad, ba3_bad;

assign LHBL_dly = LHBL, LVBL_dly=LVBL;
assign sample = LHBL;

wire [3:0] pre_r, pre_g, pre_b;

assign red   = pre_r >> dwnld_busy;
assign green = pre_g >> dwnld_busy;
assign blue  = pre_b >> dwnld_busy;

jtsdram_video u_video(
    .clk        ( clk           ),
    .LVBL       ( LVBL          ),
    .LHBL       ( LHBL          ),
    .pxl_cen    ( pxl_cen       ),
    .vdump      ( vdump         ),
    .dwnld_busy ( !game_led     ),
    .ba0_bad    ( ba0_bad       ),
    .ba1_bad    ( ba1_bad       ),
    .ba2_bad    ( ba2_bad       ),
    .ba3_bad    ( ba3_bad       ),
    .red        ( pre_r         ),
    .green      ( pre_g         ),
    .blue       ( pre_b         )
);

jtsdram_snd u_snd(
    .clk        ( clk           ),
    .LHBL       ( LHBL          ), // 15kHz base tone
    .dwnld_busy ( dwnld_busy    ),
    .bad        ( bad           ),
    .snd        ( snd           )
);

`ifdef JTFRAME_SDRAM96
    jtframe_cen96 u_cen96(
        .clk        ( clk           ),
        .cen16      (               ),
        .cen12      ( pxl2_cen      ),
        .cen8       (               ),
        .cen6       ( pxl_cen       ),
        // 180 shifted signals
        .cen6b      (               )
    );
`else
    jtframe_cen48 u_cen48(
        .clk        ( clk           ),
        .cen16      (               ),
        .cen12      ( pxl2_cen      ),
        .cen8       (               ),
        .cen6       ( pxl_cen       ),
        .cen4       (               ),
        .cen4_12    (               ),
        .cen3       (               ),
        .cen3q      (               ),
        .cen1p5     (               ),
        // 180 shifted signals
        .cen16b     (               ),
        .cen12b     (               ),
        .cen6b      (               ),
        .cen3b      (               ),
        .cen3qb     (               ),
        .cen1p5b    (               )
    );
`endif


// Same parameters as Bubble Bobble core
jtframe_vtimer #(
    .HB_START( 9'd255 ),
    .HS_START( 9'd287 ),
    .HB_END  ( 9'd383 ),
    .V_START ( 9'd016 ),
    .VS_START( 9'd254 ),
    .VB_START( 9'd240 ),
    .VB_END  ( 9'd279 )
)
u_timer(
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),
    .vdump      ( vdump         ),
    .vrender    (               ),
    .vrender1   (               ),
    .H          (               ),
    .Hinit      (               ),
    .Vinit      (               ),
    .LHBL       ( LHBL          ),
    .LVBL       ( LVBL          ),
    .HS         ( HS            ),
    .VS         ( VS            )
);

jtldtest_sdram u_checker(
    .clk         ( clk           ),
    .LVBL        ( LVBL          ),

    .downloading ( downloading   ),
    .dwnld_busy  ( dwnld_busy    ),
    .ioctl_addr  ( ioctl_addr    ),
    .ioctl_dout  ( ioctl_dout    ),
    .ioctl_wr    ( ioctl_wr      ),
    .game_led    ( game_led      ),

    .bad         ( bad           ),
    .ba0_bad     ( ba0_bad       ),
    .ba1_bad     ( ba1_bad       ),
    .ba2_bad     ( ba2_bad       ),
    .ba3_bad     ( ba3_bad       ),

    .prog_addr   ( prog_addr     ),
    .prog_data   ( prog_data     ),
    .prog_mask   ( prog_mask     ),
    .prog_ba     ( prog_ba       ),
    .prog_we     ( prog_we       ),
    .prog_rd     ( prog_rd       ),
    .prog_rdy    ( prog_rdy      ),
    .prog_ack    ( prog_ack      ),

    .ba_ack      ( ba_ack        ),
    .ba_rd       ( ba_rd         ),
    .ba_rdy      ( ba_rdy        ),
    .ba_dst      ( ba_dst        ),
    // Bank 0: allows R/W
    .ba0_wr      ( ba_wr         ),
    .ba0_din     ( ba0_din       ),
    .ba0_din_m   ( ba0_din_m     ),

    .ba0_addr    ( ba0_addr      ),
    .ba1_addr    ( ba1_addr      ),
    .ba2_addr    ( ba2_addr      ),
    .ba3_addr    ( ba3_addr      ),

    .data_read   ( data_read     ),
    .refresh_en  ( refresh_en    )
);

endmodule
