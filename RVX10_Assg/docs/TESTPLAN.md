# RVX10 Test Plan

## 1. Overview and Verification Strategy

This test plan defines the test cases for the 10 custom RVX10 instructions added to the RV32I core. All instructions must adhere to single-cycle semantics and use the R-type format with the Custom-0 opcode (0x0B).

The verification strategy is self-checking:

1. A sequence of RVX10 instructions is executed; intermediate results are stored in specific registers.
2. A deterministic checksum is computed by accumulating a result from each test case into a designated register (e.g., `x28`).
3. The final success criterion is met by storing the value **25** to memory address **100**.

## 2. Instruction Test Cases

All RVX10 instructions use the **CUSTOM-0 opcode (0001011)**.

| No. | Instruction | Opcode  | Test Expression                                    | Expected Result (Hex) | Verification Method      |
|:---:|:------------|:--------|:---------------------------------------------------|:----------------------:|:------------------------:|
| 1   | **ANDN**    | 0001011 | `x5 = x6 & ~x7`; `x6 = 0xF0F0A5A5`, `x7 = 0x0F0FFFFF` | `0xF0F00000`          | Checksum accumulation    |
| 2   | **ORN**     | 0001011 | `x8 = x1 | ~x2`; `x1 = 0x00FF0000`, `x2 = 0x0000FFFF`  | `0xFFFF0000`          | Checksum accumulation    |
| 3   | **XNOR**    | 0001011 | `x9 = ~(x3 ^ x4)`; `x3 = 0xAAAAAAAA`, `x4 = 0x55555555` | `0x00000000`       | Checksum accumulation    |
| 4   | **MIN**     | 0001011 | `x10 = min_S(-3, 5)`                                 | `0xFFFFFFFD`          | Checksum accumulation    |
| 5   | **MAX**     | 0001011 | `x11 = max_S(-3, 5)`                                 | `0x00000005`          | Checksum accumulation    |
| 6   | **MINU**    | 0001011 | `x12 = min_U(0xFFFFFFFE, 0x00000001)`                | `0x00000001`          | Checksum accumulation    |
| 7   | **MAXU**    | 0001011 | `x13 = max_U(0xFFFFFFFE, 0x00000001)`                | `0xFFFFFFFE`          | Checksum accumulation    |
| 8   | **ROL**     | 0001011 | `x14 = rol(0x80000001, 3)`                           | `0x0000000C`          | Checksum accumulation    |
| 9   | **ROR**     | 0001011 | `x15 = ror(0x00000008, 3)`                           | `0x00000001`          | Checksum accumulation    |
|10   | **ABS**     | 0001011 | `x16 = abs(0x80000000)` (INT_MIN)                    | `0x80000000`          | Checksum accumulation    |

> Notes:
> * All test expressions are R-type encodings (CUSTOM-0).  
> * Use canonical 32-bit hex notation (leading zeros shown).  
> * Accumulate each instruction’s result (or a derived check value) into the checksum register (e.g., `x28`).

## 3. Special Case Notes

* **ABS overflow:** The `ABS` instruction must handle `INT_MIN` (`0x80000000`) by returning itself (two’s-complement wrap behavior).  
* **Rotation by zero:** For `ROL` and `ROR`, the shift amount is defined as `rs2[4:0]`. If the shift amount is `0`, the result must be `rs1` unchanged (this avoids undefined `<< 32` / `>> 32` shifts).  
* **Writes to x0:** Writes to register `x0` must be ignored by the core (no architectural state change).

## 4. Example test flow (pseudo-assembly)

1. Initialize registers with the chosen inputs (e.g., `li x6, 0xF0F0A5A5 ; li x7, 0x0F0FFFFF`).
2. Execute the RVX10 instruction (using `.word` for custom encodings if assembler does not support the opcode).
3. Read the result register and `add` it into the checksum register `x28`.
4. Repeat for all tests.
5. At the end: `li x10, 25 ; li x11, 100 ; sw x10, 0(x11)` — store 25 at memory address 100 to signal success.

---

If you want, I can:
* produce a ready-to-run `.s` file that implements the above checks and writes `25` to address `100`, or  
* generate the `.word` list (machine words) for each RVX10 instruction used in the tests so you can paste them into your `rvx10.hex` / test image.

