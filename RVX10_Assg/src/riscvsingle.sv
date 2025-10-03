// src/riscvsingle.sv
// -----------------------------------------------------------------------------
// RV32I Single-Cycle Core + RVX10 Extension (CUSTOM-0)
// Implements the base single-cycle datapath plus 10 custom ALU instructions
// defined in RVX10: ANDN, ORN, XNOR, MIN, MAX, MINU, MAXU, ROL, ROR, ABS.
// -----------------------------------------------------------------------------

module riscv_single (
    input  logic         clk,
    input  logic         reset,

    // Instruction + Data Memory interface
    output logic [31:0]  imem_addr,
    input  logic [31:0]  imem_rdata,
    
    // Data Memory (for RV32I loads/stores and final success check)
    output logic [31:0]  dmem_addr,
    output logic [31:0]  dmem_wdata,
    input  logic [31:0]  dmem_rdata,
    output logic         dmem_we
);

  // -------------------------------
  // Datapath Signals & Wires
  // -------------------------------
  logic [31:0] pc, pc_next;

  // Instruction Fields
  logic [6:0]  opcode;
  logic [4:0]  rd_idx, rs1_idx, rs2_idx;
  logic [2:0]  funct3;
  logic [6:0]  funct7;

  // Register File Wires
  logic [31:0] rs1_val, rs2_val, regfile_wdata;
  logic        regfile_we;
  logic [31:0] alu_result;
  
  // Signed versions for signed comparisons (MIN, MAX, ABS)
  logic signed [31:0] s1, s2;


  // -------------------------------
  // Program Counter (PC)
  // -------------------------------
  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      pc <= 32'h0;
    else
      pc <= pc_next;
  end

  assign imem_addr = pc; // Instruction Fetch Address

  // -------------------------------
  // Instruction Decode & Register File Read
  // -------------------------------
  assign opcode  = imem_rdata[6:0];
  assign rd_idx  = imem_rdata[11:7];
  assign funct3  = imem_rdata[14:12];
  assign rs1_idx = imem_rdata[19:15];
  assign rs2_idx = imem_rdata[24:20];
  assign funct7  = imem_rdata[31:25];

  // Register File (32 registers, x0 is hardwired to 0)
  logic [31:0] regfile [0:31];

  // Read Logic: x0 read returns 0 (RISC-V spec)
  assign rs1_val = regfile[rs1_idx];
  assign rs2_val = regfile[rs2_idx];

  // Write Logic: Ignore write to x0 (Required for RVX10 and RV32I) [cite: 31]
  always_ff @(posedge clk) begin
    if (reset) begin
      for (int i = 0; i < 32; i++) regfile[i] <= 32'b0;
    end else if (regfile_we && rd_idx != 0) begin // x0 writes ignored [cite: 31]
      regfile[rd_idx] <= regfile_wdata;
    end
  end

  // -------------------------------
  // ALU Operation Enumeration (Expanded for RVX10) 
  // -------------------------------
  typedef enum logic [4:0] {
    // RV32I Standard Ops
    ALU_NOP   = 5'h00, ALU_ADD   = 5'h01, ALU_SUB   = 5'h02,
    ALU_AND   = 5'h03, ALU_OR    = 5'h04, ALU_XOR   = 5'h05,
    ALU_SLT   = 5'h06, ALU_SLTU  = 5'h07, ALU_SLL   = 5'h08,
    ALU_SRL   = 5'h09, ALU_SRA   = 5'h0A,
    
    // RVX10 Custom Ops (Custom-0, opcode 0x0B)
    ALU_ANDN  = 5'h10, ALU_ORN   = 5'h11, ALU_XNOR  = 5'h12,
    ALU_MIN   = 5'h13, ALU_MAX   = 5'h14, ALU_MINU  = 5'h15,
    ALU_MAXU  = 5'h16, ALU_ROL   = 5'h17, ALU_ROR   = 5'h18,
    ALU_ABS   = 5'h19
  } alu_op_t;

  alu_op_t current_alu_op;

  // -------------------------------
  // Control Unit / Decode Logic
  // -------------------------------
  always_comb begin
    // Default control signals (for sequential PC advance)
    regfile_we     = 1'b0;
    dmem_we        = 1'b0;
    current_alu_op = ALU_NOP;
    pc_next        = pc + 4; // Default to sequential execution

    case (opcode)

      // ----------- RVX10 Custom (opcode = 0x0B) ----------
      7'b0001011: begin // CUSTOM-0 R-type [cite: 12]
        regfile_we = 1'b1; // All RVX10 ops write to RD [cite: 35, 70]
        dmem_we    = 1'b0; // No memory access 
        
        // Select ALU operation based on funct7 and funct3 [cite: 34]
        unique case ({funct7, funct3})
          // Logical Negation Ops (funct7=0000000)
          {7'b0000000, 3'b000}: current_alu_op = ALU_ANDN; // ANDN [cite: 25]
          {7'b0000000, 3'b001}: current_alu_op = ALU_ORN;  // ORN [cite: 25]
          {7'b0000000, 3'b010}: current_alu_op = ALU_XNOR; // XNOR [cite: 25]

          // Min/Max Ops (funct7=0000001)
          {7'b0000001, 3'b000}: current_alu_op = ALU_MIN;  // MIN (signed) [cite: 25]
          {7'b0000001, 3'b001}: current_alu_op = ALU_MAX;  // MAX (signed) [cite: 25]
          {7'b0000001, 3'b010}: current_alu_op = ALU_MINU; // MINU (unsigned) [cite: 25]
          {7'b0000001, 3'b011}: current_alu_op = ALU_MAXU; // MAXU (unsigned) [cite: 25]

          // Rotate Ops (funct7=0000010)
          {7'b0000010, 3'b000}: current_alu_op = ALU_ROL;  // ROL [cite: 25]
          {7'b0000010, 3'b001}: current_alu_op = ALU_ROR;  // ROR [cite: 25]

          // Unary Op (funct7=0000011)
          {7'b0000011, 3'b000}: current_alu_op = ALU_ABS;  // ABS [cite: 25]

          default: begin
            current_alu_op = ALU_NOP; // Illegal RVX10 encoding
            regfile_we     = 1'b0;
          end
        endcase
      end

      // ----------- Example RV32I opcodes (R-type and others) ----------
      7'b0110011: begin // Standard RV32I R-type
        regfile_we = 1'b1;
        // ... (rest of RV32I R-type logic)
        unique case ({funct7, funct3})
          {7'b0000000, 3'b000}: current_alu_op = ALU_ADD;
          {7'b0100000, 3'b000}: current_alu_op = ALU_SUB;
          {7'b0000000, 3'b111}: current_alu_op = ALU_AND;
          {7'b0000000, 3'b110}: current_alu_op = ALU_OR;
          {7'b0000000, 3'b100}: current_alu_op = ALU_XOR;
          {7'b0000000, 3'b010}: current_alu_op = ALU_SLT;
          {7'b0000000, 3'b011}: current_alu_op = ALU_SLTU;
          {7'b0000000, 3'b001}: current_alu_op = ALU_SLL;
          {7'b0000000, 3'b101}: current_alu_op = ALU_SRL;
          {7'b0100000, 3'b101}: current_alu_op = ALU_SRA;
          default: current_alu_op = ALU_NOP;
        endcase
      end
      
      // ... (Add other RV32I opcodes here: I-type, S-type, etc.)
      
      default: begin
        current_alu_op = ALU_NOP; // Illegal opcode
      end
    endcase
  end

  // -------------------------------
  // ALU Implementation [cite: 36]
  // -------------------------------
  // Sign extension/interpretation for signed ops (MIN, MAX, ABS) 
  assign s1 = rs1_val;
  assign s2 = rs2_val;

  always_comb begin
    alu_result = 32'b0;
    
    case (current_alu_op)
      // RV32I Standard Ops
      ALU_ADD:   alu_result = rs1_val + rs2_val;
      ALU_SUB:   alu_result = rs1_val - rs2_val;
      // ... (rest of RV32I ALU ops)
      ALU_AND:   alu_result = rs1_val & rs2_val;
      ALU_OR:    alu_result = rs1_val | rs2_val;
      ALU_XOR:   alu_result = rs1_val ^ rs2_val;
      ALU_SLT:   alu_result = (s1 < s2) ? 32'd1 : 32'd0;
      ALU_SLTU:  alu_result = (rs1_val < rs2_val) ? 32'd1 : 32'd0;
      ALU_SLL:   alu_result = rs1_val << rs2_val[4:0];
      ALU_SRL:   alu_result = rs1_val >> rs2_val[4:0];
      ALU_SRA:   alu_result = s1 >>> rs2_val[4:0]; // Arithmetic right shift

      // ----------------- RVX10 custom ops -----------------
      
      // Bitwise Operations (Negation) [cite: 25]
      ALU_ANDN:  alu_result = rs1_val & ~rs2_val;
      ALU_ORN:   alu_result = rs1_val | ~rs2_val;
      ALU_XNOR:  alu_result = ~(rs1_val ^ rs2_val);

      // Comparison Operations [cite: 25]
      ALU_MIN:   alu_result = (s1 < s2) ? rs1_val : rs2_val;      // Signed
      ALU_MAX:   alu_result = (s1 > s2) ? rs1_val : rs2_val;      // Signed
      ALU_MINU:  alu_result = (rs1_val < rs2_val) ? rs1_val : rs2_val; // Unsigned
      ALU_MAXU:  alu_result = (rs1_val > rs2_val) ? rs1_val : rs2_val; // Unsigned

      // Rotate Operations (requires special handling for shift-by-0) [cite: 29]
      ALU_ROL: begin
        logic [4:0] sh = rs2_val[4:0];
        alu_result = (sh == 0) ? rs1_val :
                     ((rs1_val << sh) | (rs1_val >> (32 - sh)));
      end
      ALU_ROR: begin
        logic [4:0] sh = rs2_val[4:0];
        alu_result = (sh == 0) ? rs1_val :
                     ((rs1_val >> sh) | (rs1_val << (32 - sh)));
      end

      // Absolute Value (Handles INT_MIN overflow to 0x80000000) [cite: 30]
      ALU_ABS: begin
        alu_result = (s1 >= 0) ? rs1_val : (0 - rs1_val); 
        // (0 - rs1_val) correctly computes the two's complement negation. 
        // If rs1_val = INT_MIN (0x8000_0000), 0 - 0x8000_0000 results in 0x8000_0000
        // due to 32-bit wrap, fulfilling the requirement. [cite: 30]
      end

      default: alu_result = 32'b0;
    endcase
  end

  // -------------------------------
  // Writeback and Memory Access
  // -------------------------------
  // Mux for Writeback (Only ALU result used for RVX10, no memory or immediate) 
  assign regfile_wdata = alu_result;

  // Data memory Interface (for RV32I S/L-type and the final success criterion)
  // dmem_addr must select ALU result since SW/LW use the result of ADDI (address calculation).
  assign dmem_addr  = alu_result; 
  assign dmem_wdata = rs2_val; 

endmodule