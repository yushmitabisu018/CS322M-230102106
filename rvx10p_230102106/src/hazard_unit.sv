// If EX stage is performing a load and its destination register matches
// either source register in ID stage, request a one-cycle stall and bubble.

module hazard_unit(
  input  logic       MemReadE,
  input  logic [4:0] RdE,
  input  logic [4:0] Rs1D,
  input  logic [4:0] Rs2D,
  output logic      stallF,
  output logic      stallD,
  output logic      flushE
);

  // single combinational expression that captures the hazard condition
  logic load_use_hazard;
  assign load_use_hazard = MemReadE && ( (RdE == Rs1D) || (RdE == Rs2D) );

  // drive outputs from the computed condition
  assign stallF = load_use_hazard;
  assign stallD = load_use_hazard;
  assign flushE = load_use_hazard;

endmodule
