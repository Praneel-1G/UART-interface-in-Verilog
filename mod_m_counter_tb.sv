`timescale 1ns / 1ps

module mod_m_counter_tb;

    // 1. Inputs to UUT (Unit Under Test)
    reg clk;
    reg rst;

    // 2. Outputs from UUT
    wire max_tick;
    wire [7:0] q; // 4 bits to hold the number 10

    // 3. Parameters for this specific test
    // We want to count to 10 (0 to 9)
    localparam M = 163; 
    localparam N = 8;  // 4 bits needed to store "9"

    // 4. Instantiate the Counter
    mod_m_counter #(
        .M(M), 
        .N(N)
    ) uut (
        .clk(clk),
        .rst(rst),
        .max_tick(max_tick),
        .q(q)
    );

    // 5. Clock Generation (Run at 100 MHz -> 10ns period)
    always #5 clk = ~clk;

    // 6. Test Sequence
    initial begin
        // --- Setup ---
        $display("Starting Simulation: Mod-%0d Counter", M);
        clk = 0;
        rst = 1; // Hold rst initially
        
        // --- Release rst ---
        #20;
        rst = 0;
        $display("rst released.");

        // --- Let it run for 25 clock cycles ---
        // It should wrap around twice (10 + 10 + 5)
        repeat (25) @(posedge clk);

        // --- Test rst in the middle ---
        // Let's force a rst when it's halfway through counting
        $display("Forcing rst...");
        rst = 1;
        #20;
        rst = 0;
        
        // --- Run a bit more ---
        repeat (15) @(posedge clk);
        
    end
    
    // Optional: Print status to console
    initial begin
        $monitor("Time: %0t | Count (q): %d | Tick: %b | rst: %b", 
                 $time, q, max_tick, rst);
    end
    initial begin 
        $dumpfile("mod_m_counter.vcd");
        $dumpvars(0,mod_m_counter_tb);
    end

endmodule