module button_logic (
    input  logic clk,
    input  logic reset,
    input  logic button_in,
    output logic button_out
);

  parameter int MAX_COUNT = 1_000_000;

  logic button_ff1, button_ff2;
  logic button_prev;
  logic [31:0] count;

  // 2-flop synchronizer
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      button_ff1 <= 0;
      button_ff2 <= 0;
    end else begin
      button_ff1 <= button_in;
      button_ff2 <= button_ff1;
    end
  end

  // Debouncer + 1-cycle rising edge pulse
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count <= 0;
      button_prev <= 0;
      button_out <= 0;
    end else begin
      button_out <= 0;

      if (button_ff2 == button_prev) begin
        count <= 0;
      end else if (count == MAX_COUNT) begin
        button_prev <= button_ff2;
        if (button_ff2 == 1) button_out <= 1;  // <-- 1 clock pulse
        count <= 0;
      end else begin
        count <= count + 1;
      end
    end
  end
endmodule
