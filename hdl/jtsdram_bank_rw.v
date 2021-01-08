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
    Date: 8-1-2021 */

module jtsdram_bank_rw(
    input             rst,
    input             clk,
    input             LVBL,
    output reg [21:0] cnt_addr,
    output     [21:0] sdram_addr,
    input      [21:0] coded_addr,
    output            rd,
    output            wr,
    input             we,

    input             ack,
    input             rdy,
    input      [15:0] data_ref,
    input             start,
    input             slow,
    input      [31:0] data_read,
    output reg        bad,
    output reg        done
);

reg         cs, dly_cs, clr, ok_wait, rqsel, wrtng;
reg  [ 3:0] slow_cnt;
wire [15:0] lfsr, dout;
wire        slow_done, dout_ok;
wire        req, req_rnw;

assign rd = req &  req_rnw;
assign wr = req & ~req_rnw;

assign slow_done = &slow_cnt;

jtsdram_rnd u_rnd(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .adv    ( 1'b1      ),
    .lfsr   ( lfsr      )
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cnt_addr <= 22'd0;
        bad      <= 0;
        done     <= 0;
        dly_cs   <= 0;
        cs       <= 0;
        slow_cnt <= 4'd0;
        clr      <= 0;
        ok_wait  <= 0;
        wrtng    <= 0;
    end else begin
        if(!slow_done) slow_cnt<=slow_cnt+1'd1;
        ok_wait <= 0;
        if(start) begin
            cnt_addr <= 22'd0;
            cs      <= 1;
            done    <= 0;
            clr     <= 1;
            ok_wait <= 1;
            wrtng   <= 0;
            dly_cs  <= 0;
        end else if(!done) begin
            if( rd ) clr <= 0;
            if( dly_cs && ( !slow || slow_done) ) begin
                dly_cs  <= 0;
                cs      <= 1;
                ok_wait <= 1;
                wrtng   <= we && lfsr[0];
            end
            else if( dout_ok && !ok_wait && !rqsel ) begin
                cs   <= 0;
                if( &cnt_addr ) begin
                    done <= 1;
                    `ifdef SIMULATION
                    $display("R/W bank verification done");
                    `endif
                end else begin
                    dly_cs   <= 1;
                    slow_cnt <= lfsr[3:0];
                    cnt_addr <= cnt_addr + 1'd1;
                    ok_wait  <= 1;
                end
                if( dout !== data_ref ) bad <= 1;
            end
        end
    end
end

always @(posedge clk, posedge rst ) begin
    if( rst )
        rqsel <= 0;
    else begin
        if( ack )
            rqsel <= 1;
        else if( rdy )
            rqsel <= 0;
    end
end

jtframe_ram_rq #(.AW(22), .DW(16) ) u_ramrq(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .addr       ( coded_addr    ),
    .offset     ( 22'd0         ),
    .addr_ok    ( cs            ),
    .din        ( data_read     ),
    .din_ok     ( rdy           ),
    .wrin       ( wrtng         ),
    .we         ( rqsel         ),
    .req        ( req           ),
    .req_rnw    ( req_rnw       ),
    .data_ok    ( dout_ok       ),    // strobe that signals that data is ready
    .sdram_addr ( sdram_addr    ),
    .wrdata     (               ),
    .dout       ( dout          )
);

endmodule