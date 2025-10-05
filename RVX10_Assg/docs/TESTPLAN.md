# RVX10 Test Plan

This test plan ensures the correct functionality of all 10 custom RVX10 single-cycle instructions. A deterministic checksum (accumulated in x28) is used to verify correct execution of all tests.

The success criterion is met by storing the value 25 to memory address 100 after all checks are complete.

## Test Case Definitions (Inputs: R_A = rs1, R_B = rs2; Output: R_D = rd)

| Instr | funct7/funct3 | Test Inputs (Hex) | R_A (rs1) | R_B (rs2) | Expected R_D (rd) (Hex) | Property Tested |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **ANDN** | 0000000/000 | 0xF00F_000F | 0xA5A5_A5A5 | 0xF00F_000F | 0x0000_A5A5 | Bitwise AND-NOT: rd = rs1 & ~rs2[cite: 25]. |
| **ORN** | 0000000/001 | 0xF00F_000F | 0x0000_A5A5 | 0xFF00_FFFF | 0xFF00_A5A5 | Bitwise OR-NOT: $rd = rs1\ |\ \sim rs2$[cite: 25]. |
| **XNOR** | 0000000/010 | 0xAAAA_5555 | 0xAAAA_AAAA | 0x5555_5555 | 0x0000_0000 | Bitwise XNOR: $rd = \sim(rs1\ \oplus\ rs2)$[cite: 25]. |
| **MIN** | 0000001/000 | 0x8000_0001 | 0x7FFFFFFF | 0x80000001 | 0x8000_0001 | Signed minimum comparison. |
| **MAX** | 0000001/001 | 0x8000_0000 | 0x00000000 | 0x80000000 | 0x0000_0000 | Signed maximum comparison. |
| **MINU** | 0000001/010 | 0xFFFF_FFFF | 0x00000000 | 0xFFFF_FFFF | 0x0000_0000 | Unsigned minimum comparison. |
| **MAXU** | 0000001/011 | 0xFFFF_FFFE | 0x00000001 | 0xFFFF_FFFE | 0xFFFF_FFFE | Unsigned maximum comparison. |
| **ROL** | 0000010/000 | 0x0000_0000 | 0x12345678 | 0x00000000 | 0x12345678 | Rotate by zero: $\text{ROL}$ with $s=0$ returns $rs1$ unchanged. |
| **ROR** | 0000010/001 | 0x0000_0005 | 0x12345678 | 0x00000005 | 0x78123456 | Rotate Right by 5 bits: $s=rs2[4:0]=5$. |
| **ABS** | 0000011/000 | 0x8000_0000 | 0x80000000 | x0 | 0x8000_0000 | ABS overflow: ABS(INT_MIN) = 0x80000000. |
