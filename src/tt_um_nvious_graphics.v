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
	wire _unused_ok = &{ena, uio_in};

	reg show;
	reg [9:0] counter;
	wire [7:0] led = show ? ui_in : countdown[counter[8:5]];

	reg [7:0] countdown[15:0];
	initial begin
		countdown  = 8'b01110011; // P
		countdown  = 8'b00000110; // I
		countdown  = 8'b00111000; // L
		countdown  = 8'b00000110; // I
		countdown  = 8'b01110011; // P
		countdown  = 8'b00000110; // I
		countdown  = 8'b00110111; // N
		countdown  = 8'b01110111; // A
		countdown  = 8'b01101101; // S
		countdown  = 8'b00111000; // L
		countdown = 8'b01110111; // A
		countdown = 8'b01101101; // S
		countdown = 8'b01110111; // A
		countdown = 8'b00111000; // L
		countdown = 8'b00111000; // L
		countdown = 8'b01111001; // E
	end

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

	// Original 7-Segment On-Screen Spatial Intersection Boundaries
	wire a0 = y > 7;
	wire a1 = x < y + 392;
	wire a2 = 454 - x > y;
	wire a3 = y < 56;
	wire a4 = x > y + 185;
	wire a5 = x > 247 - y;
	wire a = a0 & a1 & a2 & a3 & a4 & a5;

	wire b0 = a1;
	wire b1 = x < 448;
	wire b2 = 662 - x > y;
	wire b3 = a4;
	wire b4 = x > 399;
	wire b5 = 455 - x < y;
	wire b = b0 & b1 & b2 & b3 & b4 & b5;

	wire c0 = x < y + 184;
	wire c1 = b1;
	wire c2 = 872 - x > y;
	wire c3 = x + 23 > y;
	wire c4 = b4;
	wire c5 = 663 - x < y;
	wire c = c0 & c1 & c2 & c3 & c4 & c5;

	wire d0 = y > 423;
	wire d1 = y > x + 24; 
	wire d2 = c2;
	wire d3 = y < 472;
	wire d4 = x > y - 232;
	wire d5 = c5;
	wire d = d0 & d1 & d2 & d3 & d4 & d5;

	wire e0 = d1;
	wire e1 = x < 240;
	wire e2 = b2;
	wire e3 = d4;
	wire e4 = x > 191;
	wire e5 = b5;
	wire e = e0 & e1 & e2 & e3 & e4 & e5;

	wire f0 = c0;
	wire f1 = e1;
	wire f2 = a2;
	wire f3 = c3;
	wire f4 = e4;
	wire f5 = a5;
	wire f = f0 & f1 & f2 & f3 & f4 & f5;

	wire g0 = y > 215;
	wire g1 = c0;
	wire g2 = b2;
	wire g3 = y < 262;
	wire g4 = f3;
	wire g5 = e5;
	wire g = g0 & g1 & g2 & g3 & g4 & g5;

	// Bounding box layout for segment h (decimal point)
	wire h = (x >= 480) && (x <= 544) && (y >= 408) && (y <= 472); 

	wire [5:0] black  = 6'b000000;
	wire [5:0] cyan   = 6'b011111;

	wire [5:0] fg = cyan;

	// Gated Video Multiplexer Output
	assign RGB = video_active ? (((a & led) | (b & led) | (c & led) | (d & led) | (e & led) | (f & led) | (g & led) | (h & led)) ? fg : black) : black;

	always @(posedge vsync, negedge rst_n) begin
		if (~rst_n) begin
			show <= 0;
			counter <= 0;
		end else begin
			show <= show | ui_in | ui_in | ui_in | ui_in | ui_in | ui_in | ui_in | ui_in;
			counter <= counter + 1;
		end
	end

endmodule

