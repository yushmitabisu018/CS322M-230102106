# Problem 2: Moore Traffic Light Controller

## State Diagram
![State Diagram](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem2_traffic/figures/2nd_state%20Diagram.jpeg)  
- **States**:  
  - `NS_G`: North-South green (5 ticks)  
  - `NS_Y`: North-South yellow (2 ticks)  
  - `EW_G`: East-West green (5 ticks)  
  - `EW_Y`: East-West yellow (2 ticks)  
- **Transitions**: Triggered by `tick` after counting ticks in each state.

## Waveform
![Waveform](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem2_traffic/figures/traffic_waveform.jpeg)  
- **Signals**:  
  - `clk` → 100 MHz clock (period = 10 ns)  
  - `rst` → synchronous active-high reset  
  - `tick` → 1-cycle pulse generated every 20 cycles (for fast simulation)  
  - `ns_g`, `ns_y`, `ns_r` → North-South traffic lights  
  - `ew_g`, `ew_y`, `ew_r` → East-West traffic lights  

- **Annotations**:  
  - NS green high for **5 ticks** → NS yellow high for **2 ticks**  
  - EW green high for **5 ticks** → EW yellow high for **2 ticks**  
  - Each transition occurs only when `tick=1`.  

## Test Cases
| Scenario          | Expected Behavior                                    |
|-------------------|-----------------------------------------------------|
| Reset             | FSM starts in `NS_GREEN` with tick counter = 0       |
| NS Green phase    | `ns_g=1`, `ew_r=1` for 5 ticks                       |
| NS Yellow phase   | `ns_y=1`, `ew_r=1` for 2 ticks                       |
| EW Green phase    | `ew_g=1`, `ns_r=1` for 5 ticks                       |
| EW Yellow phase   | `ew_y=1`, `ns_r=1` for 2 ticks                       |
| Normal Operation  | Repeats the cycle **5/2/5/2 ticks** indefinitely     |

## How to Run
1. Compile & simulate:
   ```bash
   iverilog -o sim.out tb_traffic_light.v traffic_light.v
   vvp sim.out
   gtkwave dump.vcd

# Tick Generation and Verification

## Clock and Tick Settings
- **System clock (clk):** 50 MHz  
- **Chosen tick rate (TICK_HZ):** 1 Hz  
  - Means `tick=1` occurs **once every 1 second**.  
- **Prescaler counter value:**  
  - Rolls over every `CLK_FREQ_HZ / TICK_HZ = 50,000,000 / 1 = 50,000,000` cycles.  
  - At rollover, `tick` is asserted high for exactly **1 clock cycle**.

## Why Tick?
- FSM always runs on the **fast clk (50 MHz)**.  
- FSM state transitions depend only on **tick pulses**, not raw clock cycles.  
- Easier to tune traffic-light timings (e.g., change TICK_HZ without touching FSM).  
- Simulation becomes faster and waveform viewing clearer.  

## Verification of Tick
1. In the testbench, we monitored the `tick` signal.  
2. Confirmed that `tick` pulses are **1-cycle wide** and occur once per second.  
3. FSM durations:  
   - Red: **5 ticks** → 5 seconds  
   - Green: **2 ticks** → 2 seconds  
   - Yellow: **5 ticks** → 5 seconds  
   - Green: **2 ticks** → 2 seconds  
4. Waveform (GTKWave) showed correct phase lengths: **5/2/5/2 seconds**.  

## Example Check in Simulation
- At simulation time **5 seconds**, FSM transitioned Red → Green.  
- At **7 seconds**, FSM transitioned Green → Yellow.  
- At **12 seconds**, FSM transitioned Yellow → Green.  
- At **14 seconds**, FSM transitioned Green → Red.  

This confirmed the **5/2/5/2 tick-based durations** were working correctly.
