`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2025 02:16:31 PM
// Design Name: 
// Module Name: downbeats
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


module downbeats (
    input logic clk,
    input logic reset,
    input logic [3:0] beats_per_measure,
    input logic beat_tick,
    output logic downbeat
);
  logic [3:0] beat_idx;

  always_ff @(posedge clk or posedge reset) begin
    downbeat <= 0;
    if (reset) begin
      beat_idx <= 0;
    end else if (beat_tick) begin
      if (beat_idx >= beats_per_measure - 1) begin
        beat_idx <= 0;
        downbeat <= 1;
      end else begin
        beat_idx <= beat_idx + 1;
      end
    end
  end
endmodule
