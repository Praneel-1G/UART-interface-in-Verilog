`timescale 1ns / 1ps

module fifo #(
    parameter int B = 8,
    parameter int W = 4
)(
    input  logic clk, rst, rd, wr,
    input  logic [B-1:0] w_data,
    output logic empty, full,
    output logic [B-1:0] r_data
);

    logic [B-1:0] array_reg [0:(2**W)-1]; // FIXED! Properly sized array.
    logic [W-1:0] w_ptr_reg, w_ptr_next, w_ptr_succ;
    logic [W-1:0] r_ptr_reg, r_ptr_next, r_ptr_succ;
    logic full_reg, empty_reg, full_next, empty_next;
    logic wr_en;

    assign wr_en = wr & ~full_reg;

    always_ff @(posedge clk) begin
        if (wr_en) begin
            array_reg[w_ptr_reg] <= w_data;
        end
    end

    assign r_data = array_reg[r_ptr_reg];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr_reg <= '0;
            r_ptr_reg <= '0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        w_ptr_succ = w_ptr_reg + 1;
        r_ptr_succ = r_ptr_reg + 1;
        
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        
        case ({wr, rd})
            2'b01: begin
                if (~empty_reg) begin
                    r_ptr_next = r_ptr_succ;
                    full_next  = 1'b0;
                    if (r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1;
                end
            end
            2'b10: begin
                if (~full_reg) begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if (w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1;
                end
            end
            2'b11: begin
                w_ptr_next = w_ptr_succ;
                r_ptr_next = r_ptr_succ;
            end
            default: ;
        endcase
    end

    assign full  = full_reg;
    assign empty = empty_reg;

endmodule