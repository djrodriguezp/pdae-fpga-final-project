`timescale 1ns / 1ps

module top_tb;

    reg printed_output; 
    // Testbench signals
    reg clk;
    reg reset;
    wire  sw;
    wire [6:0] seg;
    wire [3:0] an;

    // Instantiate your top module
    top uut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .an(an),
        .seg(seg)
    );

    // Clock generation: 100 MHz -> 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;   // toggle every 5ns

    // Test sequence
    initial begin
        printed_output = 0;
// Reset pulse
        reset = 0;
        #50;
        reset = 1;
        #50;
        reset = 0;
        #5000;
        // Run long enough for CPU to execute instructions

    
        //$finish;
    end

    always @(posedge clk) begin
        if (uut.process_done & !printed_output) begin
            $display("At time %0t: process_done=1, cycles_counter=%d", $time, uut.cycles_counter);
            printed_output = 1;
        end
    end
endmodule