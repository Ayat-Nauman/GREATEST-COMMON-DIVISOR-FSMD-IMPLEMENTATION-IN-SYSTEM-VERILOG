# GCD FSMD — Finite State Machine with Datapath

A hardware **Greatest Common Divisor (GCD)** unit implemented as a classic **FSMD (Finite State Machine with Datapath)**: a hand-written SystemVerilog **datapath**, a **controller** captured graphically with Quartus's **State Machine Wizard** and auto-generated into synthesizable SystemVerilog, integrated into a top-level module (`ugcd`), verified in **ModelSim**, and synthesized in **Quartus Prime Lite 18.1.0** targeting a **Cyclone V (5CGXFC7C7F23C8)**.

---

## GCD Algorithm

Computes `GCD(xi, yi)` for two 6-bit operands using the **subtractive Euclidean algorithm** — no divider needed, just a comparator and a subtractor:

```
function gcd(x, y):
    while (x != y):
        if (x < y):  y = y - x
        else:        x = x - y
    return x   // == y, the GCD
```

Verified test cases (GCD): `(12,4)→4`, `(3,9)→3`, `(14,7)→7`, `(24,24)→24`, `(56,48)→8`, `(39,52)→13`.

---

## 🧠 What Is an FSMD, and Why Use One?

An **FSMD** splits a digital design into two cooperating pieces:

- **Datapath** — registers, arithmetic/logic units, muxes, comparators. Does the actual data manipulation, entirely combinationally/register-driven, with **no notion of sequencing**.
- **Controller (FSM)** — a pure Moore state machine that sequences the datapath by asserting control signals (load-enables, mux-selects), branching only on status flags fed back from the datapath.

They talk to each other through a narrow, one-directional-each-way interface: controller → control signals → datapath, datapath → status flags → controller.

**Why it's useful:**
- **Separation of concerns** — arithmetic correctness and control sequencing can be designed and debugged independently.
- **Reusability** — the same controller pattern can drive a different datapath, and vice versa.
- **Tool-assisted design** — because the controller is a pure Moore FSM, it can be drawn graphically (as done here) and the tool auto-generates correct HDL *and* can independently re-extract the state diagram from the synthesized netlist as a sanity check.
- **Natural algorithm mapping** — any "operate, then branch" algorithm (like this GCD) maps directly: each algorithmic step → one state, each branch → a guarded state transition.

---

## 🧱 Datapath (`gcd_datapath`)

```systemverilog
assign mux1 = (x_sel)? x_y : xi;   // load xi, or feed back x−y
assign mux2 = (y_sel)? y_x : yi;   // load yi, or feed back y−x

assign x_lt_y  = (x < y)  ? 1 : 0; // → controller
assign x_neq_y = (x != y) ? 1 : 0; // → controller
assign y_x = y - x;
assign x_y = x - y;
```
<img width="4456" height="2940" alt="DATAPATH" src="https://github.com/user-attachments/assets/cfd021fd-5234-430a-bff8-ac71fc351123" />

Registers `x`, `y`, `d` load only when their `*_ld` control signal is asserted — otherwise they hold. `x_lt_y` and `x_neq_y` are the two status flags the algorithm's `while`/`if` need to branch on.

---
###  FSM Flowchart
<img width="1644" height="2547" alt="FSM FLOWCHART" src="https://github.com/user-attachments/assets/9d36dd43-71c3-4230-b938-b80869fbef7e" />

###  FSMD Flowchart 
<img width="2091" height="3000" alt="FSMD FLOWCHART" src="https://github.com/user-attachments/assets/23682eb7-994b-47a0-a9fe-d4dbc9803433" />

## 🕹️ Controller — Built with Quartus's State Machine Wizard

Instead of hand-writing the FSM, it was **drawn graphically**:

