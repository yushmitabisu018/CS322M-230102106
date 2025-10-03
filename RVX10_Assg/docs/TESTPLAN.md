# RVX10 Test Plan

This test plan ensures the correct functionality of all 10 custom RVX10 single-cycle instructions. A deterministic checksum (accumulated in x28) is used to verify correct execution of all tests.

[cite_start]The success criterion is met by storing the value 25 to memory address 100 after all checks are complete.

## Test Case Definitions (Inputs: R_A = rs1, R_B = rs2; Output: R_D = rd)

| Instr | funct7/funct3 | Test Inputs (Hex) | R_A (rs1) | R_B (rs2) | Expected R_D (rd) (Hex) | Property Tested |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **ANDN** | 0000000/000 | 0xF00F_000F | 0xA5A5_A5A5 | 0xF00F_000F | 0x0000_0000 | Bitwise complement and masking. |
| **ORN** | 0000000/001 | 0xF00F_000F | 0x0000_A5A5 | 0xFF00_FFFF | 0xFFFFFFFF | Bitwise complement of $rs2$ (0x00FF_0000) ORed with $rs1$. |
| **XNOR** | 0000000/010 | 0xAAAA_5555 | 0xAAAA_AAAA | 0x5555_5555 | 0xFFFFFFFF | Test for total bit mismatch (XOR=0xFFFFFFFF, then NOT). |
| **MIN** | 0000001/000 | 0x8000_0001 | 0x7FFFFFFF | 0x80000001 | 0x8000_0001 | Signed comparison: Negative number is smaller than positive number. |
| **MAX** | 0000001/001 | 0x8000_0000 | 0x00000000 | 0x80000000 | 0x0000_0000 | Signed comparison: 0 is larger than INT_MIN (0x80000000). |
| **MINU** | 0000001/010 | 0xFFFF_FFFF | 0x00000000 | 0xFFFF_FFFF | 0x0000_0000 | Unsigned comparison: Smallest possible unsigned value. |
| **MAXU** | 0000001/011 | 0xFFFF_FFFE | 0x00000001 | 0xFFFF_FFFE | 0xFFFF_FFFE | Unsigned comparison: Largest possible unsigned value. |
| **ROL** | 0000010/000 | 0x0000_0000 | 0x12345678 | 0x00000000 | 0x12345678 | [cite_start]Rotate by zero (must return $rs1$)[cite: 29]. |
| **ROR** | 0000010/001 | 0x0000_0005 | 0x12345678 | 0x00000005 | 0x78123456 | Rotate Right by 5 bits. |
| **ABS** | 0000011/000 | 0x8000_0000 | 0x80000000 | x0 | 0x8000_0000 | [cite_start]ABS overflow: $\text{ABS}(\text{INT\_MIN})=\text{INT\_MIN}$. |

***

## 2. `docs/README.md` (How to Run)

This file provides instructions for your simulator/test environment.

```markdown
# CS322M RV32I Core with RVX10 Extension

This repository contains the single-cycle RISC-V RV32I core implementation with the custom RVX10 instruction set extension (CUSTOM-0, opcode 0x0B).

## Deliverables

* [cite_start]`src/riscvsingle.sv`: Modified core RTL supporting RVX10 decode/ALU[cite: 97].
* `docs/ENCODINGS.md`: Full instruction encoding table and a manual encoding example.
* `docs/TESTPLAN.md`: Per-op inputs and expected results for verification.
* [cite_start]`tests/rvx10.hex`: The self-checking test program image for simulation[cite: 100].

## Build and Run Instructions

Assuming a standard Verilog/SystemVerilog simulation environment (e.g., Icarus Verilog or VCS):

1.  **Simulation Command:**
    Compile the core and the provided testbench (`testbench.sv` - assumed to be provided by the course).
    ```bash
    # Example using Icarus Verilog (iverilog)
    iverilog -o sim.vvp src/riscvsingle.sv testbench.sv
    ```

2.  **Run Simulation:**
    Execute the compiled simulation, reading the memory image from `tests/rvx10.hex`.
    ```bash
    vvp sim.vvp
    ```

3.  **Success Criterion:**
    [cite_start]The simulation will print **"Simulation succeeded"** if the final instruction correctly stores the value $\mathbf{25}$ to memory address $\mathbf{100}$[cite: 10, 106].