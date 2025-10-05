# RVX10 Instruction Encoding (CUSTOM-0, R-type)

All RVX10 instructions use the CUSTOM-0 opcode (0x0B) and the R-type format.

## R-Type Instruction Format

| Bits 31:25 | Bits 24:20 | Bits 19:15 | Bits 14:12 | Bits 11:7 | Bits 6:0 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| funct7 | rs2 | rs1 | funct3 | rd | opcode |

## RVX10 Encoding Table

| Instr | opcode (hex) | funct7 (bin) | funct3 (bin) | rs2 usage | Operation |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ANDN | 0x0B | 0000000 | 000 | rs2 | $rd = rs1\ \&\ \sim rs2$ |
| ORN | 0x0B | 0000000 | 001 | rs2 | $rd = rs1\ |\ \sim rs2$ |
| XNOR | 0x0B | 0000000 | 010 | rs2 | $rd = \sim(rs1\ \oplus\ rs2)$ |
| MIN | 0x0B | 0000001 | 000 | rs2 | Signed Min: $rd = \min(rs1, rs2)$ |
| MAX | 0x0B | 0000001 | 001 | rs2 | Signed Max: $rd = \max(rs1, rs2)$ |
| **MINU** | **0x0B** | **0000001** | **010** | **rs2** | Unsigned Min: $rd = \min_{U}(rs1, rs2)$ |
| **MAXU** | **0x0B** | **0000001** | **011** | **rs2** | Unsigned Max: $rd = \max_{U}(rs1, rs2)$ |
| ROL | 0x0B | 0000010 | 000 | rs2[4:0] for shamt | Rotate Left: $rd = rs1\ \text{rotate\_left}\ rs2$ |
| ROR | 0x0B | 0000010 | 001 | rs2[4:0] for shamt | Rotate Right: $rd = rs1\ \text{rotate\_right}\ rs2$ |
| ABS | 0x0B | 0000011 | 000 | ignored (set rs2=x0) | Absolute Value: $rd = |rs1|$ |

## Corrected Manual Encoding Example: $\text{MAXU}$ x12, x10, x11

Instruction: $\text{MAXU}$ x12, x10, x11. ($rd=x12$, $rs1=x10$, $rs2=x11$)

| Field | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Value (Decimal) | 1 | 11 | 10 | 3 | 12 | 11 |
| Value (Binary) | 0000001 | 01011 | 01010 | 011 | 01100 | 0001011 |
| Value (Hex) | 0x01 | 0x0B | 0x0A | 0x3 | 0x0C | 0x0B |

The 32-bit machine code is calculated as:
$$\text{inst} = (\text{funct7}\ll25) | (\text{rs2}\ll20) | (\text{rs1}\ll15) | (\text{funct3}\ll12) | (\text{rd}\ll7) | \text{opcode}$$

1.  $\text{funct7} = 0\text{x01} \ll 25 = 0\text{x02000000}$
2.  $\text{rs2} = 11 \ll 20 = 0\text{x00B00000}$
3.  $\text{rs1} = 10 \ll 15 = 0\text{x00050000}$
4.  $\text{funct3} = 3 \ll 12 = 0\text{x00003000}$
5.  $\text{rd} = 12 \ll 7 = 0\text{x00000600}$
6.  $\text{opcode} = 0\text{x0B} = 0\text{x0000000B}$

$$\text{inst} = 0\text{x02000000} | 0\text{x00B00000} | 0\text{x00050000} | 0\text{x00003000} | 0\text{x00000600} | 0\text{x0000000B}$$

**32-bit Hex Code (Corrected):** $\mathbf{0\text{x02B5360B}}$