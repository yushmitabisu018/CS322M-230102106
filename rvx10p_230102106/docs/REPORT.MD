# RVX10-P: 5-Stage Pipelined RISC-V Processor (RV32I + RVX10 Extension)

**Name:** Yushmita Bisu (230102106)  
**Institute:** IIT Guwahati  
**Date:** October 2025  

---

## 1. Introduction

This project implements **RVX10-P**, a five-stage pipelined RISC-V processor extending the base **RV32I** ISA with 10 **custom ALU instructions** (the RVX10 extension).  
The processor has been designed using **SystemVerilog** and fully simulated with **Icarus Verilog**.  
It demonstrates instruction-level parallelism through pipelining and efficient hazard handling using **forwarding** and **stall control**.

---

## 2. Design Overview

### 2.1 Pipeline Stages
RVX10-P follows the standard 5-stage RISC pipeline:

| Stage | Name | Main Function |
|--------|------|----------------|
| IF | Instruction Fetch | Fetch instruction from instruction memory |
| ID | Instruction Decode | Decode, read registers, generate control signals |
| EX | Execute | Perform ALU operations and branch decisions |
| MEM | Memory Access | Read/write data memory |
| WB | Write Back | Write results to register file |

Each stage is separated by pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) that hold intermediate data and control signals.

### 2.2 Key Modules

| Module | Function |
|---------|-----------|
| **riscvpipeline.sv** | Top-level processor integrating datapath and control |
| **controller.sv** | Decodes opcode and generates control signals |
| **datapath.sv** | Implements all five pipeline stages |
| **hazard_unit.sv** | Detects and handles load-use hazards |
| **forwarding_unit.sv** | Resolves data hazards by forwarding ALU results |
| **tb_pipeline.sv** | Self-checking testbench for verification |

---

## 3. Hazard Detection and Forwarding

### 3.1 Data Hazards
Data hazards arise when an instruction depends on the result of a previous one still in the pipeline.

**Solution:**
- **Forwarding**: The forwarding unit detects dependencies and forwards ALU results from EX/MEM or MEM/WB to the EX stage.
- **Priority**: MEM-stage data > WB-stage data.

### 3.2 Load-Use Hazards
When an instruction immediately follows a load using its result, forwarding isn’t enough because the data is available only after MEM.

**Solution:**
The **hazard unit** detects such cases and stalls:
- Stalls IF and ID stages (by asserting `stallF` and `stallD`)
- Flushes the EX stage (`flushE`) to insert a NOP bubble

### 3.3 Control Hazards
Branches are handled using a **predict-not-taken** approach.  
If the branch is taken, the next fetched instruction is flushed from the pipeline.

---

## 4. RVX10 Custom Instruction Set

The **RVX10** extension adds 10 custom ALU operations under opcode `0001011`.  
These include bitwise and arithmetic extensions such as ANDN, ORN, XNOR, MIN, MAX, and rotation operations.

| Mnemonic | Description |
|-----------|--------------|
| ANDN | `rd = rs1 & ~rs2` |
| ORN | `rd = rs1 \| ~rs2` |
| XNOR | `rd = ~(rs1 ^ rs2)` |
| MIN / MAX | Signed comparison |
| MINU / MAXU | Unsigned comparison |
| ROL / ROR | Rotate left/right |
| ABS | Absolute value of `rs1` |

These are implemented directly in the ALU using extended control codes and seamlessly integrated into the pipeline flow.

---

## 5. Simulation Setup

### 5.1 Testbench
The self-checking **tb_pipeline.sv** provides:
- Clock and reset generation  
- Monitors for store operations and result verification  
- Automatic success/failure messages  
- Optional waveform dumping via `$dumpvars`

### 5.2 Program Memory
The test program (`tests/rvx10_pipeline.hex`) includes:
- Arithmetic, logical, and custom RVX10 instructions  
- Forwarding tests  
- Store operations verifying memory write correctness

---

## 6. Simulation Results

**Command Used:**
```bash
iverilog -g2012 -o pipeline_tb src/*.sv tb/tb_pipeline.sv
vvp pipeline_tb
