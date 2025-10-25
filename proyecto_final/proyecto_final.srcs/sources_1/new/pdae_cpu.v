`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Daniel Rodriguez
// 
// Create Date: 10/25/2025 08:43:07 PM
// Design Name: 
// Module Name: pdae_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pdae_cpu #(
    parameter integer MEM_ADDR_BASE = 0, MEM_ADDR_LAST = 255
)(
    input clk,
    input reset,
    input	 [17:0]    	instruction ,
    input [7:0] address_bus,
    input [7:0] databus,
    output [15:0] sum,
    output process_done,
    output [11:0]	address 
    );
    
    wire [7:0] in_port;
    wire [7:0] out_port;
    wire [7:0] port_id;
    wire read_strobe;
    wire write_strobe;
    wire k_write_strobe;
    wire interrupt;
    wire interrupt_ack; 
    wire sleep;
    wire bram_enable;
    
    
    reg [7:0] in_port_reg = 8'h00;
    reg done = 1'b0;
    reg [7:0] sum_lsb = 8'h00;
    reg [7:0] sum_msb = 8'h00;
    reg [7:0] address_bus_reg =  8'h00;
    
    assign sleep = 1'b0;
    assign interrupt = 1'b0;
    assign bram_enable = 1'b1;
    assign k_write_strobe = 1'b0;
    assign interrupt_ack = 1'b0;
    assign in_port = in_port_reg;
    
    //Constantes para puertos
    localparam MEM_BASE_PORT_PORT_ID  = 8'h00; 
    localparam MEM_OFFSET_PORT_ID =  8'h01; 
    localparam MEM_DATA_PORT_ID =  8'h02;
    localparam MEM_ADDR_PORT_ID =  8'h03; 
    localparam SUM_DONE_PORT_ID = 8'h04;
    localparam SUM_NUM_LSB = 8'h05;
    localparam SUM_NUM_MSB = 8'h06;
    
    
    kcpsm6 #( // Override default parameters
        .hwbuild(8'h00),
        .interrupt_vector(12'h3FF),
        .scratch_pad_memory_size(64)
    )  
    cpu (
	   .address 		(address),
	   .instruction 	(instruction),
	   .bram_enable 	(bram_enable),
	   .port_id 		(port_id),
	   .write_strobe 	(write_strobe),
	   .k_write_strobe 	(k_write_strobe),
	   .out_port 		(out_port),
	   .read_strobe 	(read_strobe),
	   .in_port 		(in_port),
	   .interrupt 		(interrupt),
	   .interrupt_ack 	(interrupt_ack),
	   .sleep(sleep),
	   .reset 		(reset),
	   .clk (clk)
    );
    
    
   always @(posedge clk) begin
        if (reset) begin
            in_port_reg <= 8'h00;
            sum_lsb <= 8'h00;
            sum_msb <= 8'h00;
            done <= 1'b0;
            address_bus_reg <= 8'h00;
        end else if (read_strobe) begin
        // Only update the register when PicoBlaze is reading
        case(port_id)
            MEM_BASE_PORT_PORT_ID:   in_port_reg <= MEM_ADDR_BASE;
            MEM_OFFSET_PORT_ID:      in_port_reg <= MEM_ADDR_LAST;
            MEM_DATA_PORT_ID:        in_port_reg <= databus;
        endcase
    end else if (write_strobe) begin
                case(port_id)
                    SUM_NUM_LSB:       sum_lsb <= out_port;
                    SUM_NUM_MSB:       sum_msb <= out_port;
                    MEM_ADDR_PORT_ID:  address_bus_reg   <= out_port;
                    SUM_DONE_PORT_ID: done <= out_port[0];
                    
                endcase
            end
            
    end
    
    assign address_bus = address_bus_reg;
    assign process_done = done;
    assign sum[7:0]  = sum_lsb;
    assign sum[15:8] = sum_msb;
endmodule
