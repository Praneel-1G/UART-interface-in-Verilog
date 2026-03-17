`timescale 1ns / 1ps

module mod_m_counter #(
    parameter M = 10
    )(
    input wire clk, rst,
    output wire max_tick,
    output wire [$clog2(M)-1:0] q
);

    reg [N-1:0] r_reg;
    wire [N-1:0] r_next;

    always @(posedge clk or posedge rst) begin
        if (rst)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end

    assign r_next = (r_reg == M - 1) ? 0 : r_reg + 1;
    assign q = r_reg;
    assign max_tick = (r_reg == M - 1) ? 1'b1 : 1'b0;

endmodule