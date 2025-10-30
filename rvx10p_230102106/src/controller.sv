// Combinational decode used by ID stage. Produces ID/EX control fields.
module controller(
  input  logic [6:0] opcode,
  output logic       RegWrite,
  output logic       MemWrite,
  output logic       MemToReg,
  output logic       ALUSrc,
  output logic       Branch,
  output logic       Jump,
  output logic [1:0] ALUOp,
  output logic [1:0] ImmSrc,
  output logic [1:0] ResultSrc
);

  // opcode constants (named for clarity)
  localparam logic [6:0] OP_LW     = 7'b0000011;
  localparam logic [6:0] OP_SW     = 7'b0100011;
  localparam logic [6:0] OP_RTYPE  = 7'b0110011;
  localparam logic [6:0] OP_ITYPE  = 7'b0010011;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_RVX10  = 7'b0001011; // CUSTOM-0

  // compact container for control signals
  typedef struct packed {
    logic       regw;
    logic       memw;
    logic       memtoreg;
    logic       alusrc;
    logic       branch;
    logic       jump;
    logic [1:0] aluop;
    logic [1:0] immsrc;
    logic [1:0] ressrc;
  } ctrl_t;

  ctrl_t ctrl;

  // combinational decode
  always_comb begin
    // default values (safe reset state)
    ctrl = '0;
    ctrl.aluop  = 2'b00;
    ctrl.immsrc = 2'b00;
    ctrl.ressrc = 2'b00;

    unique case (opcode)
      OP_LW: begin
        // load word: ALU computes address, read from memory -> write reg
        ctrl.regw     = 1;
        ctrl.alusrc   = 1;
        ctrl.memtoreg = 1;
        ctrl.ressrc   = 2'b01; // memory result
        ctrl.immsrc   = 2'b00; // I-type imm
        ctrl.aluop    = 2'b00; // add
      end

      OP_SW: begin
        // store word: ALU computes address, write memory
        ctrl.memw   = 1;
        ctrl.alusrc = 1;
        ctrl.immsrc = 2'b01; // S-type imm
        ctrl.aluop  = 2'b00; // add
      end

      OP_RTYPE: begin
        // register-register ALU
        ctrl.regw   = 1;
        ctrl.alusrc = 0;
        ctrl.aluop  = 2'b10; // function-select ALU
        ctrl.immsrc = 2'b00;
        ctrl.ressrc = 2'b00; // ALU result
      end

      OP_ITYPE: begin
        // immediate ALU (addi, etc.)
        ctrl.regw   = 1;
        ctrl.alusrc = 1;
        ctrl.aluop  = 2'b10;
        ctrl.immsrc = 2'b00;
        ctrl.ressrc = 2'b00;
      end

      OP_BRANCH: begin
        // conditional branches
        ctrl.branch = 1;
        ctrl.aluop  = 2'b01; // branch comparator ALU
        ctrl.immsrc = 2'b10; // B-type imm
      end

      OP_JAL: begin
        // jump and link (PC+4 -> rd)
        ctrl.regw   = 1;
        ctrl.jump   = 1;
        ctrl.ressrc = 2'b10; // PC+imm result source
        ctrl.immsrc = 2'b11; // J-type imm
      end

      OP_JALR: begin
        // jump and link register (rd = PC+4), compute target with ALU
        ctrl.regw   = 1;
        ctrl.jump   = 1;
        ctrl.alusrc = 1;
        ctrl.ressrc = 2'b10;
        ctrl.immsrc = 2'b00; // I-type imm (jalr uses I-type)
        ctrl.aluop  = 2'b00;
      end

      OP_RVX10: begin
        // CUSTOM-0 RVX10: treat as R-type ALU instruction
        ctrl.regw   = 1;
        ctrl.alusrc = 0;
        ctrl.aluop  = 2'b10;
        ctrl.immsrc = 2'b00;
        // ressrc default (ALU result)
      end

      default: begin
      end
    endcase
  end

  // expose fields as outputs
  assign RegWrite  = ctrl.regw;
  assign MemWrite  = ctrl.memw;
  assign MemToReg  = ctrl.memtoreg;
  assign ALUSrc    = ctrl.alusrc;
  assign Branch    = ctrl.branch;
  assign Jump      = ctrl.jump;
  assign ALUOp     = ctrl.aluop;
  assign ImmSrc    = ctrl.immsrc;
  assign ResultSrc = ctrl.ressrc;

endmodule
