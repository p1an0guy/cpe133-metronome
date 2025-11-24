`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2025 12:38:21 PM
// Design Name: 
// Module Name: seven_seg_display
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

// What I need
//   - bpm[7:0]     : tempo in BPM
//   - ts[4:0]      : beats per measure (time signature)
//   - show_ts      : 0 = show BPM; 1 = show TS
//   - downbeat     : 1-clock pulse at the first beat of each measure


module seven_seg_display (
  input  logic        clk,        
  input  logic [7:0]  bpm,        
  input  logic [4:0]  ts,         // (time signature, beats per measure)
  input  logic        show_ts,    // 0=BPM, 1=TS
  input  logic        downbeat,   // 1-cycle pulse on measure start
  output logic [15:0] led,        // board LEDs (active-high)
  output logic [3:0]  an,         // 7-seg anodes (active-low)
  output logic [6:0]  seg,        // 7-seg segments a..g (active-low)
  output logic        dp          // 7-seg dp (active-low) (off)
);

  seg7_frontend_min u_front (
    .clk(clk),
    .bpm(bpm),
    .ts(ts),
    .show_ts(show_ts),
    .downbeat(downbeat),
    .led(led),
    .an(an), .seg(seg), .dp(dp)
  );
endmodule


module seg7_frontend_min (
  input  logic        clk,        // 100 MHz
  input  logic [7:0]  bpm,        
  input  logic [4:0]  ts,         // (time signature)
  input  logic        show_ts,    // 0=BPM, 1=TS
  input  logic        downbeat,   // 1-cycle pulse on measure start

  output logic [15:0] led,        // LEDs flash on downbeat
  output logic [3:0]  an,         // seven-seg anodes (active-low)
  output logic [6:0]  seg,        // seven-seg segments a..g (active-low)
  output logic        dp          // seven-seg dp (active-low)
);


// bcd_u8  (Binary to Hundreds/Tens/Ones)
module bcd_u8 (
  input  logic [7:0] bin,
  output logic [3:0] hund, tens, ones
);
  logic [7:0] q;

  always_comb begin
    // hundreds
    if (bin >= 8'd200)
        hund = 4'd2;
    else if (bin >= 8'd100) 
        hund = 4'd1;
    else                    
        hund = 4'd0;

    // remainder after removing hundreds
    if (hund == 4'd2)       
        q = bin - 8'd200;
    else if (hund == 4'd1)  
        q = bin - 8'd100;
    else                    
        q = bin;

    // tens
    if      (q >= 8'd90) tens = 4'd9;
    else if (q >= 8'd80) tens = 4'd8;
    else if (q >= 8'd70) tens = 4'd7;
    else if (q >= 8'd60) tens = 4'd6;
    else if (q >= 8'd50) tens = 4'd5;
    else if (q >= 8'd40) tens = 4'd4;
    else if (q >= 8'd30) tens = 4'd3;
    else if (q >= 8'd20) tens = 4'd2;
    else if (q >= 8'd10) tens = 4'd1;
    else                  tens = 4'd0;

    // ones
    ones = q - (tens * 8'd10);
  end
endmodule


// display_format_bpm_or_ts  (BPM/TS to Four Decimal Digits)
module display_format_bpm_or_ts (
  input  logic [7:0] bpm,
  input  logic [4:0] ts,
  input  logic       show_ts,
  output logic [3:0] d3, d2, d1, d0
);
  logic [3:0] h,t,o, ts_t, ts_o;
  bcd_u8 u_bpm (.bin(bpm), .hund(h), .tens(t), .ones(o));
  bcd_u8 u_ts  (.bin({3'b0, ts}), .hund(),  .tens(ts_t), .ones(ts_o));

  always_comb begin
    if (!show_ts) begin
      // [blank][hundreds][tens][ones]
      d3 = 4'hF; d2 = h;   d1 = t;   d0 = o;
    end else begin
      // [blank][blank][TS tens][TS ones]
      d3 = 4'hF; d2 = 4'hF; d1 = ts_t; d0 = ts_o;
    end
  end
endmodule

  // backend values to 4 BCD digits (leftto right: d3 d2 d1 d0)
  logic [3:0] d3, d2, d1, d0;
  display_format_bpm_or_ts u_fmt (
    .bpm(bpm), .ts(ts), .show_ts(show_ts),
    .d3(d3), .d2(d2), .d1(d1), .d0(d0)
  );
  
  
//  Uses a 17-bit timer to get ~1ms per digit at 100 MHz.
//  Cycles digit_select = 0..3 -> selects ones/tens/hundreds/thousands.
//  For each digit, turns on the correct anode 
module seg7_control_case(
    input  logic       clk_100MHz,
    input  logic       reset,
    input  logic [3:0] ones,       // rightmost digit
    input  logic [3:0] tens,
    input  logic [3:0] hundreds,
    input  logic [3:0] thousands,  // leftmost digit
    output logic [6:0] seg,        // segments a..g (ACTIVE-LOW)
    output logic [3:0] digit,      // anodes (ACTIVE-LOW)
    output logic       dp          // decimal point (ACTIVE-LOW)
);


    // 2-bit counter selects which of the 4 digits is active
    logic [1:0] digit_select;
    // counter to divide 100 MHz down to ~1 ms
    logic [16:0] digit_timer;  // up to 99_999 (17 bits)

    // Clock divider and digit index
    always_ff @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            digit_select <= 2'd0;
            digit_timer  <= 17'd0;
        end else begin
            // 10 ns * 100_000 = 1 ms at 100 MHz
            if (digit_timer == 17'd99_999) begin
                digit_timer  <= 17'd0;
                digit_select <= digit_select + 2'd1; 
            end else begin
                digit_timer <= digit_timer + 17'd1;
            end
        end
    end

    // Select which anode to turn on (ACTIVE-LOW)
    always_comb begin
        // default all off
        digit = 4'b1111;
        case (digit_select)
            2'b00: digit = 4'b1110; // ones 
            2'b01: digit = 4'b1101; // tens
            2'b10: digit = 4'b1011; // hundreds
            2'b11: digit = 4'b0111; // thousands 
            default: digit = 4'b1111;
        endcase
    end

    // Pick which nibble to show and map 0-9 
    logic [3:0] cur_digit;

    always_comb begin
        // choose current digit's value based on digit_select
        case (digit_select)
            2'b00: cur_digit = ones;
            2'b01: cur_digit = tens;
            2'b10: cur_digit = hundreds;
            2'b11: cur_digit = thousands;
            default: cur_digit = 4'hF; // blank
        endcase

        // map nibble to active-low seven-seg pattern
        unique case (cur_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

    // Decimal point off
    assign dp = 1'b1; 

endmodule


  seg7_control_case u_disp (
    .clk_100MHz(clk),
    .reset      (1'b0),   
    .ones       (d0),
    .tens       (d1),
    .hundreds   (d2),
    .thousands  (d3),
    .seg        (seg),
    .digit      (an),
    .dp         (dp)
  );

  // LED FLASH: stretch downbeat so LEDs visibly blink
  led_flash_on_pulse #(
    .FLASH_MS(120),
    .CLK_HZ(100_000_000),
    .LEDS(16),
    .MASK(16'hFFFF)
  ) u_ledflash (
    .clk     (clk),
    .pulse_in(downbeat),
    .led_out (led)
  );
endmodule



module led_flash_on_pulse #(
  parameter int FLASH_MS = 120,
  parameter int CLK_HZ   = 100_000_000,
  parameter int LEDS     = 16,
  parameter int MASK     = 16'hFFFF
)(
  input  logic            clk,
  input  logic            pulse_in,       // 1-cycle pulse at clk
  output logic [LEDS-1:0] led_out
);
  localparam int CYCLES = FLASH_MS * (CLK_HZ/1000);
  logic [$clog2(CYCLES+1)-1:0] tmr;

  always_ff @(posedge clk) begin
    if (pulse_in)      tmr <= CYCLES[$clog2(CYCLES+1)-1:0];
    else if (tmr != 0) tmr <= tmr - 1'b1;
  end

  always_comb begin
    led_out = (tmr != 0) ? MASK[LEDS-1:0] : '0;
  end
endmodule


