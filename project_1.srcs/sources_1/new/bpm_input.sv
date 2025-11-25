`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2025 02:37:54 PM
// Design Name: 
// Module Name: bpm_input
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


module bpm_input (
    input logic clk,
    input logic reset,
    input logic button_up,
    input logic button_down,
    output logic [7:0] bpm_out
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      bpm_out <= 9'd120;
    end else begin
      if (button_up && bpm_out < 8'd500) bpm_out <= bpm_out + 1;
      if (button_down && bpm_out > 8'd40) bpm_out <= bpm_out - 1;
    end
  end
endmodule
