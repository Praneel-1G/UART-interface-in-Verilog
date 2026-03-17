`timescale 1ns/1ps
module uart_rx_tb();
reg clk , rst , rx , s_tick;
wire rx_done_tick ;
wire [7:0] dout;

// test main clock at 10ns (100MHZ)
// s_tick every 4 clocks pulse (just for simulation)
// 1 Tick = 40ns
// 1UART Bit = 16 Ticks = 640ns
localparam CLK_PERIOD = 10;
localparam TICK_PERIOD = 4 * CLK_PERIOD;
localparam BIT_PERIOD = 16 * TICK_PERIOD; // 640ns per bit

uart_rx #(.DBIT(8), .SB_TICK(16))
uut(.*);

// main clock generation
always #(CLK_PERIOD/2) clk = ~clk;
// tick generation (over sampling)
// pulse of width 1 clock cycles repeating every 4 clocks.
always begin 
    s_tick = 0;
    #(TICK_PERIOD - CLK_PERIOD);
    s_tick =1;
    #(CLK_PERIOD);
end
// sending a byte (mimics uart tx)
task uart_send_byte;
input [7:0] data;
integer i;
begin
    // start bit (low for 16 tics)
    rx = 0;
    #(BIT_PERIOD);

    // data bits (lsb first)
    for (i = 0 ; i < 8 ; i = i+1) begin
        rx = data[i];
        #(BIT_PERIOD);
    end
    // stop bit
    rx =1;
    #(BIT_PERIOD);
end
endtask

// Main test sequence
initial begin
    clk = 0 ;
    rst =1;
    rx = 1;

    #100;
    rst = 0;
    #100;

    // test case 1: sending 0x55 
    $display("Sending 0x55...");
    uart_send_byte(8'h55);

    // check result
    @(posedge rx_done_tick); // wait for done signal
    #10;
    if (dout == 8'h55) $display("SUCESS: Recieved 0x55");
    else $display("FALURE : expected 0x55, got %h", dout);

    // wait a bit
    #1000;
end
initial begin
    $dumpfile("rx.vcd");
    $dumpvars(0,uart_rx_tb);
end

endmodule