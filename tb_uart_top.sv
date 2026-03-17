`timescale 1ns / 1ps

module tb_uart_top;

    // --- Signal Declarations ---
    reg clk;
    reg rst;
    reg rd_uart;
    reg wr_uart;
    reg [7:0] w_data;
    
    wire tx_full;
    wire rx_empty;
    wire tx;
    wire [7:0] r_data;
    
    integer i;
    integer timeout;
    integer errors;

    // --- Array to hold our test "Pixels" ---
    reg [7:0] pixel_array [0:9];

    // --- Instantiate the Top-Level UART ---
    uart #(
        .DBIT(8), .SB_TICK(16), .DVSR(325), .DVSR_BIT(9), .FIFO_W(2)
    ) uut (
        .clk(clk), .rst(rst), .rd_uart(rd_uart), .wr_uart(wr_uart),
        .rx(tx),           // LOOPBACK: Connect TX directly to RX
        .w_data(w_data), .tx_full(tx_full), .rx_empty(rx_empty),
        .tx(tx), .r_data(r_data)
    );

    // --- Clock Generation (10ns period) ---
    always #5 clk = ~clk; 

    initial begin
        // 1. Initialize Signals
        clk = 0; 
        rst = 1; 
        rd_uart = 0; 
        wr_uart = 0; 
        w_data = 0;
        errors = 0;

        // Load our array with 10 dummy pixels
        pixel_array[0] = 8'hA1;
        pixel_array[1] = 8'hB2;
        pixel_array[2] = 8'hC3;
        pixel_array[3] = 8'hD4;
        pixel_array[4] = 8'hE5;
        pixel_array[5] = 8'hF6;
        pixel_array[6] = 8'h17;
        pixel_array[7] = 8'h28;
        pixel_array[8] = 8'h39;
        pixel_array[9] = 8'h4A;

        // Apply Reset
        #50; 
        rst = 0; 
        #50;

        // 2. Parallel Processing (Pushing and Popping at the same time)
        fork
            // ---------------------------------------------------------
            // THREAD 1: PUSH DATA (TX)
            // ---------------------------------------------------------
            begin
                $display("--- Starting Transmission Stream ---");
                for (i = 0; i < 10; i = i + 1) begin
                    // Wait safely if the TX FIFO fills up (since it only holds 4 bytes)
                    wait (tx_full == 1'b0);
                    
                    // Align to clock and push data
                    @(posedge clk);
                    w_data = pixel_array[i];
                    wr_uart = 1;
                    
                    @(posedge clk);
                    wr_uart = 0; // Deassert write
                    
                    $display("[%0t] Pushed index %0d: 0x%h", $time, i, pixel_array[i]);
                end
                $display("--- Finished Transmitting Stream ---");
            end

            // ---------------------------------------------------------
            // THREAD 2: POP DATA (RX)
            // ---------------------------------------------------------
            begin
                $display("--- Starting Reception Stream ---");
                // Note: We use a different loop variable index here or hardcode it 
                // to avoid clashing with the 'i' in thread 1. Let's use a local integer.
                for (int j = 0; j < 10; j = j + 1) begin
                    timeout = 0;
                    
                    // Wait for data to arrive, with a timeout safety net
                    while (rx_empty == 1'b1 && timeout < 100000) begin
                        @(posedge clk);
                        timeout = timeout + 1;
                    end

                    if (timeout >= 100000) begin
                        $display("❌ TIMEOUT! Lost data at index %0d.", j);
                        errors = errors + 1;
                    end else begin
                        // 1. Tell the synchronous FIFO to output the data
                        @(posedge clk);
                        rd_uart = 1; 
                        
                        // 2. Wait exactly 1 clock for data to appear on r_data
                        @(posedge clk); 
                        rd_uart = 0; // Turn off read
                        
                        // 3. Now check the data!
                        if (r_data === pixel_array[j]) begin
                            $display("[%0t] ✅ Received index %0d: 0x%h", $time, j, r_data);
                        end else begin
                            $display("[%0t] ❌ ERROR index %0d: Expected 0x%h, Got 0x%h", $time, j, pixel_array[j], r_data);
                            errors = errors + 1;
                        end
                    end
                end
                
                // Final Results
                $display("========================================");
                if (errors == 0)
                    $display("🎉 ALL 10 PIXELS LOOPED BACK PERFECTLY! 🎉");
                else
                    $display("⚠️ Test finished with %0d errors.", errors);
                $display("========================================");
            end
        join // The simulation waits here until BOTH threads finish

        #1000;
        $finish;
    end

    // --- Waveform Dumping ---
    initial begin 
        $dumpfile("uart_top.vcd");
        $dumpvars(0, tb_uart_top);
    end

endmodule