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
    Date: 5-1-2021 */

module jtsdram_checker(
    input           rst,
    input           clk,
    input           LVBL,

    output          dwnld_busy,
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

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output          ba0_rd,
    output          ba0_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    input           ba0_rdy,
    input           ba0_ack,

    // Bank 1: Read only
    output   [21:0] ba1_addr,
    output          ba1_rd,
    input           ba1_rdy,
    input           ba1_ack,

    // Bank 2: Read only
    output   [21:0] ba2_addr,
    output          ba2_rd,
    input           ba2_rdy,
    input           ba2_ack,

    // Bank 3: Read only
    output   [21:0] ba3_addr,
    output          ba3_rd,
    input           ba3_rdy,
    input           ba3_ack,

    input   [31:0]  data_read,
    output          refresh_en
);

wire [21:0] ba0_preaddr, ba1_preaddr, ba2_preaddr, ba3_preaddr, next_addr,
            ba0_coded_addr, ba1_coded_addr, ba2_coded_addr, ba3_coded_addr;
wire [15:0] ba0_data_ref, ba1_data_ref, ba2_data_ref, ba3_data_ref, data_ref;
wire [ 4:0] ba0_key, ba1_key, ba2_key, ba3_key;

wire        prog_start, prog_done, rd_start, prog_rfsh, slow,
            ba0_done, ba1_done, ba2_done, ba3_done,
            ba0_we;

assign refresh_en = dwnld_busy ? prog_rfsh : ~LVBL;
assign bad = ba0_bad | ba1_bad | ba2_bad | ba3_bad;

// Bank 0 writting not used for now
assign ba0_din   = ba0_data_ref;
assign ba0_din_m = 2'b00;

jtsdram_seq u_seq(
    .rst        ( rst           ),
    .clk        ( clk           ),

    .ba0_key    ( ba0_key       ),
    .ba1_key    ( ba1_key       ),
    .ba2_key    ( ba2_key       ),
    .ba3_key    ( ba3_key       ),
    .data_ref   ( data_ref      ),

    .prog_start ( prog_start    ),
    .prog_done  ( prog_done     ),

    .rd_start   ( rd_start      ),
    .slow       ( slow          ),
    .ba0_we     ( ba0_we        ),
    .ba0_done   ( ba0_done      ),
    .ba1_done   ( ba1_done      ),
    .ba2_done   ( ba2_done      ),
    .ba3_done   ( ba3_done      )
);

jtsdram_prog u_prog(
    .rst        ( rst           ),
    .clk        ( clk           ),

    .start      ( prog_start    ),
    .done       ( prog_done     ),
    .dwnld_busy ( dwnld_busy    ),
    .LVBL       ( LVBL          ),
    .rfsh       ( prog_rfsh     ),

    .ba0_data   ( ba0_data_ref  ),
    .ba1_data   ( ba1_data_ref  ),
    .ba2_data   ( ba2_data_ref  ),
    .ba3_data   ( ba3_data_ref  ),

    .next_addr  ( next_addr     ),

    .prog_addr  ( prog_addr     ),
    .prog_data  ( prog_data     ),
    .prog_mask  ( prog_mask     ),
    .prog_ba    ( prog_ba       ),
    .prog_we    ( prog_we       ),
    .prog_rd    ( prog_rd       ),
    .prog_ack   ( prog_ack      ),
    .prog_rdy   ( prog_rdy      )
);

jtsdram_shuffle u_sh0(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .prog_en    ( dwnld_busy    ),
    .prog_addr  ( next_addr     ),
    .key        ( ba0_key       ),
    .addr_in    ( ba0_preaddr   ),
    .addr_out   ( ba0_coded_addr),
    .ref_in     ( data_ref      ),
    .ref_out    ( ba0_data_ref  )
);

