# GCD FSMD — Finite State Machine with Datapath

A hardware Greatest Common Divisor (GCD) unit implemented as a classic FSMD (Finite State Machine with Datapath): a hand-written SystemVerilog datapath, a controller captured graphically with Quartus's State Machine Wizard and auto-generated into synthesizable SystemVerilog, integrated into a top-level module (`ugcd`), verified in ModelSim, and synthesized in Quartus Prime Lite 18.1.0 targeting an Intel Cyclone V FPGA (`5CGXFC7C7F23C8`).

---

## 📐 GCD Algorithm

Computes $\gcd(x_i, y_i)$ for two 6-bit operands using the subtractive Euclidean algorithm — requiring no division hardware, only a comparator and subtractor.

```systemverilog
function
gcd(x, y):
       while (x != y):
              if (x < y):  y = y - x
              else:        x = x - y
       return x   // == y, the GCD
```

## What Is an FSMD, and Why Use One?

An FSMD decouples digital designs into two cooperating components:

* **Datapath** — Registers, arithmetic logic units (ALUs), multiplexers, and comparators. Executes actual data processing combinatorially and via registers without any sequencing awareness.
* **Controller (FSM)** — A pure Moore state machine that sequences the datapath by asserting control signals (load enables, select lines), branching purely on status flags returned from the datapath.


### Advantages

* **Separation of Concerns:** Arithmetic evaluation and control flow are designed, simulated, and debugged independently.
* **Reusability:** The controller logic can drive alternate datapaths (and vice versa) with minimal friction.
* **Tool-Assisted Flow:** Graphical creation of pure Moore FSMs enables auto-generation of clean HDL and netlist cross-verification.
* **Direct Mapping:** Translates algorithmic steps directly into state transitions and branch conditions.

### Steps of creating a datapath
The following are the steps for creating a datapath:
1. Identify the variables as FF registers, i.e., x,y,d_o.
2. Identify functional units, i.e., two comparators and two subtractors.
3. To connect the above two, Muxes may be used.

Datapath:
<p align="center">
<img width="501" height="209" alt="DATAPATH" src="https://github.com/user-attachments/assets/b4503840-1449-41d5-ba5a-c65240e2b15d" />
</p>
---

## FSM Flowchart
FSM Flowchart only contains the signals of the FSM, excluding all the assignments of the datapath.
<p align="center">
<img width="501" height="209" alt="FSM FLOWCHART" src="https://github.com/user-attachments/assets/255b23a4-2557-44c2-9d4a-a58f55258f19" />
</p>
---

## FSMD Flowchart
FSMD Flowchart contains the signals of the FSM, including all the assignments of the datapath.
<p align="center">
<img width="2091" height="3000" alt="FSMD FLOWCHART" src="https://github.com/user-attachments/assets/8cec7485-d25b-4fe0-b7a7-42dd464b19fe" />
</p>
---

## Controller — Built with Quartus State Machine Wizard

The FSM controller was designed graphically using Intel Quartus Prime:

1. **Wizard Setup:** Created via `File ▸ New ▸ State Machine File`.
2. **Inputs:** `rst`, `clk`, `go_i`, `x_lt_y`, `x_neq_y`.
3. **Outputs:** `x_ld`, `y_ld`, `x_sel`, `y_sel`, `d_ld`.
4. **Configuration:** Synchronous active-high reset with auto self-loop on unspecified conditions.
5. **State Definition:** 6 defined states (`state1` through `state6`), with `state1` designated as the reset state.
6. **Actions & Transitions:** Implemented Moore-style outputs per state and conditional transition branches.
7. **HDL Generation:** Exported clean, synthesizable SystemVerilog for state encoding, next-state logic, and output decoding.

### State Table

| State | Outputs Asserted | Role |
| :--- | :--- | :--- |
| `state1` | *(None)* | **IDLE** — Waiting for `go_i` assertion |
| `state2` | `x_ld = 1`, `y_ld = 1` | **LOAD** — Register inputs $x \leftarrow x_i$, $y \leftarrow y_i$ |
| `state3` | *(None)* | **TEST** — Allow comparator outputs (`x_lt_y`, `x_neq_y`) to settle |
| `state4` | `x_ld = 1`, `x_sel = 1` | **SUBTRACT X** — Execute $x \leftarrow x - y$ (when $x \ge y$) |
| `state5` | `y_ld = 1`, `y_sel = 1` | **SUBTRACT Y** — Execute $y \leftarrow y - x$ (when $x < y$) |
| `state6` | `d_ld = 1` | **DONE** — Register result $d \leftarrow x$ (GCD output ready) |

### State Diagram
<p align="center">
<img width="501" height="209" alt="GCD_FSM_QUARTUS" src="https://github.com/user-attachments/assets/82800ba4-3d8f-4881-8d7d-40415d7eb9f2" />
</p>
---

## 🖼️ RTL Diagrams

### Top-Level View (`ugcd`)

<p align="center">
<img width="501" height="209" alt="GCD_RTL_DIAGRAM_TOP_VIEW" src="https://github.com/user-attachments/assets/d3476eaf-1e7e-4ac1-b274-0b8724ccaa5d" />
</p>

### Controller FSM RTL

<p align="center">
<img width="501" height="209" alt="CONTROLLER_RTL_DIAGRAM" src="https://github.com/user-attachments/assets/2bfaa756-0b65-452f-9d79-cb1a3c8a2bf3" />
</p>

### Datapath RTL

<p align="center">
<img width="501" height="209" alt="CONTROLLER_RTL_DIAGRAM" src="https://github.com/user-attachments/assets/2bfaa756-0b65-452f-9d79-cb1a3c8a2bf3" />
</p>
---

## ✅ Testbench & Verification (ModelSim)

| $x_i$ | $y_i$ | Expected GCD | Simulated `d_o` | Result |
| :---: | :---: | :---: | :---: | :---: |
| 12 | 4 | 4 | 4 | **PASS** |
| 3 | 9 | 3 | 3 | **PASS** |
| 14 | 7 | 7 | 7 | **PASS** |
| 24 | 24 | 24 | 24 | **PASS** |
| 56 | 48 | 8 | 8 | **PASS** |
| 39 | 52 | 13 | 13 | **PASS** |

<p align="center">
<img width="501" height="209" alt="GCD_OUTPUT_WAVEFORM" src="https://github.com/user-attachments/assets/0707c7cc-5e84-40fe-975a-a95078963af3" />
</p>
---

## Utilization Report

The utilization report generated from Quartus is given below:
<p align="center">
<img width="501" height="209" alt="GCD UTILIZATION REPORT" src="https://github.com/user-attachments/assets/44e9ff8c-0320-4040-922e-24ed7100405a" />
</p>

---

## Tools & Technologies

* **Language:** SystemVerilog
* **FSM Capture:** Quartus Prime State Machine Wizard
* **Simulation:** ModelSim
* **Synthesis Engine:** Intel Quartus Prime Lite Edition 18.1.0
* **Hardware Architecture:** FSMD (Finite State Machine with Datapath)
