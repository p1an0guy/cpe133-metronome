`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2025 02:39:48 PM
// Design Name: 
// Module Name: beats_per_measure_input
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


module beats_per_measure_input (
    input logic clk,
    input logic reset,
    input logic button_up,
    input logic button_down,
    output logic [3:0] beats_per_measure_out
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      beats_per_measure_out <= 4'd4;
    end else begin
      if (button_up && beats_per_measure_out < 4'd15)
        beats_per_measure_out <= beats_per_measure_out + 1;
      if (button_down && beats_per_measure_out > 4'd1)
        beats_per_measure_out <= beats_per_measure_out - 1;
    end
  end
endmodule
