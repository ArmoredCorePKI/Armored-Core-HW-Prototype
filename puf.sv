module puf_test #(
  parameter XLEN          = 64  // Must be one of: 32, 64.
  )(

  input  logic                     clk_i           , // Global clock
  input  logic                     rst_ni          , // Synchronous active low reset.
  input  logic [TRANS_ID_BITS-1:0] trans_id_i      , // Transaction ID.
  input  logic                     valid_i         , // Inputs valid.
  input  logic              [31:0] operand_i       , // Source register 1. Low 32 bits.

  input  logic                     op_ssm3_p0      , // SSM3 P0
  input  logic                     op_ssm3_p1      , // SSM3 P1

  output logic          [XLEN-1:0] result_o        , // Result.
  output logic                     puf_ready_o     , // Outputs ready.
  output logic [TRANS_ID_BITS-1:0] puf_trans_id_o
  );


  function logic [31:0] rol32(input logic [31:0] a, input int b);
    return (a << b) | (a >> (32 - b));
  endfunction

  logic [31:0] ssm3_p0;
  logic [31:0] ssm3_p1;
  logic [31:0] ssm3_low32;

  logic [TRANS_ID_BITS-1:0] trans_id_q;

  assign puf_ready_o = 1'b1;

  assign ssm3_p0 = operand_i ^ rol32(operand_i, 9) ^ rol32(operand_i, 17);
  assign ssm3_p1 = operand_i ^ rol32(operand_i,15) ^ rol32(operand_i, 23);

  assign ssm3_low32  =
      {32{op_ssm3_p0}} & ssm3_p0 |
      {32{op_ssm3_p1}} & ssm3_p1 ;

  assign result_o = {32'b0, ssm3_low32};

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      puf_valid_q  <= '0;
      trans_id_q   <= '0;
    end else begin
      puf_valid_q  <= valid_i;
      trans_id_q   <= trans_id_i;
    end
  end

endmodule

