/*
 * Copyright (c) 2024-2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_nvious_graphics(
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	// VGA signals
	wire hsync;
	wire vsync;
	wire [5:0] RGB;
	wire video_active;
	wire [9:0] x;
	wire [9:0] y;

	// TinyVGA PMOD formatted with exact spacing constraints
	assign uo_out = {hsync, RGB [ 0 ], RGB [ 2 ], RGB [ 4 ], vsync, RGB [ 1 ], RGB [ 3 ], RGB [ 5 ]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	// Suppress unused signals warning
	wire _unused_ok = &{ena, uio_in, ui_in};

	// Expanded 28-bit clock divider to handle safe, slow on-screen letter transitions
	reg [27:0] slow_counter;
	
	// Combinational ROM lookup for PILIPINASLASALLE based on top bits of the divider
	reg [7:0] countdown_val;
	always @* begin
		case (slow_counter[27:24])
			4'd0:  countdown_val = 8'b01110011; // P
			4'd1:  countdown_val = 8'b00000110; // I
			4'd2:  countdown_val = 8'b00111000; // L
			4'd3:  countdown_val = 8'b00000110; // I
			4'd4:  countdown_val = 8'b01110011; // P
			4'd5:  countdown_val = 8'b00000110; // I
			4'd6:  countdown_val = 8'b00110111; // N
			4'd7:  countdown_val = 8'b01110111; // A
			4'd8:  countdown_val = 8'b01101101; // S
			4'd9:  countdown_val = 8'b00111000; // L
			4'd10: countdown_val = 8'b01110111; // A
			4'd11: countdown_val = 8'b01101101; // S
			4'd12: countdown_val = 8'b01110111; // A
			4'd13: countdown_val = 8'b00111000; // L
			4'd14: countdown_val = 8'b00111000; // L
			4'd15: countdown_val = 8'b01111001; // E
			default: countdown_val = 8'b00000000;
		endcase
	end

	wire [7:0] led = countdown_val;

	// VGA output
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(video_active),
		.hpos(x),
		.vpos(y)
	);

	// Centered Bounding Box Grid Mapping for Standard 640x480 Layout
	// This keeps segments flawlessly separated regardless of structural porch variations.
	wire a = (x >= 240) && (x <= 400) && (y >= 100) && (y <= 130);  // Top
	wire b = (x >= 370) && (x <= 400) && (y >= 130) && (y <= 230);  // Top-Right
	wire c = (x >= 370) && (x <= 400) && (y >= 250) && (y <= 350);  // Bottom-Right
	wire d = (x >= 240) && (x <= 400) && (y >= 350) && (y <= 380);  // Bottom
	wire e = (x >= 240) && (x <= 270) && (y >= 250) && (y <= 350);  // Bottom-Left
	wire f = (x >= 240) && (x <= 270) && (y >= 130) && (y <= 230);  // Top-Left
	wire g = (x >= 240) && (x <= 400) && (y >= 230) && (y <= 250);  // Middle
	wire h = (x >= 420) && (x <= 450) && (y >= 350) && (y <= 380);  // Decimal Dot

	wire [5:0] black = 6'b000000;
	wire [5:0] cyan  = 6'b011111;

	wire [5:0] bg = black;
	wire [5:0] fg = cyan;
	
	// Gated Video Multiplexer Output
	assign RGB = video_active ? (((a & led) | (b & led) | (c & led) | (d & led) | (e & led) | (f & led) | (g & led) | (h & led)) ? fg : bg) : black;

	// Stable system clock-driven sequential block
	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			slow_counter <= 0;
		end else begin
			slow_counter <= slow_counter + 1;
		end
	end

endmodule
