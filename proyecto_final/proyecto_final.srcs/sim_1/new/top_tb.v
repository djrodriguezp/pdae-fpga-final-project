`timescale 1ns / 1ps

module top_tb;

    reg printed_output; 
    // Testbench signals
    reg clk;
    reg reset;
    wire  sw;
    wire [6:0] seg;
    wire [3:0] an;

    // Inicializar top module
    top  #( .NUM_CPU(4) )
    uut
    (
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
        reset = 1;      // assert reset immediately
        #100;           // hold long enough for clocks
        reset = 0;      // RELEASE reset → CPUs start running HERE
        #50000;         // let CPUs do work
    end

    always @(posedge clk) begin
        if (&uut.cpu_processing_done && !printed_output) begin
            $display("At time %0t: process_done=1, cycles_counter=%d", $time, uut.cycles_counter);
            printed_output = 1;
        end
    end
endmodule