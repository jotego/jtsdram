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

module jtsdram_shuffle(
    input             rst,
    input             clk,
    input      [ 4:0] key,
    input      [21:0] addr_in,
    output reg [21:0] addr_out,
    input      [15:0] ref_in,
    output reg [15:0] ref_out
);

function [3:0] swap;
    input [3:0] a;
    swap = { a[2], a[0], a[3], a[1] };
endfunction

always @(*) begin
    addr_out = addr_in;
    if( key[0] )
        addr_out = { addr_out[11:0], addr_out[12], addr_out[21:13] };
    if( key[1] )
        addr_out = { addr_out[21:12], swap(addr_out[11:8]), swap(addr_out[7:4]), swap(addr_out[3:0]) };
    if( key[2] )
        addr_out = { addr_out[20],addr_out[21], swap(addr_out[19:16]), swap(addr_out[15:12]), addr_out[11:0] };
    if( key[3])
        addr_out = addr_out ^ 22'h15_5555;
    if( key[4])
        addr_out = addr_out ^ 22'h2a_aaaa;
end

always @(*) begin
    ref_out = ref_in;
    if( key[0] )
        ref_out = { ref_out[7:0], ref_out[15:8] };
    if( key[1] )
        ref_out = { ref_out[15:8], swap(ref_out[7:4]), swap(ref_out[3:0]) };
    if( key[2] )
        ref_out = { swap(ref_out[15:12]), swap(ref_out[11:8]), ref_out[7:0] };
    if( key[3])
        ref_out = ref_out ^ 16'h5555;
    if( key[4])
        ref_out = ref_out ^ 16'haaaa;
end

endmodule