1. **File ▸ New ▸ State Machine File** — launches the wizard.
2. **Inputs tab** — declare `rst`, `clk`, `go_i`, `x_lt_y`, `x_neq_y`.
3. **Outputs tab** — declare `x_ld`, `y_ld`, `x_sel`, `y_sel`, `d_ld`.
4. **General tab** — synchronous, active-high reset; auto self-loop on unspecified conditions.
5. **States tab** — define 6 states (`state1`…`state6`), mark `state1` as the reset state.
6. **Per-state Actions + Outgoing Transitions** — for each state, set which outputs are held high (Moore-style — outputs depend only on current state) and draw guarded transitions to the next state(s).
7. **Generate HDL** — the wizard emits synthesizable SystemVerilog for the state register, next-state logic and output-decode logic, guaranteed consistent with the diagram.

### State Table

| State | Outputs Asserted | Role |
|---|---|---|
| `state1` | *(all 0)* | **IDLE** — waits for `go_i` |
| `state2` | `x_ld=1, y_ld=1` | **LOAD** — `x ← xi`, `y ← yi` |
| `state3` | *(all loads 0)* | **TEST** — let `x_lt_y`/`x_neq_y` settle |
| `state4` | `x_ld=1, x_sel=1` | **SUBTRACT X** — `x ← x − y` (when `x ≥ y`) |
| `state5` | `y_ld=1, y_sel=1` | **SUBTRACT Y** — `y ← y − x` (when `x < y`) |
| `state6` | `d_ld=1` | **DONE** — `d ← x` (== y), the GCD result |

###  State Diagram 

State diagram made in Quartus from which HDL code is generated:
<img width="501" height="209" alt="GCD_FSM_QUARTUS" src="https://github.com/user-attachments/assets/a6a38f92-1490-4c14-8078-632bfb4877e8" />


### RTL Diagram
Top view:
<img width="920" height="341" alt="GCD_RTL_DIAGRAM_TOP_VIEW" src="https://github.com/user-attachments/assets/19c354a9-95aa-451b-a91c-d29e1481412a" />

Controller:
<img width="490" height="371" alt="CONTROLLER_RTL_DIAGRAM" src="https://github.com/user-attachments/assets/0dc3efd9-57f2-4616-b20c-bad4c726b024" />

Datapath:
<img width="827" height="277" alt="GCD_DATAPATH_RTL" src="https://github.com/user-attachments/assets/dd943827-dece-4396-a48e-b2023a15931d" />


## ✅ Testbench & Simulation (ModelSim)
<img width="892" height="98" alt="GCD_OUTPUT_WAVEFORM" src="https://github.com/user-attachments/assets/86aec678-ce88-4c15-8744-2edaa57e996b" />

| xi | yi | Expected GCD | Simulated `d_o` |
|---|---|---|---|
| 12 | 4 | 4 | 4 |
| 3 | 9 | 3 | 3 |
| 14 | 7 | 7 | 7 |
| 24 | 24 | 24 | 24 |
| **56** | **48** | **8** | **8** |
| **39** | **52** | **13** | **13** |

All six vectors — including the three of primary interest, `(56,48)`, `(24,24)`, `(39,52)` — resolve to bit-exact correct results.

---

## 📊 Synthesis Results (Quartus Prime Lite 18.1.0, Cyclone V)

<img width="332" height="307" alt="GCD UTILIZATION REPORT" src="https://github.com/user-attachments/assets/f3eb7a92-8530-4356-8b6e-11475913f25f" />

---

## 🛠️ Tools Used

- **HDL:** SystemVerilog (hand-written datapath & testbench; Quartus-generated controller)
- **Controller entry:** Quartus Prime **State Machine Wizard** (graphical state-diagram → auto-generated SystemVerilog)
- **Functional verification:** ModelSim
- **Synthesis:** Quartus Prime Lite Edition 18.1.0 (Build 625)
- **Target device:** Intel/Altera Cyclone V, `5CGXFC7C7F23C8`

---
