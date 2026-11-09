/*
 * File: calf_gpio.sv                                                          *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-26 04:06:31 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Memory-mapped 8-bit GPIO: ENO (output enables), IN (inputs,    *
 * synchronized on 2 flip-flops) and OUT (outputs) registers.                  *
 */


module calf_gpio
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_addr_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   DATA_BIT_N = 32,

    localparam int  DATA_BYTE_N = DATA_BIT_N / 8
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                         clk_i,
    input logic                         rst_i,

    output logic                        mem_ready_o,
    input logic                         mem_valid_i,
    input logic [GPIO_ADDR_N_BIT - 1:0] mem_addr_i,
    input logic [DATA_BYTE_N - 1:0]     mem_wmask_i,
    input logic [DATA_BIT_N - 1:0]      mem_wdata_i,
    output logic                        mem_rready_o,
    output logic [DATA_BIT_N - 1:0]     mem_rdata_o,

    output logic [7:0]                  eno_o,
    input logic [7:0]                   in_i,
    output logic [7:0]                  out_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [7:0] eno_r, eno_n;
  logic [1:0][7:0] in_r, in_n;
  logic [7:0] out_r, out_n;
  logic rready_r, rready_n;
  logic [DATA_BIT_N - 1:0] rdata_r, rdata_n;

// *****************************************************************************
// * READ
// *****************************************************************************
  always_comb begin
    rready_n = mem_valid_i && (mem_wmask_i == 'h0);
    case (mem_addr_i)
      GPIO_ADDR_OFFSET_ENO: begin
        rdata_n = {{(DATA_BIT_N - 8){1'b0}}, eno_r};
      end
      GPIO_ADDR_OFFSET_IN: begin
        rdata_n = {{(DATA_BIT_N - 8){1'b0}}, in_r[1]};
      end
      GPIO_ADDR_OFFSET_OUT: begin
        rdata_n = {{(DATA_BIT_N - 8){1'b0}}, out_r};
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
  always_comb begin
    eno_n = eno_r;
    out_n = out_r;

    if (mem_valid_i) begin
      case (mem_addr_i)
        GPIO_ADDR_OFFSET_ENO: begin
          if (mem_wmask_i[0]) begin
            eno_n = mem_wdata_i[7:0];
          end
        end
        GPIO_ADDR_OFFSET_OUT: begin
          if (mem_wmask_i[0]) begin
            out_n = mem_wdata_i[7:0];
          end
        end
        default: begin
          
        end
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      eno_r <= 'h0;
      out_r <= 'h0;
    end else begin
      eno_r <= eno_n;
      out_r <= out_n;
    end
  end

// *****************************************************************************
// * GPIO
// *****************************************************************************
  always_comb begin
    in_n[0] = in_i;
    in_n[1] = in_r[0];
  end

  always_comb begin
    eno_o = eno_r;
    out_o = out_r;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      in_r[0] <= 'h0;
      in_r[1] <= 'h0;
    end else begin
      in_r[0] <= in_n[0];
      in_r[1] <= in_n[1];
    end
  end
endmodule
