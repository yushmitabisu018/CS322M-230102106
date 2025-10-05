# RVX10 Test Plan

## 1. Overview and Verification Strategy

[cite_start]This test plan defines the test cases for the 10 custom RVX10 instructions added to the RV32I core[cite: 2]. [cite_start]The instructions adhere to single-cycle semantics and involve no architectural state changes beyond the register file[cite: 8].

[cite_start]The verification strategy is a self-checking one[cite: 93]:
1.  A sequence of RVX10 instructions is executed, with intermediate results stored in specific registers.
2.  [cite_start]A deterministic checksum is computed by accumulating a result from each test case into a designated register (e.g., `x28`)[cite: 94].
3.  [cite_start]The final success criterion is met by storing the value **25** to memory address **100**[cite: 10, 106]. The provided test harness will confirm "Simulation succeeded" upon detecting this specific memory write.

## 2. Instruction Test Cases

[cite_start]All RVX10 instructions use the **CUSTOM-0 opcode (0001011)** and the **R-type format**[cite: 12].

| No. | Instruction | Opcode | Test Expression | Expected Result (Hex) | Verification Method |
|:---:|:-------------|:--------|:----------------|:----------------------|:--------------------|
| 1 | **ANDN** | 0001011 | $x5 = x6\ \&\ \sim x7$; $x6=0\text{xF0F0\_A5A5}$, $x7=0\text{x0F0F\_FFFF}$ | $0\text{xF0F0\_0000}$ | Checksum accumulation |
| 2 | **ORN** | 0001011 | $x8 = x1\ |\ \sim x2$; $x1=0\text{x00FF\_0000}$, $x2=0\text{x0000\_FFFF}$ | $0\text{xFFFF\_0000}$ | Checksum accumulation |
| 3 | **XNOR** | 0001011 | $x9 = \sim(x3\ \oplus\ x4)$; $x3=0\text{xAAAA\_AAAA}$, $x4=0\text{x5555\_5555}$ | $0\text{x0000\_0000}$ | Checksum accumulation |
| 4 | **MIN** | 0001011 | $x10 = \min_{S}(-3, 5)$ | $0\text{xFFFFFFFD}$ | Checksum accumulation |
| 5 | **MAX** | 0001011 | $x11 = \max_{S}(-3, 5)$ | $0\text{x00000005}$ | Checksum accumulation |
| 6 | **MINU** | 0001011 | $x12 = \min_{U}(0\text{xFFFF\_FFFE}, 0\text{x0000\_0001})$ | $0\text{x0000\_0001}$ | Checksum accumulation |
| 7 | **MAXU** | 0001011 | $x13 = \max_{U}(0\text{xFFFF\_FFFE}, 0\text{x0000\_0001})$ | $0\text{xFFFF\_FFFE}$ | Checksum accumulation |
| 8 | **ROL** | 0001011 | $x14 = \text{rol}(0\text{x8000\_0001}, 3)$ | $0\text{x0000\_0008}$ | Checksum accumulation |
| 9 | **ROR** | 0001011 | $x15 = \text{ror}(0\text{x0000\_0008}, 3)$ | $0\text{x1000\_0001}$ | Checksum accumulation |
| 10 | **ABS** | 0001011 | $x16 = \text{abs}(0\text{x8000\_0000})$ ($\text{INT\_MIN}$) | $0\text{x8000\_0000}$ | Checksum accumulation |

## 3. Special Case Notes

* [cite_start]**ABS Overflow:** The `ABS` instruction must handle $\text{INT\_MIN}$ (`0\text{x80000000}`) by returning itself, resulting in `0\text{x80000000}`[cite: 30, 104].
* [cite_start]**Rotation by Zero:** Both `ROL` and `ROR` must be defined such that if the shift amount ($s=rs2[4:0]$) is 0, the result is $rs1$ unchanged[cite: 29, 103].
* [cite_start]**Writes to x0:** As per RISC-V convention, any instruction attempting to write a result to register `x0` must be ignored[cite: 31, 105]. This is typically tested by observing no change in the `x0` register value.
