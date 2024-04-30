
module puf_wrap
import ariane_pkg::*;
#(
  parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
  input  logic                            clk_i,
  input  logic                            rst_ni,
  input  logic                            flush_i,
  input  fu_data_t                        fu_data_i,
  input  logic                            puf_valid_i,
  output riscv::xlen_t                    result_o,

  output logic                            puf_valid_o,
  output logic                            puf_ready_o,
  output logic        [TRANS_ID_BITS-1:0] puf_trans_id_o,
);

  enum logic {
    READY,
    STALL
  } state_q, state_d;

  logic puf_valid;
  logic puf_ready_i;  // receiver of division result is able to accept the result

  logic puf_valid_op;
  assign puf_valid_op = ~flush_i && puf_valid_i && (fu_data_i.operation inside { PUFC });

  assign puf_ready_i = 1'b1;

  puf_test #(
    .XLEN(64)
  ) puf_test_inst (
    .clk_i            (clk_i),
    .rst_ni           (rst_ni),
    .trans_id_i       (fu_data_i.trans_id),
    .valid_i          (puf_valid_op),
    .operand_i        (fu_data_i.operand_a),
    .op_ssm3_p0       (0),
    .op_ssm3_p1       (1),
    .result_o         (result_o),
    .puf_ready_o      (puf_ready_o),
    .puf_trans_id_o   (puf_trans_id_o)
  );

  always_comb begin :
    puf_valid_o = 1'b0;
    puf_ready_o = 1'b1;
    state_d = state_q;

    case (state_q)
      READY: begin
        if (puf_valid_op) begin
          puf_valid_o = 1'b1;
          puf_ready_o = 1'b0;
          state_d = STALL;
        end
      end
      STALL: begin
        if (puf_ready_i) begin
          puf_ready_o = 1'b1;
          state_d = READY;
        end
      end
    endcase
  end

  // registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      state_q <= READY;
      puf_valid <= '0;
    end else begin
      state_q <= state_d;
      puf_valid <= puf_valid_op;
    end
  end

endmodule
