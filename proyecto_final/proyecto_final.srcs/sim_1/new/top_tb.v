`timescale 1ns / 1ps

module top_tb;

    // Testbench signals
    reg clk;
    reg reset;
    reg  sw;
    wire [8:0] led;

    // Instantiate your top module
    top uut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .led(led)
    );

    // Clock generation: 100 MHz -> 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;   // toggle every 5ns

    // Test sequence
    initial begin
// Reset pulse
        reset = 0;
        sw = 16'h0000;
        #50;
        reset = 1;
        #50;
        reset = 0;
        sw = 16'h0004;
    
        
        // Run long enough for CPU to execute instructions
        #500000;
    
        $finish;
    end

endmodule