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

module jtsdram_snd(
    input         clk,
    input         LHBL,
    input         dwnld_busy,
    input         bad,
    output [15:0] snd
);

reg [4:0] pre;
reg       last_LHBL;

assign snd = { {3{pre}}, pre[0] };

always @(posedge clk) begin
    last_LHBL <= LHBL;
    if( dwnld_busy )
        pre <= pre>>1;
    else if( LHBL && !last_LHBL ) begin
        if( !bad )
            pre <= pre + 5'd1;
        else
            pre <= pre + 5'd3;  // goes to a higher pitch when fails
    end
end


endmodule