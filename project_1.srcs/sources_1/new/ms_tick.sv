`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Jonah Chan
// 
// Create Date: 11/20/2025 04:54:29 PM
// Module Name: ms_tick
// Project Name: metronome
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ms_tick (
    input  logic clk,
    input  logic reset,
    output logic ms_tick
);
  logic [16:0] ms_div;  // used as mod-99,999 counter

  always_ff @(posedge clk or posedge reset) begin

    if (reset) begin
      ms_div  <= 0;
      ms_tick <= 0;
    end else begin
      ms_tick <= 0;  // set the "tick" to low
      // set the "tick" to high once every millisecond
      if (ms_div == 99_999) begin
        ms_div  <= 0;
        ms_tick <= 1;
      end else begin
        ms_div <= ms_div + 1;
      end
    end
  end

endmodule
