# RVX10‑P — Compact 5‑Stage RISC‑V Pipeline

A clean, practical implementation of a 5‑stage pipelined RV32I core with a set of custom RVX10 ALU extensions. This README is written to be short, actionable, and easy to scan — perfect for contributors, students, or quick experiments.

---

## What this repo contains

* **A synthesizable (SystemVerilog) 5‑stage pipeline**: IF → ID → EX → MEM → WB
* **Hazard handling**: forwarding, load‑use stall, and flush on taken branches/jumps
* **Custom RVX10 instructions** (CUSTOM‑0 opcode): `andn`, `orn`, `xnor`, `min`, `max`, `minu`, `maxu`, `rol`, `ror`, `abs`
* **Testbenches** to exercise normal operation and hazard behaviors
* **Simple performance counters** (cycles, retired instructions, stalls, flushes)

---

## Major files

```
src/
  datapath.sv         # Five-stage datapath and ALU
  controller.sv       # Opcode / control signal generator
  forwarding_unit.sv  # Forwarding logic (EX/MEM, MEM/WB)
  hazard_unit.sv      # Load-use hazard detector and stall interface
  riscvpipeline.sv    # Optional top-level wrapper

tb/
  tb_pipeline.sv      # Minimal smoke testbench
tests/
  *.hex               # Example programs loaded by the testbenches
```

---

## Highlights / Design goals

* **Simplicity and clarity**: readable SystemVerilog, designed for classroom use and step‑by‑step debugging
* **Icarus‑friendly constructs**: avoids certain constant selects and concatenated `case` patterns that cause elaboration issues
* **Extensible ALU**: extra RVX10 ops are encoded under a custom opcode and decode path so you can add more micro‑ops easily
* **Minimal runtime checks**: x0 corruption warnings, forwarding events, and load‑use stall messages are printed during simulation

---

## Quick build & run (Icarus Verilog)

```bash
# from repository root
iverilog -g2012 -o pipeline_tb src/*.sv tb/tb_pipeline.sv
vvp pipeline_tb
# optional: create a VCD and open in GTKWave
 vvp pipeline_tb -vcd && gtkwave dump.vcd
```
---

## Running tests

* **Smoke test:** `tb/tb_pipeline.sv` — basic instruction stream
* **Hazard stress:** `tb/tb_pipeline_hazard.sv` — produces forwarding and load‑use stall messages

Suggested workflow:

1. Compile as above.
2. Run `vvp pipeline_tb` and inspect stdout for diagnostic messages.
3. For waveform debugging: generate a VCD and open it in GTKWave.

---

## Performance summary (example)

```
Cycles:         34
Retired instrs: 26
Stalls:         0
Flushes:        0
Branches:       0
Avg CPI:        1.31
Utilization:    76.5%
```

---

