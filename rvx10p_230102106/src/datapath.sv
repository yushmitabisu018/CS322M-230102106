`timescale 1ns/1ps
// Five-stage pipeline datapath 
// - IF/ID, ID/EX, EX/MEM, MEM/WB
// - forwarding (EX/MEM, MEM/WB), load-use hazard stall, branch/jump control
// - performance counters and runtime checks

module datapath(
  input  wire        clk,
  input  wire        reset,
  output wire [31:0] PC,
  input  wire [31:0] InstrIF,
  output wire        MemWrite_out,
  output wire [31:0] DataAdr_out,
  output wire [31:0] WriteData_out,
  input  wire [31:0] ReadData
);

  
  // Performance counters
  reg [31:0] cnt_cycles, cnt_instructions, cnt_stalls, cnt_flushes, cnt_branches;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      cnt_cycles      <= 32'd0;
      cnt_instructions<= 32'd0;
      cnt_stalls      <= 32'd0;
      cnt_flushes     <= 32'd0;
      cnt_branches    <= 32'd0;
    end else begin
      cnt_cycles <= cnt_cycles + 32'd1;
      if (stallF || stallD) cnt_stalls <= cnt_stalls + 32'd1;
      if (flushE)           cnt_flushes <= cnt_flushes + 32'd1;
    end
  end

  // IF stage
  reg [31:0] pc_reg;
  wire [31:0] pc_next_word, pc_plus4;
  assign PC = pc_reg;
  assign pc_plus4 = pc_reg + 32'd4;

  // IF/ID registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_instr;

  // control signals for pipeline flow
  wire stallF, stallD, flushE, flushD;

  // branch/jump selection
  reg        branch_taken_e; 
  wire [31:0] pc_target;

  assign pc_next_word = pc_take ? pc_target : pc_plus4;

  always @(posedge clk or posedge reset) begin
    if (reset) pc_reg <= 32'd0;
    else if (!stallF) pc_reg <= pc_next_word;
  end

  // IF/ID pipeline register update
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      if_id_pc    <= 32'd0;
      if_id_instr <= 32'h00000013; // NOP (addi x0,x0,0)
    end else begin
      if (flushD) begin
        if_id_pc    <= 32'd0;
        if_id_instr <= 32'h00000013;
      end
      else if (!stallD) begin
        if_id_pc    <= pc_reg;
        if_id_instr <= InstrIF;
      end
      // if stallD, retain IF/ID contents
    end
  end

  // ID stage
  // register file (behavioral)
  reg [31:0] GPR [0:31];
  integer idx;
  initial for (idx = 0; idx < 32; idx = idx + 1) GPR[idx] = 32'd0;

  wire [4:0] rs1_d, rs2_d, rd_d;
  wire [31:0] rf_rd1_d, rf_rd2_d;
  wire [31:0] instr_d;
  assign instr_d = if_id_instr;
  assign rs1_d = instr_d[19:15];
  assign rs2_d = instr_d[24:20];
  assign rd_d  = instr_d[11:7];

  assign rf_rd1_d = (rs1_d != 5'd0) ? GPR[rs1_d] : 32'd0;
  assign rf_rd2_d = (rs2_d != 5'd0) ? GPR[rs2_d] : 32'd0;

  // decode outputs from controller
  wire        RegWriteD, MemWriteD, MemToRegD, ALUSrcD, BranchD, JumpD;
  wire [1:0]  ALUOpD, ImmSrcD, ResultSrcD;

  controller decoder (
    .opcode(instr_d[6:0]),
    .RegWrite(RegWriteD), .MemWrite(MemWriteD),
    .MemToReg(MemToRegD), .ALUSrc(ALUSrcD),
    .ALUOp(ALUOpD), .ImmSrc(ImmSrcD), .ResultSrc(ResultSrcD),
    .Branch(BranchD), .Jump(JumpD)
  );

  // immediate extraction (I, S, B, J)
  wire [11:0] imm_i, imm_s;
  wire [12:0] imm_b;
  wire [20:0] imm_j;
  assign imm_i = instr_d[31:20];
  assign imm_s = {instr_d[31:25], instr_d[11:7]};
  assign imm_b = {instr_d[31], instr_d[7], instr_d[30:25], instr_d[11:8], 1'b0};
  assign imm_j = {instr_d[31], instr_d[19:12], instr_d[20], instr_d[30:21], 1'b0};

  reg [31:0] imm_ext_d;
  // Use always @* instead of always_comb to avoid iverilog constant-select complaints
  always @* begin
    if (ImmSrcD == 2'b00) imm_ext_d = {{20{imm_i[11]}}, imm_i};
    else if (ImmSrcD == 2'b01) imm_ext_d = {{20{imm_s[11]}}, imm_s};
    else if (ImmSrcD == 2'b10) imm_ext_d = {{19{imm_b[12]}}, imm_b};
    else if (ImmSrcD == 2'b11) imm_ext_d = {{11{imm_j[20]}}, imm_j};
    else imm_ext_d = 32'd0;
  end

  // ID/EX pipeline registers
  reg [31:0] idex_rf1, idex_rf2, idex_imm, idex_pc;
  reg [4:0]  idex_rs1, idex_rs2, idex_rd;
  reg        idex_RegWrite, idex_MemWrite, idex_MemToReg, idex_ALUSrc, idex_Branch, idex_Jump;
  reg [1:0]  idex_ALUOp, idex_ResultSrc;
  reg [2:0]  idex_f3;
  reg [6:0]  idex_f7, idex_op;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      idex_rf1 <= 32'd0; idex_rf2 <= 32'd0; idex_imm <= 32'd0; idex_pc <= 32'd0;
      idex_rs1 <= 5'd0; idex_rs2 <= 5'd0; idex_rd <= 5'd0;
      idex_RegWrite <= 1'b0; idex_MemWrite <= 1'b0; idex_MemToReg <= 1'b0;
      idex_ALUSrc <= 1'b0; idex_Branch <= 1'b0; idex_Jump <= 1'b0;
      idex_ALUOp <= 2'd0; idex_ResultSrc <= 2'd0;
      idex_f3 <= 3'd0; idex_f7 <= 7'd0; idex_op <= 7'd0;
    end else begin
      if (flushE) begin
        // insert bubble into EX stage
        idex_rf1 <= 32'd0; idex_rf2 <= 32'd0; idex_imm <= 32'd0; idex_pc <= 32'd0;
        idex_rs1 <= 5'd0; idex_rs2 <= 5'd0; idex_rd <= 5'd0;
        idex_RegWrite <= 1'b0; idex_MemWrite <= 1'b0; idex_MemToReg <= 1'b0;
        idex_ALUSrc <= 1'b0; idex_Branch <= 1'b0; idex_Jump <= 1'b0;
        idex_ALUOp <= 2'd0; idex_ResultSrc <= 2'd0;
        idex_f3 <= 3'd0; idex_f7 <= 7'd0; idex_op <= 7'b0010011; // keep safe opcode
      end
      else if (!stallD) begin
        idex_rf1 <= rf_rd1_d;
        idex_rf2 <= rf_rd2_d;
        idex_imm <= imm_ext_d;
        idex_pc  <= if_id_pc;
        idex_rs1 <= rs1_d; idex_rs2 <= rs2_d; idex_rd <= rd_d;
        idex_RegWrite <= RegWriteD; idex_MemWrite <= MemWriteD;
        idex_MemToReg <= MemToRegD; idex_ALUSrc <= ALUSrcD;
        idex_Branch <= BranchD; idex_Jump <= JumpD;
        idex_ALUOp <= ALUOpD; idex_ResultSrc <= ResultSrcD;
        idex_f3 <= instr_d[14:12];
        idex_f7 <= instr_d[31:25];
        idex_op <= instr_d[6:0];
      end
      // if stallD and not flushE, keep previous idex registers (stall)
    end
  end

  // EX stage
  // ALU control codes (unique constants)
  localparam [4:0] C_ADD   = 5'd0;
  localparam [4:0] C_SUB   = 5'd1;
  localparam [4:0] C_AND   = 5'd2;
  localparam [4:0] C_OR    = 5'd3;
  localparam [4:0] C_XOR   = 5'd4;
  localparam [4:0] C_SLT   = 5'd5;
  localparam [4:0] C_SLL   = 5'd6;
  localparam [4:0] C_SRL   = 5'd7;
  localparam [4:0] C_ANDN  = 5'd8;
  localparam [4:0] C_ORN   = 5'd9;
  localparam [4:0] C_XNOR  = 5'd10;
  localparam [4:0] C_MIN   = 5'd11;
  localparam [4:0] C_MAX   = 5'd12;
  localparam [4:0] C_MINU  = 5'd13;
  localparam [4:0] C_MAXU  = 5'd14;
  localparam [4:0] C_ROL   = 5'd15;
  localparam [4:0] C_ROR   = 5'd16;
  localparam [4:0] C_ABS   = 5'd17;

  // ALU control generator
  function [4:0] alu_ctrl_gen(input [1:0] aluop, input [2:0] f3, input [6:0] f7, input [6:0] op);
    begin
      alu_ctrl_gen = C_ADD;
      if (op == 7'b0001011) begin
        if (f7 == 7'b0000000) begin
          if (f3 == 3'b000) alu_ctrl_gen = C_ANDN;
          else if (f3 == 3'b001) alu_ctrl_gen = C_ORN;
          else if (f3 == 3'b010) alu_ctrl_gen = C_XNOR;
          else alu_ctrl_gen = C_ADD;
        end
        else if (f7 == 7'b0000001) begin
          if (f3 == 3'b000) alu_ctrl_gen = C_MIN;
          else if (f3 == 3'b001) alu_ctrl_gen = C_MAX;
          else if (f3 == 3'b010) alu_ctrl_gen = C_MINU;
          else if (f3 == 3'b011) alu_ctrl_gen = C_MAXU;
          else alu_ctrl_gen = C_ADD;
        end
        else if (f7 == 7'b0000010) begin
          if (f3 == 3'b000) alu_ctrl_gen = C_ROL;
          else if (f3 == 3'b001) alu_ctrl_gen = C_ROR;
          else alu_ctrl_gen = C_ADD;
        end
        else if (f7 == 7'b0000011) begin
          if (f3 == 3'b000) alu_ctrl_gen = C_ABS;
          else alu_ctrl_gen = C_ADD;
        end
        else alu_ctrl_gen = C_ADD;
      end
      else begin
        // standard RISC-V decoding
        if (aluop == 2'b00) alu_ctrl_gen = C_ADD;
        else if (aluop == 2'b01) alu_ctrl_gen = C_SUB;
        else begin
          // R-type / I-type select by funct3 and funct7 msb
          if (f3 == 3'b000) alu_ctrl_gen = (f7[5]) ? C_SUB : C_ADD;
          else if (f3 == 3'b010) alu_ctrl_gen = C_SLT;
          else if (f3 == 3'b110) alu_ctrl_gen = C_OR;
          else if (f3 == 3'b111) alu_ctrl_gen = C_AND;
          else alu_ctrl_gen = C_ADD;
        end
      end
    end
  endfunction

  // EX/MEM and MEM/WB registers (declared early for forwarding)
  reg [31:0] exmem_alu_out, exmem_store_data;
  reg [4:0]  exmem_rd;
  reg        exmem_RegWrite_r, exmem_MemWrite_r, exmem_MemToReg_r;

  reg [31:0] memwb_alu_out, memwb_readback;
  reg [4:0]  memwb_rd;
  reg        memwb_RegWrite_r, memwb_MemToReg_r;

  // forwarding signals
  reg [1:0] forwardA, forwardB;
  wire [4:0] ex_rs1, ex_rs2;
  assign ex_rs1 = idex_rs1;
  assign ex_rs2 = idex_rs2;

  // single-driver copies for forwarding unit and other uses
  wire [4:0]  exmem_rd_wire, memwb_rd_wire;
  wire        exmem_regwrite_wire, memwb_regwrite_wire;

  assign exmem_rd_wire       = exmem_rd;
  assign memwb_rd_wire       = memwb_rd;
  assign exmem_regwrite_wire = exmem_RegWrite_r;
  assign memwb_regwrite_wire = memwb_RegWrite_r;

  // ALU pre-forward operands
  wire [31:0] alu_a_pre, alu_b_pre;
  reg [31:0] alu_in_a, alu_in_b;
  assign alu_a_pre = idex_rf1;
  assign alu_b_pre = idex_ALUSrc ? idex_imm : idex_rf2;

  // forwarding muxing (combinational)
  always @* begin
    alu_in_a = alu_a_pre;
    alu_in_b = alu_b_pre;
    if (idex_rs1 != 5'd0) begin
      if (forwardA == 2'b01) alu_in_a = exmem_alu_out;
      else if (forwardA == 2'b10) alu_in_a = (memwb_MemToReg_r ? memwb_readback : memwb_alu_out);
    end
    if (idex_rs2 != 5'd0 && !idex_ALUSrc) begin
      if (forwardB == 2'b01) alu_in_b = exmem_alu_out;
      else if (forwardB == 2'b10) alu_in_b = (memwb_MemToReg_r ? memwb_readback : memwb_alu_out);
    end
  end

  // ALU implementation
  function [31:0] alu_exec(input [31:0] a, input [31:0] b, input [4:0] ctrl);
    reg [31:0] add_r;
    reg [31:0] sub_r;
    begin
      add_r = a + b;
      sub_r = a - b;
      case (ctrl)
        C_ADD:  alu_exec = add_r;
        C_SUB:  alu_exec = sub_r;
        C_AND:  alu_exec = a & b;
        C_OR:   alu_exec = a | b;
        C_XOR:  alu_exec = a ^ b;
        C_SLT:  alu_exec = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        C_SLL:  alu_exec = a << b[4:0];
        C_SRL:  alu_exec = a >> b[4:0];
        C_ANDN: alu_exec = a & ~b;
        C_ORN:  alu_exec = a | ~b;
        C_XNOR: alu_exec = ~(a ^ b);
        C_MIN:  alu_exec = ($signed(a) < $signed(b)) ? a : b;
        C_MAX:  alu_exec = ($signed(a) > $signed(b)) ? a : b;
        C_MINU: alu_exec = (a < b) ? a : b;
        C_MAXU: alu_exec = (a > b) ? a : b;
        C_ROL:  alu_exec = (b[4:0]==5'd0) ? a : ((a << b[4:0]) | (a >> (32 - b[4:0])));
        C_ROR:  alu_exec = (b[4:0]==5'd0) ? a : ((a >> b[4:0]) | (a << (32 - b[4:0])));
        C_ABS:  alu_exec = ($signed(a) >= 0) ? a : (32'd0 - a);
        default: alu_exec = 32'd0;
      endcase
    end
  endfunction

  // select ALU control
  reg [4:0] alu_ctrl_e;
  always @* begin
    alu_ctrl_e = alu_ctrl_gen(idex_ALUOp, idex_f3, idex_f7, idex_op);
  end

  // compute ALU result and zero flag
  wire [31:0] alu_result_e;
  assign alu_result_e = alu_exec(alu_in_a, alu_in_b, alu_ctrl_e);
  wire zero_e = (alu_result_e == 32'd0);

  // branch decision logic
  always @* begin
    branch_taken_e = 1'b0;
    if (idex_Branch) begin
      if (idex_f3 == 3'b000) branch_taken_e = zero_e;            // beq
      else if (idex_f3 == 3'b001) branch_taken_e = ~zero_e;      // bne
      else if (idex_f3 == 3'b100) branch_taken_e = alu_result_e[0]; // blt (signed)
      else if (idex_f3 == 3'b101) branch_taken_e = ~alu_result_e[0]; // bge
      else if (idex_f3 == 3'b110) branch_taken_e = alu_result_e[0]; // bltu
      else if (idex_f3 == 3'b111) branch_taken_e = ~alu_result_e[0]; // bgeu
      else branch_taken_e = 1'b0;
    end
  end

  // compute PC target and PC selection
  assign pc_target = idex_pc + idex_imm;
  wire pc_take = (branch_taken_e && idex_Branch) || idex_Jump;

  // flush IF/ID when branch/jump taken
  assign flushD = pc_take;

  // forwarded value for store-data (Rs2)
  reg [31:0] store_data_forwarded;
  always @* begin
    store_data_forwarded = idex_rf2;
    if (idex_rs2 != 5'd0) begin
      if (exmem_RegWrite_r && (exmem_rd != 5'd0) && (exmem_rd == idex_rs2))
        store_data_forwarded = exmem_alu_out;
      else if (memwb_RegWrite_r && (memwb_rd != 5'd0) && (memwb_rd == idex_rs2))
        store_data_forwarded = (memwb_MemToReg_r ? memwb_readback : memwb_alu_out);
    end
  end

  // EX/MEM registers update
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      exmem_alu_out      <= 32'd0;
      exmem_store_data   <= 32'd0;
      exmem_rd           <= 5'd0;
      exmem_RegWrite_r   <= 1'b0;
      exmem_MemWrite_r   <= 1'b0;
      exmem_MemToReg_r   <= 1'b0;
    end else begin
      exmem_alu_out    <= alu_result_e;
      exmem_store_data <= store_data_forwarded;
      exmem_rd         <= idex_rd;
      exmem_RegWrite_r <= idex_RegWrite;
      exmem_MemWrite_r <= idex_MemWrite;
      exmem_MemToReg_r <= idex_MemToReg;
    end
  end

  // MEM/WB registers update
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      memwb_alu_out     <= 32'd0;
      memwb_readback    <= 32'd0;
      memwb_rd          <= 5'd0;
      memwb_RegWrite_r  <= 1'b0;
      memwb_MemToReg_r  <= 1'b0;
    end else begin
      memwb_alu_out    <= exmem_alu_out;
      memwb_readback   <= ReadData;
      memwb_rd         <= exmem_rd;
      memwb_RegWrite_r <= exmem_RegWrite_r;
      memwb_MemToReg_r <= exmem_MemToReg_r;
    end
  end

  // Instantiate forwarding_unit (use single-driver wires)
  forwarding_unit fwdunit (
    .Rs1E(ex_rs1), .Rs2E(ex_rs2),
    .RdM(exmem_rd_wire), .RdW(memwb_rd_wire),
    .RegWriteM(exmem_regwrite_wire), .RegWriteW(memwb_regwrite_wire),
    .ForwardA(forwardA), .ForwardB(forwardB)
  );

  // MEM stage outputs to data memory
  assign MemWrite_out = exmem_MemWrite_r;
  assign DataAdr_out  = exmem_alu_out;
  assign WriteData_out = exmem_store_data;

  // WB stage
  // Mux between ALU result and memory read
  wire [31:0] memwb_result;
  assign memwb_result = (memwb_MemToReg_r) ? memwb_readback : memwb_alu_out;

  // commit to register file in WB
  always @(posedge clk) begin
    if (memwb_RegWrite_r && (memwb_rd != 5'd0)) begin
      GPR[memwb_rd] <= memwb_result;
      cnt_instructions <= cnt_instructions + 32'd1;
    end
  end

  // Runtime verification & debug displays
  always @(posedge clk) begin
    if (!reset) begin
      if (GPR[0] !== 32'd0) begin
        $display("ERROR: x0 corrupted: 0x%08h at t=%0t", GPR[0], $time);
      end

      // report EX-to-EX forwarding events
      if (exmem_RegWrite_r && exmem_rd != 5'd0 &&
          (exmem_rd == idex_rs1 || exmem_rd == idex_rs2) &&
          (idex_op == 7'b0110011 || idex_op == 7'b0001011)) begin
        $display("FORWARD: EX->EX for x%0d at t=%0t", exmem_rd, $time);
      end

      // load-use stall detection message
      if (stallF && stallD && flushE) begin
        $display("LOAD-USE STALL: bubble inserted at t=%0t (RdE=x%0d, Rs1D=x%0d, Rs2D=x%0d)",
                 $time, idex_rd, rs1_d, rs2_d);
      end

      // branch/jump notifications
      if (pc_take && idex_Branch) begin
        cnt_branches <= cnt_branches + 32'd1;
        $display("BRANCH TAKEN: PC %0d -> %0d (target=%0d) at t=%0t", idex_pc, pc_target, pc_target, $time);
        $display("  Flushing IF/ID");
      end

      if (pc_take && idex_Jump) begin
        $display("JUMP: PC %0d -> %0d at t=%0t", idex_pc, pc_target, $time);
        $display("  Flushing IF/ID");
      end
    end
  end

  // Hazard detection unit
  wire MemReadE;
  assign MemReadE = (idex_op == 7'b0000011) ? 1'b1 : 1'b0;

  hazard_unit hunit (
    .MemReadE(MemReadE), .RdE(idex_rd),
    .Rs1D(rs1_d), .Rs2D(rs2_d),
    .stallF(stallF), .stallD(stallD), .flushE(flushE)
  );


  // Final reporting (end of simulation)
  final begin
    $display("\n===== PIPELINE METRICS =====");
    $display("Cycles:         %0d", cnt_cycles);
    $display("Retired instrs: %0d", cnt_instructions);
    $display("Stalls:         %0d", cnt_stalls);
    $display("Flushes:        %0d", cnt_flushes);
    $display("Branches:       %0d", cnt_branches);
    if (cnt_instructions > 0) begin
      $display("Avg CPI:        %.2f", real'(cnt_cycles) / real'(cnt_instructions));
      $display("Utilization:    %.1f%%", 100.0 * real'(cnt_instructions) / real'(cnt_cycles));
    end
    $display("============================\n");
  end

endmodule


