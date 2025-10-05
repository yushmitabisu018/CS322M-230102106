# RVX10 Test Plan

## 1. Overview and Verification Strategy

[cite_start]This test plan defines the test cases for the 10 custom RVX10 instructions added to the RV32I core[cite: 2]. [cite_start]All instructions must adhere to single-cycle semantics [cite: 8] [cite_start]and use the R-type format with the Custom-0 opcode (0x0B)[cite: 12].

The verification strategy is a self-checking one:
1.  A sequence of RVX10 instructions is executed, with intermediate results stored in specific registers.
2.  [cite_start]A deterministic checksum is computed by accumulating a result from each test case into a designated register (e.g., x28)[cite: 94].
3.  [cite_start]The final success criterion is met by storing the value **25** to memory address **100**[cite: 10, 106].

## 2. Instruction Test Cases

All RVX10 instructions use the **CUSTOM-0 opcode (0001011)**.

| No. | Instruction | Opcode | Test Expression | Expected Result (Hex) | Verification Method |
|:---:|:-------------|:--------|:----------------|:----------------------|:--------------------|
| 1 | **ANDN** | 0001011 | x5 = x6 & ~x7; x6=0xF0F0_A5A5, x7=0x0F0F_FFFF | 0xF0F0_0000 | Checksum accumulation |
| 2 | **ORN** | 0001011 | x8 = x1 \| ~x2; x1=0x00FF_0000, x2=0x0000_FFFF | 0xFFFF_0000 | Checksum accumulation |
| 3 | **XNOR** | 0001011 | x9 = ~(x3 ^ x4); x3=0xAAAA_AAAA, x4=0x5555_5555 | 0x0000_0000 | Checksum accumulation |
| 4 | **MIN** | 0001011 | x10 = min_S(-3, 5) | 0xFFFFFFFD | Checksum accumulation |
| 5 | **MAX** | 0001011 | x11 = max_S(-3, 5) | 0x00000005 | Checksum accumulation |
| 6 | **MINU** | 0001011 | x12 = min_U(0xFFFF_FFFE, 0x0000_0001) | 0x0000_0001 | Checksum accumulation |
| 7 | **MAXU** | 0001011 | x13 = max_U(0xFFFF_FFFE, 0x0000_0001) | 0xFFFF_FFFE | Checksum accumulation |
| 8 | **ROL** | 0001011 | x14 = rol(0x8000_0001, 3) | 0x0000_0008 | Checksum accumulation |
| 9 | **ROR** | 0001011 | x15 = ror(0x0000_0008, 3) | 0x1000_0001 | Checksum accumulation |
| 10 | **ABS** | 0001011 | x16 = abs(0x8000_0000) (INT_MIN) | 0x8000_0000 | Checksum accumulation |

## 3. Special Case Notes

* [cite_start]**ABS Overflow:** The `ABS` instruction must handle $\text{INT\_MIN}$ (`0\text{x80000000}`) by returning itself[cite: 30, 104].
* [cite_start]**Rotation by Zero:** Both `ROL` and `ROR` must be defined such that if the shift amount ($s=rs2[4:0]$) is 0, the result is $rs1$ unchanged[cite: 29, 103].
* [cite_start]**Writes to x0:** Writes to register $x0$ must be ignored[cite: 31, 105].
