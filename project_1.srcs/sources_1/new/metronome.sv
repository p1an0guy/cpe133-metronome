`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 02:45:32 PM
// Design Name: 
// Module Name: metronome
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


module metronome (
    input logic clk,
    input logic reset,
    input logic bpm_button_up,
    input logic bpm_button_down,
    output logic [8:0] bpm_out  // TO BE USED FOR FRONTEND
    // TODO: drive an output for time signature once we have that implemented 
);

  // initialize to 120 bpm
  logic [8:0] bpm = 9'd120;
  // drive the output for bpm_out to be used by frontend processes
  assign bpm_out = bpm;

//Interface with left & right buttons to adjust bpm
logic bpm_button_up_pressed;
logic bpm_button_down_pressed;
button_logic bpm_button_up_debounced(.clk(clk), .reset(reset), .button_in(bpm_button_up), .button_out(bpm_button_up_pressed));
button_logic bpm_button_down_debounced(.clk(clk), .reset(reset), .button_in(bpm_button_down), .button_out(bpm_button_down_pressed));

bpm_input adjust_bpm(.clk(clk), .reset(reset), .button_up(bpm_button_up), .button_down(bpm_button_down), .bpm_out(bpm));

  // get a beat tick from tempo_generator module
  logic beat_tick;
  logic beat_tick_active;
  tempo_generator gen (
      .clk(clk),
      .reset(reset),
      .button_up(bpm_up_button),
      .button_down(bpm_down_button),
      .bpm(bpm),
      .beat_tick(beat_tick)
  );

  typedef enum logic [0:0] {
    RUN,
    STOP
  } state_type;
  state_type state;

//  always_ff @(posedge clk or posedge reset) begin
//    if (reset) begin
//      state <= STOP;
//    end else if (state == STOP && button_pressed) begin
//      state <= RUN;
//    end else if (state == RUN && button_pressed) begin
//      state <= STOP;
//    end
//  end

  assign beat_tick_active = (state == RUN) ? beat_tick : 1'b0;

endmodule
