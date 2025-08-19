## State Diagram
![State Diagram](figures/1st_state_Diagram.jpeg)  

- **States**:  
  - `S0`: Initial state (no input detected)  
  - `S1`: Detected `1`  
  - `S2`: Detected `11`  
  - `S3`: Detected `110`  

- **Transitions**:  
  - Labeled as `din/y` (e.g., `1/0` → input=1, output=0).  
  - When sequence `1101` is detected, output `y=1`.  

- **Overlap Handling**:  
  - After detecting `1101`, FSM falls back to `S1` if the next input is `1` (allowing overlap).  

---

## Waveform
![Waveform](figures/sequence_waveform.png)  

- **Signals Observed**:  
  - `clk` → clock signal  
  - `rst` → active-high reset  
  - `din` → serial input  
  - `y` → output (pulses high when `1101` detected)  

- **Key Events**:  
  - For input `11011011101`, detection occurs at cycles: **4, 7, 11**  

---

## Test Cases
| Input Stream  | Expected Pulse Indices (`y=1`) |
|---------------|--------------------------------|
| `11011011101` | 4, 7, 11                       |
| `1101`        | 4                              |
| `11101`       | 4                              |
| `1101101`     | 4, 7                           |

---

## How to Run

1. Compile design & testbench:  
   ```bash
   iverilog -o sim.out tb_seq_detect_mealy.v seq_detect_mealy.v
   vvp sim.out
   gtkwave dump.vcd
