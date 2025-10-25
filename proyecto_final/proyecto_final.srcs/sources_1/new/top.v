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
    input sw,  //sw16
    output [6:0] seg,
    output [3:0] an
);

    //Constantes globales
    localparam integer DIGITS_REFRESH_RATE = 200_000;
    // Variables globales
    reg process_done = 1'b0;
    reg [15:0] cycles_counter = 32'h00;
    reg [17:0] digits_counter = 0;
    reg [1:0] digit_select = 2'b00;
    reg  [3:0] current_display_number, current_an;
    wire [6:0] seg_output;
    
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
    
    reg [7:0] sum_lsb = 8'h00;
    reg [7:0] sum_msb = 8'h00;
    wire [7:0] in_port;
    reg [7:0] in_port_reg = 8'h00;
    reg p1_done = 1'b0;

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
            sum_lsb <= 8'h00;
            sum_msb <= 8'h00;
            p1_done <= 1'b0;
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
                    SUM_NUM_LSB:       sum_lsb <= out_port;
                    SUM_NUM_MSB:       sum_msb <= out_port;
                    MEM_ADDR_PORT_ID:  address_bus0   <= out_port;
                    SUM_DONE_PORT_ID: p1_done <= out_port[0];
                    
                endcase
            end
            
    end
    

    always @(posedge clk) begin
        if (reset) begin
            cycles_counter <= 0;
            process_done <= 0;
        end else  
            if (!p1_done) begin
                cycles_counter <= cycles_counter + 1;
            end else 
                  process_done <= 1;
    end
    
    //Señal Display 7 Segmentos
    
    always @(posedge clk) begin
        if(reset) begin
            digits_counter <= 0;
            digit_select <= 0; 
        end
        else
            if (digits_counter == DIGITS_REFRESH_RATE - 1) begin
                    digits_counter <= 0;
                    digit_select <= digit_select + 1; // Siguiente digito
                end else begin
                    digits_counter <= digits_counter + 1;
                end
            end
    
    always @(*) begin
        current_display_number = 4'b0000; //Seteamos el valor a desplegar a 0     
    
        case (digit_select)
            2'b00: begin // Digito menos significativo de la suma
                current_display_number = (sw) ? sum_lsb[3:0] : cycles_counter[3:0];
                current_an = 4'b1110; 
            end
            2'b01: begin  // Digito más significativo de la suma
                current_display_number = (sw) ? sum_lsb[7:4] : cycles_counter[7:4];
                current_an = 4'b1101; 
            end
            2'b10: begin //  Primer sumando
                current_display_number = (sw) ? sum_msb[3:0] : cycles_counter[11:8];
                current_an = 4'b1011; 
            end
            2'b11: begin // Segundo sumando
                current_display_number = (sw) ? sum_msb[7:4] : cycles_counter[15:12];
                current_an = 4'b0111; // Enable AN3
            end
            default: begin // Se apagan los leds en caso ocurra algún error (no debería de pasar)
                current_display_number = 4'b0000;; 
                current_an = 4'b1111; 
            end
        endcase
    end
    
    seg7_decoder decoder1(
        .hex_num(current_display_number),
        .seg_out(seg_output)
    );


    assign seg = seg_output; 
    assign an = current_an; 
endmodule
