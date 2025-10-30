# RVX10-P — Pipelined RISC-V Processor (Short Project Report)

**Project:** RV32I + RVX10 (5-stage pipelined CPU)    
**Author:** Yushmita Bisu


## Summary of this run

* Testbench binary: `pipeline_tb`
* Instruction memory file: `tests/rvx10_pipeline.hex`
* Key run observations: forwarding working, expected stores observed, simulation finished successfully (self-check passed).
* Note: a small warning about the instruction file length was produced — see *Warnings*.

---

## Console output (relevant excerpts)

```
WARNING: src/riscvpipeline.sv:59: $readmemh(tests/rvx10_pipeline.hex): Not enough words in the file for the requested range [0:63].
VCD info: dumpfile pipeline_tb.vcd opened for output.
FORWARD: EX->EX for x2 at t=70000
FORWARD: EX->EX for x3 at t=80000
FORWARD: EX->EX for x4 at t=90000
STORE @ 96 = 0x00000000 (t=135000)
FORWARD: EX->EX for x5 at t=280000
FORWARD: EX->EX for x5 at t=300000
FORWARD: EX->EX for x5 at t=320000
FORWARD: EX->EX for x5 at t=340000
STORE @ 100 = 0x00000019 (t=365000)
Simulation succeeded
CHECKSUM (x28) = 4 (0x00000004)
tb/tb_pipeline.sv:44: $finish called at 365000 (1ps)
```

---

## Pipeline metrics (final summary printed by TB)

* **Total cycles:** 34
* **Instructions retired:** 26
* **Stalls:** 0
* **Flushes:** 0
* **Branches taken:** 0
* **Average CPI:** 1.31
* **Utilization (instructions/cycle):** 76.5%

---

## What these numbers mean (brief interpretation)

* **Forwarding working correctly:** Multiple `FORWARD: EX->EX` messages indicate the forwarding unit successfully bypassed recent ALU results to dependent instructions — no extra cycles were needed for these RAW hazards.
* **No load-use stalls:** `Stalls = 0` shows the test program did not trigger any load→use hazards that the hazard unit had to stall for.
* **No branch penalties in this run:** `Branches = 0` and `Flushes = 0` — either the program contains no taken branches, or branches were arranged such that they were not taken during the observed run.
* **Performance:** `Avg CPI = 1.31` — slightly higher than ideal (1.0) due to pipeline fill/drain overhead for a short program and the ratio of retired instructions to cycles (utilization 76.5%).
* **Final correctness check:** The TB detected a store to address `100` with value `0x19` and printed `Simulation succeeded` and `CHECKSUM (x28) = 4` — this is your program’s self-check result (x28 holds `4` at the check point).

---

## Issues & suggestions

1. **Instruction file warning**

   ```
   WARNING: $readmemh(tests/rvx10_pipeline.hex): Not enough words in the file for the requested range [0:63].
   ```

   * Means the imem was initialized for 64 words but the hex file has fewer entries. This is not fatal but you may want to:

     * Pad the `.hex` file (append `00000013` NOPs) to reach 64 lines, **or**
     * Reduce the imem size if you intentionally have fewer instructions.
   * Padding example (append N NOPs): `printf '00000013\n%.0s' {1..38} >> tests/rvx10_pipeline.hex`

2. **Small program length effects**

   * Short tests exaggerate pipeline fill/drain overhead (raises CPI). Run longer instruction streams to measure steady-state CPI closer to ideal.

3. **Checksum value**

   * Your run produced `CHECKSUM (x28) = 4`. If you expected a different value, verify the test program and TB check condition. If `Simulation succeeded` was printed, the testbench considers the run successful based on its stored condition.

---

## Recommended next steps

* If you want a **cleaner run** with no warning, append NOPs to `tests/rvx10_pipeline.hex` until it contains 64 words.

* To inspect internal signals and verify hazard/forwarding behaviour visually, open the VCD:

  ```bash
  gtkwave pipeline_tb.vcd &
  ```

  Add these signals to the waveform view for debugging:

  * `PC`, `IFID_Instr`, `IDEX_*` (rs1/rs2/rd, imm), `ALU_input_A/B`, `alu_result_e`
  * `EXMEM_aluOut`, `EXMEM_writeData`, `MEMWB_*`
  * `ForwardA`, `ForwardB`, `stallF`, `stallD`, `flushE`, `flushD`
  * `GPR[28]` if exported / accessible (or add a TB display to print entire regfile at end)

* To collect multiple runs or compare effects of changes, run and save output:

  ```bash
  vvp pipeline_tb | tee sim_output_run1.log
  ```

---

## One-page conclusion

Your RVX10-P pipeline is functionally correct for the provided test: forwarding resolved data hazards, stores occurred at expected addresses, and the TB self-check passed (`Simulation succeeded`). The reported CPI (1.31) and utilization (76.5%) are reasonable for a short test with pipeline fill/drain overhead. Address the `$readmemh` warning by padding the hex file for cleaner initialization, and run longer tests to measure steady-state throughput.

---
