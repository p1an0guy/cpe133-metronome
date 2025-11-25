`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 05:05:12 PM
// Design Name: 
// Module Name: tempo_generator
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


module tempo_generator (
    input logic clk,
    input logic reset,
    input logic [8:0] bpm,  // supports up to ~500 bpm
    output logic beat_tick  // "tick" after conversion from 1 ms
);
  logic [31:0] millesecond_accumulator;
  logic millesecond_tick;
  ms_tick tick (
      .clk(clk),
      .reset(reset),
      .ms_tick(millesecond_tick)
  );

  always_ff @(posedge clock) begin
    if (reset) begin
      millesecond_accumulator <= 0;
      beat_tick <= 0;
    end else begin
      beat_tick <= 0;
      if (millesecond_tick) begin
        // trigger a "beat tick" after enough time has passed
        if (millesecond_accumulator + bpm >= 60000) begin
          beat_tick <= 1;
          millesecond_accumulator <= millesecond_accumulator + bpm - 60000;
        end
      end

    end

  end
endmodule
