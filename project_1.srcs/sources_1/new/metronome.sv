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

    // information to be sent to frontend
    input beats_per_measure_minute_switcher,
    output logic [7:0] bpm_out,
    output logic [3:0] beats_per_measure,

    // frontend
    output logic [15:0] led,  // all 16 leds flash on downbeat
    output logic [3:0] an,  // seven-seg anodes (active low)
    output logic [6:0] seg,  // seven-seg segments
    output logic dp  // seven-seg dp
);

  // initialize to 120 bpm
  logic [8:0] bpm = 9'd120;
  // drive the output for bpm_out to be used by frontend processes
  assign bpm_out = bpm;


  // get a beat tick from tempo_generator module
  logic beat_tick;
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
      .beat_tick(beat_tick),
      .downbeat(downbeat)
  );

  // pass the downbeat and beat_tick information into Kai's frontend
  seven_seg_display frontend (
      .clk(clk),
      .bpm(bpm_out),
      .ts(beats_per_measure),
      .show_ts(beats_per_measure_minute_switcher),
      .downbeat(downbeat),
      .led(led),
      .an(an),
      .seg(seg),
      .dp(dp)
  );

  // TODO: Issac Becker to implement interface with buttons
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      bpm <= 9'd120;
    end else begin
      if (button_increment && bpm < 9'd255) bpm <= bpm + 1;
      if (button_decrement && bpm > 9'd40) bpm <= bpm - 1;
    end
  end

  // Moore machine to start/stop the entire metronome
  typedef enum logic [0:0] {
    RUN,
    STOP
  } state_type;
  state_type state;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STOP;
    end else if (state == STOP && button_pressed) begin
      state <= RUN;
    end else if (state == RUN && button_pressed) begin
      state <= STOP;
    end
  end

endmodule

