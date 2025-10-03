# RVX10 Instruction Encoding (CUSTOM-0, R-type)

[cite_start]All RVX10 instructions use the CUSTOM-0 opcode (0x0B) and the R-type format[cite: 12].

## R-Type Instruction Format

| Bits 31:25 | Bits 24:20 | Bits 19:15 | Bits 14:12 | Bits 11:7 | Bits 6:0 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| funct7 | rs2 | rs1 | funct3 | rd | opcode |

## RVX10 Encoding Table

| Instr | opcode (hex) | funct7 (bin) | funct3 (bin) | rs2 usage | Semantics |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ANDN | 0x0B | 0000000 | 000 | rs2 | [cite_start]$rd = rs1\ \&\ \sim rs2$ [cite: 25] |
| ORN | 0x0B | 0000000 | 001 | rs2 | [cite_start]$rd = rs1\ |\ \sim rs2$ [cite: 25] |
| XNOR | 0x0B | 0000000 | 010 | rs2 | [cite_start]$rd = \sim(rs1\ \oplus\ rs2)$ [cite: 25] |
| MIN | 0x0B | 0000001 | 000 | rs2 | [cite_start]Signed Min [cite: 25] |
| MAX | 0x0B | 0000001 | 001 | rs2 | [cite_start]Signed Max [cite: 25] |
| **MINU** | **0x0B** | **0000001** | **010** | **rs2** | [cite_start]Unsigned Min [cite: 25] |
| **MAXU** | **0x0B** | **0000001** | **011** | **rs2** | [cite_start]Unsigned Max [cite: 25] |
| ROL | 0x0B | 0000010 | 000 | rs2[4:0] for shamt | [cite_start]Rotate Left [cite: 25] |
| ROR | 0x0B | 0000010 | 001 | rs2[4:0] for shamt | [cite_start]Rotate Right [cite: 25] |
| ABS | 0x0B | 0000011 | 000 | ignored (set rs2=x0) | [cite_start]Absolute Value [cite: 25] |

## Manual Encoding Example: $\text{MAXU}$ x12, x10, x11

Instruction: $\text{MAXU}$ x12, x10, x11. (i.e., $rd=x12$, $rs1=x10$, $rs2=x11$)
* **$rd = x12$** ($\mathbf{0\text{xC}}$)
* **$rs1 = x10$** ($\mathbf{0\text{xA}}$)
* **$rs2 = x11$** ($\mathbf{0\text{xB}}$)
* **$funct7 = 0\text{b0000001}$** ($\mathbf{0\text{x01}}$)
* **$funct3 = 0\text{b011}$** ($\mathbf{0\text{x3}}$)
* **$opcode = 0\text{b0001011}$** ($\mathbf{0\text{x0B}}$)

The 32-bit machine code is calculated as:
$$\text{inst} = (\text{funct7}\ll25) | (\text{rs2}\ll20) | (\text{rs1}\ll15) | (\text{funct3}\ll12) | (\text{rd}\ll7) | \text{opcode}$$

1.  $\text{funct7} = 0\text{x01} \ll 25 = 0\text{x02000000}$
2.  $\text{rs2} = 11 \ll 20 = 0\text{x00B00000}$
3.  $\text{rs1} = 10 \ll 15 = 0\text{x00005000}$
4.  $\text{funct3} = 3 \ll 12 = 0\text{x00003000}$
5.  $\text{rd} = 12 \ll 7 = 0\text{x00000600}$
6.  $\text{opcode} = 0\text{x0B} = 0\text{x0000000B}$

$$\text{inst} = 0\text{x02000000} | 0\text{x00B00000} | 0\text{x00005000} | 0\text{x00003000} | 0\text{x00000600} | 0\text{x0000000B}$$

**32-bit Hex Code:** $\mathbf{0\text{x02B0860B}}$