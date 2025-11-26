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
    input logic beats_per_measure_minute_switcher,

    // information to be sent to frontend
    output logic [15:0] led,  // all 16 leds flash on downbeat
    output logic [3:0] an,  // seven-seg anodes (active low)
    output logic [6:0] seg,  // seven-seg segments
    input logic bpm_button_up,
    input logic bpm_button_down,
    input logic beats_per_measure_button_up,
    input logic beats_per_measure_button_down,
    input logic metronome_activate_button
);
  // initialize to 120 bpm and 4 beats per measure
  logic [7:0] bpm;
  logic [3:0] beats_per_measure;
  initial begin
    bpm <= 9'd120;
    beats_per_measure <= 4;
  end

  //Interface with left & right buttons to adjust bpm
  logic bpm_button_up_pressed;
  logic bpm_button_down_pressed;
  button_logic bpm_button_up_debounced (
      .clk(clk),
      .reset(reset),
      .button_in(bpm_button_up),
      .button_out(bpm_button_up_pressed)
  );
  button_logic bpm_button_down_debounced (
      .clk(clk),
      .reset(reset),
      .button_in(bpm_button_down),
      .button_out(bpm_button_down_pressed)
  );

  //Interface with top & bottom buttons to adjust beats per measure
  logic beats_per_measure_button_up_pressed;
  logic beats_per_measure_button_down_pressed;
  button_logic beats_per_measure_button_up_debounced (
      .clk(clk),
      .reset(reset),
      .button_in(beats_per_measure_button_up),
      .button_out(beats_per_measure_button_up_pressed)
  );
  button_logic beats_per_measure_button_down_debounced (
      .clk(clk),
      .reset(reset),
      .button_in(beats_per_measure_button_down),
      .button_out(beats_per_measure_button_down_pressed)
  );

  bpm_input adjust_bpm (
      .clk(clk),
      .reset(reset),
      .button_up(bpm_button_up_pressed),
      .button_down(bpm_button_down_pressed),
      .bpm_out(bpm)
  );

  beats_per_measure_input adjust_beats_per_measure (
      .clk(clk),
      .reset(reset),
      .button_up(beats_per_measure_button_up_pressed),
      .button_down(beats_per_measure_button_down_pressed),
      .beats_per_measure_out(beats_per_measure)
  );

  // get a beat tick from tempo_generator module
  logic beat_tick;
  logic beat_tick_active;
  tempo_generator gen (
      .clk(clk),
      .reset(reset),
      .bpm(bpm),
      .beat_tick(beat_tick)
  );

  // pass the beat_tick into downbeats and get a downbeat back
  logic downbeat;
  downbeats downbeats (
      .clk(clk),
      .reset(reset),
      .beats_per_measure(beats_per_measure),
      .beat_tick(beat_tick_active),
      .downbeat(downbeat)
  );

  // pass the downbeat and beat_tick information into Kai's frontend
  seven_seg_display frontend (
      .clk(clk),
      .bpm(bpm),
      .ts(beats_per_measure),
      .show_ts(beats_per_measure_minute_switcher),
      .downbeat(downbeat),
      .led(led),
      .an(an),
      .seg(seg),
      .dp()
  );


  // Moore machine to start/stop the entire metronome
  typedef enum logic [0:0] {
    RUN,
    STOP
  } state_type;
  state_type state;

  logic activate_button_pressed;
  button_logic activate_button_debounced (
      .clk(clk),
      .reset(reset),
      .button_in(metronome_activate_button),
      .button_out(activate_button_pressed)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STOP;
    end else if (state == STOP && activate_button_pressed) begin
      state <= RUN;
    end else if (state == RUN && activate_button_pressed) begin
      state <= STOP;
    end
  end

  assign beat_tick_active = (state == RUN) ? beat_tick : 1'b0;
endmodule
