`timescale 1ns / 1ps

module uart_tx_tb;

    // --- 1. Signal Declaration ---
    reg clk;
    reg rst;
    reg tx_start;
    reg s_tick;
    reg [7:0] din;
    
    wire tx_done_tick;
    wire tx;

    // --- 2. Instantiate the Unit Under Test (UUT) ---
    uart_tx #(
        .DBIT(8), 
        .SB_TICK(16)
    ) uut (
        .clk(clk), 
        .rst(rst), 
        .tx_start(tx_start), 
        .s_tick(s_tick), 
        .din(din), 
        .tx_done_tick(tx_done_tick), 
        .tx(tx)
    );

    // --- 3. Clock Generation ---
    // 10ns Clock Period (100 MHz)
    always #5 clk = ~clk;

    // --- 4. Tick Generation (Simulating Baud Rate Gen) ---
    // We want 's_tick' to pulse HIGH for 1 clock cycle every few clocks.
    // Let's pulse it every 4 clocks to simulate 16x oversampling.
    // 1 Tick Period = 4 * 10ns = 40ns.
    // 1 Bit Duration = 16 * 40ns = 640ns.
    always begin
        s_tick = 0;
        #30;       // Wait 3 clocks
        s_tick = 1; 
        #10;       // Pulse high for 1 clock
    end

    // --- 5. Main Test Sequence ---
    initial begin
        // A. Initialization
        clk = 0;
        rst = 1;
        tx_start = 0;
        din = 0;
        
        // B. Reset Pulse
        #100;
        rst = 0;
        #100;

        // --- TEST CASE 1: Send '0x55' (Binary 01010101) ---
        // Expected Output on TX line:
        // Idle(1) -> Start(0) -> 1 -> 0 -> 1 -> 0 -> 1 -> 0 -> 1 -> 0 -> Stop(1)
        
        $display("Sending 0x55...");
        din = 8'h55;
        tx_start = 1;
        @(posedge clk); // Hold start for 1 clock cycle
        tx_start = 0;

        // Wait for the transmission to finish
        // We look for the 'tx_done_tick' signal
        wait(tx_done_tick);
        $display("Done sending 0x55 at time %t", $time);

        // Wait a bit between transmissions
        #2000;

        // --- TEST CASE 2: Send '0x33' (Binary 00110011) ---
        // Expect: Start(0) -> 1 -> 1 -> 0 -> 0 -> 1 -> 1 -> 0 -> 0 -> Stop(1)
        
        $display("Sending 0x33...");
        din = 8'h33;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;

        wait(tx_done_tick);
        $display("Done sending 0x33 at time %t", $time);

        #1000;
        $finish;
    end

initial begin
    $dumpfile("tx.vcd");
    $dumpvars(0,uart_tx_tb);
end

endmodule