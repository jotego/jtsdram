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
    Date: 7-1-2021 */

module jtsdram_led(
    input       clk,
    input       rst,
    input       LVBL,
    input       bad,
    output reg  led
);

reg [4:0] cnt;
reg       last_LVBL;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        last_LVBL <= 0;
        cnt <= 5'd0;
    end else begin
        last_LVBL <= LVBL;
        if( LVBL && !last_LVBL ) cnt<=cnt+1'd1;
        led <= bad ? cnt[4] : cnt[0];
    end
end

endmodule