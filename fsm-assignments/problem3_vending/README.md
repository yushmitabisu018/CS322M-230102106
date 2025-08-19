# Problem 3: Mealy Vending Machine with Change

## State Diagram
![State Diagram](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem3_vending/figures/3rd_%20state%20Diagram.jpeg)  

- **States** (represent accumulated total):  
  - `S0`: 0  
  - `S5`: 5  
  - `S10`: 10  
  - `S15`: 15  

- **Transitions**:  
  - Labeled as `coin / outputs`  
    - `01` = 5-unit coin  
    - `10` = 10-unit coin  
    - `00` or `11` = ignored (stay in same state)  

  - From `S10` + `10` → `S0`, output `dispense=1`  
  - From `S15` + `5`  → `S0`, output `dispense=1`  
  - From `S15` + `10` → `S0`, output `dispense=1, chg5=1`  

- **Reset**:  
  - Synchronous, active-high, forces machine to `S0`.

- **Why Mealy?**  
  - Outputs (`dispense`, `chg5`) depend on **state + coin input**, so pulses occur *in the same cycle* the final coin arrives.  
  - This avoids an extra cycle delay that a Moore machine would require.  

---

## Waveform
![Waveform](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem3_vending/figures/vending_waveform.jpeg)  

- **Signals Observed**:  
  - `clk` → clock signal  
  - `rst` → active-high reset  
  - `coin` → coin input (01=5, 10=10, 00=idle)  
  - `dispense` → pulses high when total ≥ 20  
  - `chg5` → pulses high when returning 5-unit change (total = 25)  

- **Key Events (from testbench)**:  
  - Insert 5,10,5 → **dispense=1** (20 exactly)  
  - Insert 10,10 → **dispense=1** (20 exactly)  
  - Insert 5,10,10 → **dispense=1, chg5=1** (25 with change)  

---

## Test Cases
| Coin Sequence     | Expected Outputs                     |
|-------------------|---------------------------------------|
| `10, 5, 5`        | Dispense at final `5`                |
| `10, 10`          | Dispense at second `10`              |
| `5, 10, 10`       | Dispense + Change=5 at final `10`    |
| `5, 5, 5, 5`      | Dispense at 4th `5`                  |

---

## How to Run

1. Compile design & testbench:  
   ```bash
   iverilog -o sim.out tb_vending_mealy.v vending_mealy.v
   vvp sim.out
   gtkwave dump.vcd
