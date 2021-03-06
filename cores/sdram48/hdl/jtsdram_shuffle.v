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
    input      [21:0] prog_addr,
    input             prog_en,
    output reg [21:0] addr_out,
    input      [15:0] ref_in,
    output reg [15:0] ref_out
);

reg  [21:0] addr_shf;
wire [ 3:0] addr_eff = prog_en ? prog_addr[3:0] : addr_shf[3:0];

function [3:0] swap;
    input [3:0] a;
    swap = { a[2], a[0], a[3], a[1] };
endfunction

always @(*) begin
    addr_shf = addr_in;
    if( key[0] )
        addr_shf = { addr_shf[11:0], addr_shf[12], addr_shf[21:13] };
    if( key[1] )
        addr_shf = { addr_shf[21:12], swap(addr_shf[11:8]), swap(addr_shf[7:4]), swap(addr_shf[3:0]) };
    if( key[2] )
        addr_shf = { addr_shf[20],addr_shf[21], swap(addr_shf[19:16]), swap(addr_shf[15:12]), addr_shf[11:0] };
    if( key[3])
        addr_shf = addr_shf ^ 22'h15_5555;
    if( key[4])
        addr_shf = addr_shf ^ 22'h2a_aaaa;
end

always @(posedge clk) begin
    addr_out <= addr_shf;
end

always @(*) begin
    ref_out = ref_in;
    if( key[0] ^ addr_eff[0] )
        ref_out = { ref_out[7:0], ref_out[15:8] };
    if( key[1] ^ addr_eff[1] )
        ref_out = { ref_out[15:8], swap(ref_out[7:4]), swap(ref_out[3:0]) };
    if( key[2] ^ addr_eff[2] )
        ref_out = { swap(ref_out[15:12]), swap(ref_out[11:8]), ref_out[7:0] };
    if( key[3] ^ addr_eff[3] )
        ref_out = ref_out ^ 16'h5555;
    if( key[4])
        ref_out = ref_out ^ 16'haaaa;
end

endmodule