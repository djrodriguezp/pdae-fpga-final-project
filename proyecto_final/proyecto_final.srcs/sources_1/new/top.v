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


module top #(
    parameter integer NUM_CPU = 4 
)(
    input clk,
    input reset,        
    input sw,  //sw16
    output [6:0] seg,
    output [3:0] an
);

    //Constantes globales
    localparam integer DIGITS_REFRESH_RATE = 200_000;
    
    // Variables globales
    wire [11:0] address [0:NUM_CPU-1];
    wire [17:0] instruction [0:NUM_CPU-1]; 
    wire [NUM_CPU-1:0] cpu_processing_done; //Wires para mapear las salida de los CPU cuando terminan de operar
    wire [15:0] cpu_sum_output [0:NUM_CPU-1]; 
    wire [6:0] seg_output;
    reg [15:0] total_sum = 16'h00;
    reg [15:0] cycles_counter = 16'h00;
    reg [17:0] digits_counter = 0;
    reg [1:0] digit_select = 2'b00;
    reg  [3:0] current_display_number, current_an;
    reg total_sum_done = 1'b0;
    reg [15:0] total_sum_tmp;
    
    //Wires para memoria externa con numeros
    wire [7:0] databus     [7:0]; 
    wire  [7:0] address_bus [7:0];

    EightPortArray mem_numbers (
        .DataBus0(databus[0]),
        .DataBus1(databus[1]),
        .DataBus2(databus[2]),
        .DataBus3(databus[3]),
        .DataBus4(databus[4]),
        .DataBus5(databus[5]),
        .DataBus6(databus[6]),
        .DataBus7(databus[7]),
        .AddressBus0(address_bus[0]),
        .AddressBus1(address_bus[1]),
        .AddressBus2(address_bus[2]),
        .AddressBus3(address_bus[3]),
        .AddressBus4(address_bus[4]),
        .AddressBus5(address_bus[5]),
        .AddressBus6(address_bus[6]),
        .AddressBus7(address_bus[7]),
        .reset(reset),
        .clk(clk)
    );
    

    genvar i;
    generate
        for (i = 0; i < NUM_CPU; i = i + 1) begin : CPUS
            localparam integer MEM_ADDR_BASE  = (256 / NUM_CPU) * i;
            localparam integer MEM_ADDR_LAST = MEM_ADDR_BASE + (256 / NUM_CPU) - 1;
    
            pdae_cpu #(
            .MEM_ADDR_BASE(MEM_ADDR_BASE), 
            .MEM_ADDR_LAST(MEM_ADDR_LAST)) 
            cpu (
                .clk(clk), 
                .reset(reset),
                .address(address[i]),
                .instruction(instruction[i]),
                .databus(databus[i]),
                .address_bus(address_bus[i]),
                .process_done(cpu_processing_done[i]), 
                .sum(cpu_sum_output[i])
            );
        end
        
        for (i = 0; i < NUM_CPU; i = i + 1) begin : ROMS
            prime_adder prime_adder_rom (
                .address(address[i]),
                .instruction(instruction[i]),
                .enable(1'b1),
                .clk(clk)
            );
        end 
    endgenerate
    
    
    integer j;
    always @(posedge clk) begin
        if (reset) begin
            cycles_counter   <= 0;
            total_sum        <= 0;
            total_sum_done   <= 0;
        end else begin
            // Incrementamos el contador de ciclos
            if (!(&cpu_processing_done))
                cycles_counter <= cycles_counter + 1;
    
            // Suma total de todos los CPU
            else if (!total_sum_done) begin
                total_sum_tmp = 0;
                for (j = 0; j < NUM_CPU; j = j + 1) begin
                    total_sum_tmp = total_sum_tmp + cpu_sum_output[j]; //Bloqueamos para evitar race cond
                end
                total_sum <= total_sum_tmp;
                total_sum_done <= 1'b1;
            end
        end
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
                current_display_number = (sw) ? total_sum[3:0] : cycles_counter[3:0];
                current_an = 4'b1110; 
            end
            2'b01: begin  // Digito más significativo de la suma
                current_display_number = (sw) ? total_sum[7:4] : cycles_counter[7:4];
                current_an = 4'b1101; 
            end
            2'b10: begin //  Primer sumando
                current_display_number = (sw) ? total_sum[11:8] : cycles_counter[11:8];
                current_an = 4'b1011; 
            end
            2'b11: begin // Segundo sumando
                current_display_number = (sw) ? total_sum[15:12] : cycles_counter[15:12];
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
