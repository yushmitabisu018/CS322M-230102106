// Priority: forward from M stage if available, otherwise from W stage.

module forwarding_unit(
  input  logic [4:0] Rs1E,
  input  logic [4:0] Rs2E,
  input  logic [4:0] RdM,
  input  logic [4:0] RdW,
  input  logic       RegWriteM,
  input  logic       RegWriteW,
  output logic [1:0] ForwardA,
  output logic [1:0] ForwardB
);

  // encoding for forwarding selections
  localparam logic [1:0] F_NONE = 2'b00;
  localparam logic [1:0] F_MEM  = 2'b01; // forward from EX/MEM
  localparam logic [1:0] F_WB   = 2'b10; // forward from MEM/WB

  // detect matches for each source operand
  logic matchM_rs1, matchW_rs1;
  logic matchM_rs2, matchW_rs2;

  assign matchM_rs1 = RegWriteM && (RdM != 5'd0) && (RdM == Rs1E);
  assign matchW_rs1 = RegWriteW && (RdW != 5'd0) && (RdW == Rs1E);

  assign matchM_rs2 = RegWriteM && (RdM != 5'd0) && (RdM == Rs2E);
  assign matchW_rs2 = RegWriteW && (RdW != 5'd0) && (RdW == Rs2E);

  // choose forwarding source with M-stage having higher priority than W-stage
  assign ForwardA = matchM_rs1 ? F_MEM : (matchW_rs1 ? F_WB : F_NONE);
  assign ForwardB = matchM_rs2 ? F_MEM : (matchW_rs2 ? F_WB : F_NONE);

endmodule
