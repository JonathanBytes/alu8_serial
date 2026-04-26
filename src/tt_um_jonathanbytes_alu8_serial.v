/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_jonathanbytes_alu8_serial (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire carry_out, zero, negative, overflow, done;

  // Instantiate the ALU
  alu8_serial alu_inst (
      .CLK(clk),
      .RST_n(rst_n),
      .Bit_in(ui_in[0]),
      .Carry_in(ui_in[4]),
      .op(ui_in[3:1]),
      .Data_out(uo_out),
      .Carry_out(carry_out),
      .Zero(zero),
      .Negative(negative),
      .Overflow(overflow),
      .Done(done)
  );

  // Assign bidirectional outputs
  assign uio_out[0] = carry_out;
  assign uio_out[1] = zero;
  assign uio_out[2] = negative;
  assign uio_out[3] = overflow;
  assign uio_out[4] = done;
  assign uio_out[7:5] = 3'b000;

  // Set uio pins 0 to 4 as outputs, others as inputs (or outputs driven to 0)
  // Let's set all uio as outputs since we don't use them as inputs
  assign uio_oe = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:5], uio_in};

endmodule