jtsdram_bank_rw u_ch0(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LVBL       ( LVBL          ),
    .cnt_addr   ( ba0_preaddr   ),
    .sdram_addr ( ba0_addr      ),
    .coded_addr ( ba0_coded_addr),
    .rd         ( ba0_rd        ),
    .wr         ( ba0_wr        ),
    .we         ( ba0_we        ),
    .ack        ( ba0_ack       ),
    .rdy        ( ba0_rdy       ),
    .data_ref   ( ba0_data_ref  ),
    .start      ( rd_start      ),
    .slow       ( slow          ),
    .data_read  ( data_read     ),
    .bad        ( ba0_bad       ),
    .done       ( ba0_done      )
);

`ifndef ONEBANK
jtsdram_shuffle u_sh1(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .prog_en    ( dwnld_busy    ),
    .prog_addr  ( next_addr     ),
    .key        ( ba1_key       ),
    .addr_in    ( ba1_preaddr   ),
    .addr_out   ( ba1_coded_addr),
    .ref_in     ( data_ref      ),
    .ref_out    ( ba1_data_ref  )
);

jtsdram_shuffle u_sh2(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .prog_en    ( dwnld_busy    ),
    .prog_addr  ( next_addr     ),
    .key        ( ba2_key       ),
    .addr_in    ( ba2_preaddr   ),
    .addr_out   ( ba2_coded_addr),
    .ref_in     ( data_ref      ),
    .ref_out    ( ba2_data_ref  )
);

jtsdram_shuffle u_sh3(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .prog_en    ( dwnld_busy    ),
    .prog_addr  ( next_addr     ),
    .key        ( ba3_key       ),
    .addr_in    ( ba3_preaddr   ),
    .addr_out   ( ba3_coded_addr),
    .ref_in     ( data_ref      ),
    .ref_out    ( ba3_data_ref  )
);

jtsdram_bank_ro u_ch1(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LVBL       ( LVBL          ),
    .cnt_addr   ( ba1_preaddr   ),
    .sdram_addr ( ba1_addr      ),
    .coded_addr ( ba1_coded_addr),
    .rd         ( ba1_rd        ),
    .ack        ( ba1_ack       ),
    .rdy        ( ba1_rdy       ),
    .data_ref   ( ba1_data_ref  ),
    .start      ( rd_start      ),
    .slow       ( slow          ),
    .data_read  ( data_read     ),
    .bad        ( ba1_bad       ),
    .done       ( ba1_done      )
);

jtsdram_bank_ro u_ch2(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LVBL       ( LVBL          ),
    .cnt_addr   ( ba2_preaddr   ),
    .sdram_addr ( ba2_addr      ),
    .coded_addr ( ba2_coded_addr),
    .rd         ( ba2_rd        ),
    .ack        ( ba2_ack       ),
    .rdy        ( ba2_rdy       ),
    .data_ref   ( ba2_data_ref  ),
    .start      ( rd_start      ),
    .slow       ( slow          ),
    .data_read  ( data_read     ),
    .bad        ( ba2_bad       ),
    .done       ( ba2_done      )
);

jtsdram_bank_ro u_ch3(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LVBL       ( LVBL          ),
    .cnt_addr   ( ba3_preaddr   ),
    .sdram_addr ( ba3_addr      ),
    .coded_addr ( ba3_coded_addr),
    .rd         ( ba3_rd        ),
    .ack        ( ba3_ack       ),
    .rdy        ( ba3_rdy       ),
    .data_ref   ( ba3_data_ref  ),
    .start      ( rd_start      ),
    .slow       ( slow          ),
    .data_read  ( data_read     ),
    .bad        ( ba3_bad       ),
    .done       ( ba3_done      )
);

`else
assign ba1_rd = 0;
assign ba1_done = 1;
assign ba2_rd = 0;
assign ba2_done = 1;
assign ba3_rd = 0;
assign ba3_done = 1;
assign ba1_bad = 0;
assign ba2_bad = 0;
assign ba3_bad = 0;
`endif

`ifdef SIMULATION
always @(posedge bad) begin
    $display("SDRAM check failed");
    #100 $finish;
end
`endif

endmodule