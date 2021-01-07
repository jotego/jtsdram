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

module jtsdram_bank_ro(
    input             rst,
    input             clk,
    input             LVBL,
    output     [21:0] addr,
    output            rd,

    input             ack,
    input             rdy,
    input      [15:0] data_ref,
    input             start,
    input             slow,
    input      [31:0] data_read,
    output reg        bad,
    output reg        done
);

reg [21:0]  cnt_addr;
reg         cs, dly_cs, clr, ok_wait;
reg  [ 3:0] slow_cnt;
wire [15:0] lfsr, dout;
wire        slow_done, dout_ok;

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
    end else begin
        if(!slow_done) slow_cnt<=slow_cnt+1'd1;
        ok_wait <= 0;
        if(start) begin
            cnt_addr <= 22'd0;
            cs      <= 1;
            done    <= 0;
            clr     <= 0;
            ok_wait <= 1;
            // bad  <= 0;
        end else if(!done) begin
            if( dly_cs && ( !slow ? LVBL : slow_done) ) begin
                dly_cs  <= 0;
                cs      <= 1;
                ok_wait <= 1;
            end
            else if( dout_ok && !ok_wait ) begin
                if( &cnt_addr ) begin
                    done <= 1;
                    clr  <= 1;
                end else begin
                    if( LVBL && !slow ) begin
                        cs      <= 1;
                        ok_wait <= 1;
                        dly_cs  <= 0;
                    end else begin
                        cs <= 0;
                        dly_cs <= 1;
                        slow_cnt <= lfsr[3:0];
                    end
                end
                cnt_addr <= cnt_addr + 1'd1;
                if( dout != data_ref ) bad <= 1;
            end
        end
    end
end

reg we;

always @(posedge clk, posedge rst ) begin
    if( rst )
        we <= 0;
    else begin
        if( ack )
            we <= 1;
        else if( rdy )
            we <= 0;
    end
end

jtframe_romrq #(
    .AW(22),
    .DW(16),
    .REPACK(0)  // do not let data from SDRAM pass thru without repacking (latching) it
                // 0 = data is let pass thru
                // 1 = data gets repacked (adds one clock of latency)
) u_romrq(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .clr        ( clr           ), // clears the cache
    .offset     ( 22'd0         ),
    .addr       ( cnt_addr      ),
    .addr_ok    ( cs            ),
    .din        ( data_read     ),
    .din_ok     ( rdy           ),
    .we         ( we            ),
    .req        ( rd            ),
    .data_ok    ( dout_ok       ),    // strobe that signals that data is ready
    .sdram_addr ( addr          ),
    .dout       ( dout          )
);

endmodule