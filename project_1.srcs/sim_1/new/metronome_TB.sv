`timescale 1ns / 1ps

module metronome_TB;
  timeunit 1ns;
  timeprecision 1ps;

  // 100 MHz clock
  logic clk = 0;
  always #5 clk = ~clk;

  // DUT connections
  logic        reset;
  logic        beats_per_measure_minute_switcher;
  logic        bpm_button_up;
  logic        bpm_button_down;
  logic        beats_per_measure_button_up;
  logic        beats_per_measure_button_down;
  logic        metronome_activate_button;
  logic [15:0] led;
  logic [3:0]  an;
  logic [6:0]  seg;

  metronome uut (
      .clk                           (clk),
      .reset                         (reset),
      .beats_per_measure_minute_switcher(beats_per_measure_minute_switcher),
      .led                           (led),
      .an                            (an),
      .seg                           (seg),
      .bpm_button_up                 (bpm_button_up),
      .bpm_button_down               (bpm_button_down),
      .beats_per_measure_button_up   (beats_per_measure_button_up),
      .beats_per_measure_button_down (beats_per_measure_button_down),
      .metronome_activate_button     (metronome_activate_button)
  );

  // Speed up long-running counters for simulation friendliness.
  defparam uut.gen.tick.CYCLES_PER_MS = 100;
  defparam uut.frontend.u_front.u_ledflash_downbeat.FLASH_MS = 4;
  defparam uut.frontend.u_front.u_ledflash_downbeat.CLK_HZ  = 1_000_000;
  defparam uut.frontend.u_front.u_ledflash_beat.FLASH_MS    = 4;
  defparam uut.frontend.u_front.u_ledflash_beat.CLK_HZ      = 1_000_000;

  defparam uut.bpm_button_up_debounced.MAX_COUNT                = 10;
  defparam uut.bpm_button_down_debounced.MAX_COUNT              = 10;
  defparam uut.beats_per_measure_button_up_debounced.MAX_COUNT  = 10;
  defparam uut.beats_per_measure_button_down_debounced.MAX_COUNT= 10;
  defparam uut.activate_button_debounced.MAX_COUNT              = 10;

  // Simple helper to create a debounced button press.
  task automatic press_button(ref logic btn);
    begin
      btn = 1'b1;
      repeat (20) @(posedge clk);
      btn = 1'b0;
      repeat (20) @(posedge clk);
    end
  endtask

  // Monitor LED activity so the waveform/log shows downbeat flashes.
  logic [15:0] led_prev;
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      led_prev <= '0;
    end else if (led !== led_prev) begin
      $display("[%0t ns] LED state -> %016b", $time, led);
      led_prev <= led;
    end
  end

  // Also log explicit downbeat events.
  always @(posedge uut.downbeat) begin
    $display("[%0t ns] *** DOWNBEAT (all LEDs on) ***", $time);
  end

  initial begin
    // Default inputs.
    reset                           = 1'b1;
    beats_per_measure_minute_switcher = 1'b0;
    bpm_button_up                   = 1'b0;
    bpm_button_down                 = 1'b0;
    beats_per_measure_button_up     = 1'b0;
    beats_per_measure_button_down   = 1'b0;
    metronome_activate_button       = 1'b0;

    // Enable waveform dumps for GTKWave/Simvision.
    $dumpfile("metronome_TB.vcd");
    $dumpvars(0, metronome_TB);

    // Release reset and start the metronome.
    repeat (10) @(posedge clk);
    reset = 1'b0;

    repeat (20) @(posedge clk);
    press_button(metronome_activate_button);

    // Nudge BPM up and change beats-per-measure to exercise UI controls.
    press_button(bpm_button_up);
    press_button(bpm_button_up);

    // Toggle the BPM/TS display switch for a short time.
    repeat (500) @(posedge clk);
    beats_per_measure_minute_switcher = 1'b1;
    repeat (500) @(posedge clk);
    beats_per_measure_minute_switcher = 1'b0;

    // Adjust BPM down and keep running long enough to see several measures.
    repeat (400) @(posedge clk);
    press_button(bpm_button_down);

    repeat (600_000) @(posedge clk);
    $display("Simulation finished after several downbeats.");
    $finish;
  end

endmodule
