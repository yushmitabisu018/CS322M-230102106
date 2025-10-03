# CS322M RV32I Core with RVX10 Extension

[cite_start]This repository contains the single-cycle RISC-V RV32I core implementation, extended with 10 custom operations (RVX10) using the CUSTOM-0 opcode (0x0B)[cite: 5, 12].

[cite_start]The implementation adheres to the single-cycle semantics and uses only existing datapath blocks (adder, shifter, comparator, basic logic)[cite: 8, 9].

## Implementation Notes

1.  [cite_start]**Instruction Encoding:** All RVX10 instructions use the R-type format with opcode = 0x0B (binary 0001011)[cite: 12].
2.  [cite_start]**Rotation (ROL/ROR):** The implementation explicitly checks for a shift amount of $s=0$ to ensure $rs1$ is returned unchanged, avoiding shifts by 32[cite: 29, 103].
3.  [cite_start]**Absolute Value (ABS):** The hardware correctly implements the two's complement wrap for the edge case: ABS($0\text{x8000\_0000}$) results in $0\text{x8000\_0000}$[cite: 30, 104].
4.  [cite_start]**Register $x0$:** Writes to the zero register ($x0$) are ignored in the register file write-back logic[cite: 31, 105].

## How to Build and Run

[cite_start]The test harness uses the self-checking strategy outlined in the assignment (accumulating a checksum in a register like x28)[cite: 93, 94].

### Prerequisites

You need a SystemVerilog/Verilog simulator (such as Icarus Verilog (`iverilog`), Verilator, or VCS) and access to a RISC-V toolchain environment (or the ability to load hex files).

### 1. Program the Instruction Memory

The provided test program is `tests/rvx10.hex`. This file must be loaded into the instruction memory (usually via the `$readmemh` system task in the testbench) before simulation starts.

### 2. Run the Simulation

Assuming your course environment provides a testbench (`testbench.sv`) that instantiates `riscv_single.sv` and handles memory loading:

```bash
# Example using Icarus Verilog (iverilog)

# Compile the core and the testbench
iverilog -o sim.vvp src/riscvsingle.sv testbench.sv 

# Run the simulation
# (The testbench must load the rvx10.hex file)
vvp sim.vvp