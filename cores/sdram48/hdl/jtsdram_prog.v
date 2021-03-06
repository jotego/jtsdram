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

module jtsdram_prog(
    input             rst,
    input             clk,

    input             start,
    input             LVBL,
    output reg        done,
    output reg        dwnld_busy,
    input      [15:0] ba0_data,
    input      [15:0] ba1_data,
    input      [15:0] ba2_data,
    input      [15:0] ba3_data,
    output reg [21:0] prog_addr,
    output     [21:0] next_addr,
    output reg [15:0] prog_data,
    output     [ 1:0] prog_mask,
    output reg [ 1:0] prog_ba,
    output reg        prog_we,
    output            prog_rd,
    input             prog_ack,
    input             prog_rdy,
    output            rfsh
);

reg  [24:0] full_addr;
reg         half, wait_rdy, last_LVBL, rfsh_frame;

wire        addr_done;

assign prog_mask = { half, ~half } | {2{done}};
assign prog_rd = 0;
assign rfsh = rfsh_frame & ~LVBL;
assign next_addr = full_addr[22:1];

`ifdef ONEBANK
assign addr_done = &full_addr[22:0];
`else
assign addr_done = &full_addr;
`endif

always @(posedge clk or posedge rst) begin
    if(rst) begin
        done       <= 0;
        dwnld_busy <= 0;
        full_addr  <= 25'd0;
        prog_we    <= 1'd0;
        prog_data  <= 16'd0;
        half       <= 0;
        prog_addr  <= 22'd0;
        prog_ba    <= 2'd0;
        wait_rdy   <= 0;
        rfsh_frame <= 0;
    end else begin
        if( start ) begin
            dwnld_busy <= 1;
            done       <= 0;
            full_addr  <= 25'd0;
            wait_rdy   <= 0;
        end else begin
            last_LVBL <= LVBL;
            if( LVBL && !last_LVBL ) rfsh_frame <= ~rfsh_frame;
            if( !done && !wait_rdy ) begin
                case( full_addr[24:23] )
                    2'd0: prog_data <= ba0_data;
                    2'd1: prog_data <= ba1_data;
                    2'd2: prog_data <= ba2_data;
                    2'd3: prog_data <= ba3_data;
                endcase // prog_ba
                { prog_ba, prog_addr, half } <= full_addr;
                prog_we   <= 1;
                wait_rdy  <= 1;
                dwnld_busy <= 1;
            end
            if( prog_ack ) begin
                prog_we  <= 0;
            end else
            if( prog_rdy ) begin
                wait_rdy  <= 0;
                full_addr <= full_addr + 1'd1;
                if( addr_done ) begin
                    done       <= 1;
                    dwnld_busy <= 0;
                end
            end
        end
    end
end

endmodule
