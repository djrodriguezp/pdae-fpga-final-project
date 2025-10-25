`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2025 07:42:17 PM
// Design Name: 
// Module Name: seg7_decoder
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


module seg7_decoder(
    input [3:0] hex_num,
    output [6:0] seg_out
    );
    
    reg [6:0] seg_data;

    always @(*) begin
        case (hex_num)


            4'h0: seg_data = 7'b0000001; // 0
            4'h1: seg_data = 7'b1001111; // 1
            4'h2: seg_data = 7'b0010010; // 2
            4'h3: seg_data = 7'b0000110; // 3
            4'h4: seg_data = 7'b1001100; // 4
            4'h5: seg_data = 7'b0100100; // 5
            4'h6: seg_data = 7'b0100000; // 6
            4'h7: seg_data = 7'b0001111; // 7
            4'h8: seg_data = 7'b0000000; // 8
            4'h9: seg_data = 7'b0000100; // 9
            4'hA: seg_data = 7'b0001000; // A
            4'hB: seg_data = 7'b1100000; // b
            4'hC: seg_data = 7'b0110001; // C
            4'hD: seg_data = 7'b1000010; // d
            4'hE: seg_data = 7'b0110000; // E
            4'hF: seg_data = 7'b0111000; // F
            
            default: seg_data = 7'b1111111; // Todos apagados en caso de error
        endcase
    end
    
    
    assign seg_out = seg_data;
endmodule
