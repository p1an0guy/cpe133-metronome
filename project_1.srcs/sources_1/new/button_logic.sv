`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2025 02:25:52 PM
// Design Name: 
// Module Name: button_logic
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


module button_logic(
    input logic clk,           // System clock
    input logic reset,       // Active-high reset
    input logic button_in,     // Raw button input from I/O pin
    output logic button_out    // Debounced single-cycle pulse output
);

    // Counter to measure stable time (adjust max_count based on clock frequency)
    // For a 50 MHz clock and a 20 ms debounce time, max_count = 50MHz * 20ms = 1,000,000
    parameter int MAX_COUNT = 1_000_000; 

    logic [31:0] count;
    logic [1:0]  state; // State machine: 00=idle, 01=debouncing_high, 10=debouncing_low, 11=stable
    logic        button_sync; // Synchronized button signal
    logic        button_reg; // Registered button state

    // Latch the input signal synchronously
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            button_reg <= 0;
        end else begin
            button_reg <= button_in;
            button_sync <= button_reg; // Double register for metastability protection
        end
    end

    // Debouncing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            state <= 2'b00;
            button_out <= 0;
        end else begin
            button_out <= 0; // Default to 0, only set high for one cycle on event

            case (state)
                2'b00: begin // Idle state
                    if (button_sync != button_reg) begin // Detect an edge
                        count <= 0;
                        state <= (button_sync == 1'b1) ? 2'b01 : 2'b10;
                    end
                end
                2'b01, 2'b10: begin // Debouncing high or low
                    if (count < MAX_COUNT) begin
                        count <= count + 1;
                    end else begin
                        state <= 2'b11; // Stable, move to stable state
                        count <= 0;
                    end
                end
                2'b11: begin // Stable state
                    if (button_sync != button_reg) begin // Detect next edge
                        state <= 2'b00; // Go back to idle/wait for next stable press
                        button_out <= 1; // Output a single-cycle pulse
                    end
                end
            endcase
        end
    end

endmodule