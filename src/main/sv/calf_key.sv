/*
 * File: calf_key.sv                                                           *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 07:00:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 11:30:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Memory-mapped read-only key: the DATA register returns KEY, a  *
 * value set when the design is built (e.g. a bitstream generic), and absent   *
 * from the software. Writes are ignored. Reads are decoded on the word: a     *
 * byte access (e.g. the bootloader DUMP) returns the whole word, and the      *
 * reader selects its byte lane.                                               *
 */


module calf_key
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_addr_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int                       DATA_BIT_N = 32,
    parameter logic [DATA_BIT_N - 1:0]  KEY = 'h0,

    localparam int                      DATA_BYTE_N = DATA_BIT_N / 8
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                         clk_i,
    input logic                         rst_i,

    output logic                        mem_ready_o,
    input logic                         mem_valid_i,
    input logic [KEY_ADDR_N_BIT - 1:0]  mem_addr_i,
    input logic [DATA_BYTE_N - 1:0]     mem_wmask_i,
    input logic [DATA_BIT_N - 1:0]      mem_wdata_i,
    output logic                        mem_rready_o,
    output logic [DATA_BIT_N - 1:0]     mem_rdata_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic rready_r;
  logic [DATA_BIT_N - 1:0] rdata_r;
  logic rready_n;
  logic [DATA_BIT_N - 1:0] rdata_n;
  logic [KEY_ADDR_N_BIT - 1:0] word_addr_w;
  logic unused_write_w;

// *****************************************************************************
// * READ
// *****************************************************************************
  // Byte lane bits cleared: the 4 bytes of a register return the same word
  always_comb begin
    word_addr_w = mem_addr_i & ~(KEY_ADDR_N_BIT)'(DATA_BYTE_N - 1);
  end

  always_comb begin
    rready_n = mem_valid_i && (mem_wmask_i == 'h0);
    case (word_addr_w)
      KEY_ADDR_OFFSET_DATA: begin
        rdata_n = KEY;
      end
      default: begin
        rdata_n = 'h0;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rready_r <= 1'b0;
      rdata_r <= 'h0;
    end else begin
      rready_r <= rready_n;
      rdata_r <= rdata_n;
    end
  end

  always_comb begin
    mem_ready_o = 1'b1;
    mem_rready_o = rready_r;
    mem_rdata_o = rdata_r;
  end

// *****************************************************************************
// * WRITE
// *****************************************************************************
  // Read-only
  always_comb begin
    unused_write_w = |{mem_wmask_i, mem_wdata_i};
  end
endmodule
