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

module jtsdram_bank(
    input             rst,
    input             clk,
    input             LVBL,
    output reg [21:0] addr,
    output reg        rd,
    input             ack,
    input             rdy,
    input      [15:0] data_ref,
    input             start,
    input      [31:0] data_read,
    output reg        bad,
    output reg        done
);

reg dly_rd;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        addr   <= 22'd0;
        bad    <= 0;
        done   <= 0;
        dly_rd <= 0;
    end else begin
        if(start) begin
            addr <= 22'd0;
            rd   <= 1;
            done <= 0;
            bad  <= 0;
        end else if(!done) begin
            if( dly_rd && LVBL ) begin
                dly_rd <= 0;
                rd     <= 1;
            end
            if( ack ) begin
                rd <= 0;
            end
            else if( rdy ) begin
                if( &addr )
                    done <= 1;
                else begin
                    if( LVBL ) begin
                        rd     <= 1;
                        dly_rd <= 0;
                    end else
                        dly_rd <= 1;
                end
                addr <= addr + 1'd1;
                if( data_read != {2{data_ref}} ) bad <= 1;
            end
        end
    end
end

endmodule