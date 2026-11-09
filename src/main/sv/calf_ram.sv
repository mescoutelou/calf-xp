/*
 * File: calf_ram.sv                                                           *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 08:05:18 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Synchronous RAM with byte write mask, PORT_N ports and one-    *
 * cycle read latency. Initialized from RAM_FILE (word hex file: objcopy -O    *
 * verilog --verilog-data-width=DATA_BYTE_N), or with ext_readmemh (DPI-C,     *
 * byte hex file: objcopy -O verilog) in Verilator.                            *
 */


module calf_ram
// *****************************************************************************
// * PACKAGE
// *****************************************************************************

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter string  RAM_FILE = "",
    parameter int     RAM_DATA_N = 1024,
    parameter int     DATA_BYTE_N = 4,
    parameter int     PORT_N = 1,

    localparam int    DATA_BIT_N = DATA_BYTE_N * 8,
    localparam int    RAM_ADDR_N_BIT = $clog2(RAM_DATA_N)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                                       clk_i,
    input logic                                       rst_i,
    
    output logic [PORT_N - 1:0]                       mem_ready_o,
    input logic [PORT_N - 1:0]                        mem_valid_i,
    input logic [PORT_N - 1:0][RAM_ADDR_N_BIT - 1:0]  mem_addr_i,
    input logic [PORT_N - 1:0][DATA_BYTE_N - 1:0]     mem_wmask_i,
    input logic [PORT_N - 1:0][DATA_BIT_N - 1:0]      mem_wdata_i,
    output logic [PORT_N - 1:0]                       mem_rready_o,
    output logic [PORT_N - 1:0][DATA_BIT_N - 1:0]     mem_rdata_o
  );

// *****************************************************************************
// * CHECK
// *****************************************************************************
  generate
    if (PORT_N < 1) begin : port_n_min_g
      $error("calf_ram: PORT_N must be at least 1");
    end

    `ifdef SYNTHESIS
      if (PORT_N > 2) begin : port_n_max_g
        $error("calf_ram: PORT_N above 2 is only supported in simulation");
      end
    `endif
  endgenerate

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [DATA_BYTE_N * 8 - 1: 0] mem_r [RAM_DATA_N - 1:0];
  logic [7:0] mem_z [RAM_DATA_N * DATA_BYTE_N];

  logic [PORT_N - 1:0] rready_r;
  logic [PORT_N - 1:0][DATA_BIT_N - 1:0] rdata_r;

// *****************************************************************************
// * FILE INIT
// *****************************************************************************
  // Read directly in mem_r: Vivado ignores the copy from a byte array at
  // elaboration, so RAM_FILE holds DATA_BYTE_N-byte words.
  initial begin
    if (RAM_FILE != "") begin
      for (int d = 0; d < RAM_DATA_N; d = d + 1) begin
        mem_r[d] = 'h0;
      end

      $readmemh(RAM_FILE, mem_r);
    end
  end

  `ifdef verilator
    export "DPI-C" task ext_readmemh;

    task ext_readmemh;
      input string TASK_INITFILE;

      for (int b = 0; b < RAM_DATA_N * DATA_BYTE_N; b = b + 1) begin
        mem_z[b] = 'h0;
      end

      $readmemh(TASK_INITFILE, mem_z);

      for (int d = 0; d < RAM_DATA_N; d = d + 1) begin
        for (int db = 0; db < DATA_BYTE_N; db = db + 1) begin
          mem_r[d][db*8 +: 8] = mem_z[d * DATA_BYTE_N + db];
        end
      end
    endtask
  `endif

// *****************************************************************************
// * WRITE
// *****************************************************************************
  generate
    for (genvar p = 0; p < PORT_N; p = p + 1) begin : write_g
      always_ff @(posedge clk_i) begin
        if (!rst_i) begin
          for (int db = 0; db < DATA_BYTE_N; db = db + 1) begin
            if (mem_valid_i[p] && mem_wmask_i[p][db]) begin
              mem_r[mem_addr_i[p]][db*8 +: 8] <= mem_wdata_i[p][db*8 +: 8];
            end
          end
        end
      end
    end
  endgenerate

// *****************************************************************************
// * READ
// *****************************************************************************
  generate
    for (genvar p = 0; p < PORT_N; p = p + 1) begin : read_g
      always_ff @(posedge clk_i) begin
        if (rst_i) begin
          rready_r[p] <= 1'b0;
          rdata_r[p] <= 'h0;
        end else begin
          rready_r[p] <= mem_valid_i[p] && (mem_wmask_i[p] == 'h0);
          if (mem_valid_i[p]) begin
            rdata_r[p] <= mem_r[mem_addr_i[p]];
          end
        end
      end

      always_comb begin
        mem_ready_o[p] = 1'b1;
        mem_rready_o[p] = rready_r[p];
        mem_rdata_o[p] = rdata_r[p];
      end
    end
  endgenerate
endmodule
