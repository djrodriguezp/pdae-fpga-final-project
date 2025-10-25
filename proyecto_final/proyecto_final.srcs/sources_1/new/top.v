`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Universidad Galileo
// Engineer: Daniel Rodríguez
// 
// Create Date: 10/23/2025 10:49:34 PM
// Design Name: 
// Module Name: top
// Project Name: Proyecto Final Hardware reconfigurable
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


module top(
    input clk,
    input reset,        
    input sw,  //
    output [8:0] led    // Output LEDs
);
    
    
    // Wires para conectar a PicoBlaze
    wire [11:0] address;
    wire [17:0] instruction;
    wire [7:0] out_port;
    wire [7:0] port_id;
    wire read_strobe;
    wire write_strobe;
    wire k_write_strobe;
    wire interrupt;
    wire interrupt_ack; 
    wire sleep;
    wire bram_enable;
    
    reg [7:0] sum_reg = 8'h00;
    wire [7:0] in_port;
    reg [7:0] in_port_reg = 8'h00;
    reg carry = 1'b0;

    assign sleep = 1'b0;
    assign interrupt = 1'b0;
    assign bram_enable = 1'b1;
    assign k_write_strobe = 1'b0;
    assign interrupt_ack = 1'b0;
    assign in_port = in_port_reg;

    //Constantes para puertos
    localparam MEM_BASE_PORT_PORT_ID  = 8'h00; // I/O port para sw[7:0]
    localparam MEM_OFFSET_PORT_ID =  8'h01; // I/O port para sw[15:8]
    localparam MEM_DATA_PORT_ID =  8'h02;
    localparam MEM_ADDR_PORT_ID =  8'h03; 
    localparam SUM_DONE_PORT_ID = 8'h04;
    localparam LEDS_PORT_ID = 8'h05;
    
    //Wires para memoria externa con numeros
    wire [7:0] databus0;
    wire [7:0] databus1;
    wire [7:0] databus2;
    wire [7:0] databus3;
    wire [7:0] databus4;
    wire [7:0] databus5;
    wire [7:0] databus6;
    wire [7:0] databus7;
    reg [7:0] address_bus0;
    reg [7:0] address_bus1;
    reg [7:0] address_bus2;
    reg [7:0] address_bus3;
    reg [7:0] address_bus4;
    reg [7:0] address_bus5;
    reg [7:0] address_bus6;
    reg [7:0] address_bus7;
    localparam MEM_ADDR_BASE = 8'h05;
    localparam MEM_ADDR_OFFSET = 8'hFF;
    

    
    EightPortArray mem_numbers (
        .DataBus0(databus0),
        .DataBus1(databus1),
        .DataBus2(databus2),
        .DataBus3(databus3),
        .DataBus4(databus4),
        .DataBus5(databus5),
        .DataBus6(databus6),
        .DataBus7(databus7),
        .AddressBus0(address_bus0),
        .AddressBus1(address_bus1),
        .AddressBus2(address_bus2),
        .AddressBus3(address_bus3),
        .AddressBus4(address_bus4),
        .AddressBus5(address_bus5),
        .AddressBus6(address_bus6),
        .AddressBus7(address_bus7),
        .reset(reset),
        .clk(clk)
    );

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



    // ROM con las instrucciones a ejecutar
    prime_adder prime_adder_rom(
        .address(address),
        .instruction(instruction),
         .enable(1'b1), 
        .clk(clk)   
    );
    



    always @(posedge clk) begin
        if (reset) begin
            in_port_reg <= 8'h00;
            sum_reg <= 8'h00;
            carry <= 1'b0;
            address_bus0 <= 8'h00;
            address_bus1 <= 8'h00;
            address_bus2 <= 8'h00;
            address_bus3 <= 8'h00;
            address_bus4 <= 8'h00;
            address_bus5 <= 8'h00;
            address_bus6 <= 8'h00;
            address_bus7 <= 8'h00;
        end else if (read_strobe) begin
        // Only update the register when PicoBlaze is reading
        case(port_id)
            MEM_BASE_PORT_PORT_ID:   in_port_reg <= MEM_ADDR_BASE;
            MEM_OFFSET_PORT_ID:      in_port_reg <= MEM_ADDR_OFFSET;
            MEM_DATA_PORT_ID:        in_port_reg <= databus0;
        endcase
    end else if (write_strobe) begin
                case(port_id)
                    LEDS_PORT_ID:       sum_reg <= out_port;
                    MEM_ADDR_PORT_ID:  address_bus0   <= out_port;
                    SUM_DONE_PORT_ID: carry <= out_port[0];
                endcase
            end
            
    end
    

    assign led[7:0] = sum_reg;
    assign led[8] = carry;
    
endmodule
