# Problem 4: Handshake Protocol FSM (Master–Slave)

## State Diagram
![State Diagram](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem4_link/figures/4th_state%20Diagram.jpeg)  

- **Master FSM States**:  
  - `IDLE` : Waiting for request  
  - `REQ`  : Master asserts `req=1`  
  - `WAIT` : Waiting for `ack` from slave  
  - `DONE` : Acknowledgment received, return to IDLE  

- **Slave FSM States**:  
  - `IDLE` : Waiting for master’s request  
  - `ACK`  : Slave asserts `ack=1` on seeing `req`  
  - `WAIT` : Slave holds until master de-asserts `req`  
  - `DONE` : Slave releases `ack` and returns to IDLE  

- **Transitions**:  
  - Master drives `req`, Slave responds with `ack`  
  - Handshake completes when `req` goes high, `ack` follows, then both return low  

---

## Waveform
![Waveform](https://github.com/yushmitabisu018/CS322M-230102106/blob/main/fsm-assignments/problem4_link/figures/link_waveform.jpeg)  

- **Signals Observed**:  
  - `clk` → system clock  
  - `rst` → active-high reset  
  - `req` → request from Master  
  - `ack` → acknowledgment from Slave  

- **Key Events**:  
  - Master raises `req=1` → Slave responds with `ack=1`  
  - Master lowers `req=0` → Slave lowers `ack=0`  
  - Cycle repeats for the next transaction  

---

## Test Cases
| Scenario                         | Expected Behavior |
|----------------------------------|-------------------|
| Master sends `req` pulse         | Slave asserts `ack` |
| Master keeps `req` high          | Slave keeps `ack` high |
| Master lowers `req`              | Slave lowers `ack` |
| Multiple handshakes (back-to-back) | FSM cycles correctly between IDLE → REQ/ACK → DONE |

---

## How to Run

1. Compile design & testbench:  
   ```bash
   iverilog -o sim.out tb_handshake.v master.v slave.v
   vvp sim.out
   gtkwave dump.vcd
