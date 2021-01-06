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

module jtsdram_seq(
    input            rst,
    input            clk,

    output     [4:0] ba0_key,
    output     [4:0] ba1_key,
    output     [4:0] ba2_key,
    output     [4:0] ba3_key,

    output reg [15:0] data_ref,

    output reg       prog_start,
    input            prog_done,

    output reg       rd_start,
    input            ba0_done,
    input            ba1_done,
    input            ba2_done,
    input            ba3_done
);

reg        prog_wait, rd_wait;

reg [15:0] lfsr;
// D295
// 1101 0010 1001 0101
wire       lfsr_fb = ^{ lfsr[15:14], lfsr[12], lfsr[9], lfsr[7], lfsr[4], lfsr[2], lfsr[0] };

assign ba0_key = lfsr[ 4: 0];
assign ba1_key = lfsr[ 9: 5];
assign ba2_key = lfsr[14:10];
assign ba3_key = { lfsr[15], lfsr[4], lfsr[9], lfsr[0], lfsr[11] };

always @(posedge clk or posedge rst) begin
    if(rst) begin
        prog_start <= 0;
        rd_start   <= 0;
        prog_wait  <= 0;
        rd_wait    <= 0;
        lfsr       <= 16'haaaa;
        data_ref   <= 16'haaaa;
    end else begin
        case( {prog_wait, rd_wait} )
            2'b00: begin
                prog_start <= 1;
                prog_wait  <= 1;
            end
            2'b10: begin
                prog_start <= 0;
                if( prog_done ) begin
                    prog_wait <= 0;
                    rd_start  <= 1;
                    rd_wait   <= 1;
                end
            end
            2'b01: begin
                rd_start <= 0;
                if( !rd_start && ba0_done && ba1_done && ba2_done && ba3_done ) begin
                    rd_wait <= 0;
                    // advance lfsr
                    lfsr <= { lfsr_fb, lfsr[15:1] };
                    data_ref <= data_ref+1'b1;
                end
            end
            default: begin
                prog_wait  <= 0;
                prog_start <= 0;
                rd_wait    <= 0;
                rd_start   <= 0;
            end
        endcase
    end
end

endmodule