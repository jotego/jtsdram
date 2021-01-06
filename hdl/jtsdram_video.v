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

module jtsdram_video(
    input            clk,
    input            LVBL,
    input            LHBL,
    input      [8:0] vdump,
    input            dwnld_busy,
    input            ba0_bad,
    input            ba1_bad,
    input            ba2_bad,
    input            ba3_bad,
    output reg [3:0] red,
    output reg [3:0] green,
    output     [3:0] blue
);

reg bad;

assign blue = 4'd0;

always @(*) begin
    case( vdump[7:6] )
        2'd0: bad = ba0_bad;
        2'd1: bad = ba1_bad;
        2'd2: bad = ba2_bad;
        2'd3: bad = ba3_bad;
    endcase
end

always @(posedge clk) begin
    if( !LHBL || !LVBL ) begin
        green <= 4'd0;
        red   <= 4'd0;
    end else begin
        green <= {4{~bad}} >> dwnld_busy;
        red   <= {4{bad}} >> dwnld_busy;
    end
end

endmodule