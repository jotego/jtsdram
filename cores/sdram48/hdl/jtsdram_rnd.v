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

module jtsdram_rnd(
    input             rst,
    input             clk,
    input             adv,
    output reg [15:0] lfsr
);

parameter [15:0] INITVAL=16'hcafe;

wire       lfsr_fb = ^{ lfsr[15:14], lfsr[12], lfsr[9], lfsr[7], lfsr[4], lfsr[2], lfsr[0] };

always @(posedge clk, posedge rst) begin
    if( rst )
        lfsr <= INITVAL;
    else begin
        if( adv )
            lfsr <= { lfsr_fb, lfsr[15:1] };
    end
end

endmodule