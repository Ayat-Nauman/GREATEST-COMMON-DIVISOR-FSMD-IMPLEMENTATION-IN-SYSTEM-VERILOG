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

### Verified Test Cases

- $\gcd(12, 4) = 4$
- $\gcd(3, 9) = 3$
- $\gcd(14, 7) = 7$
- $\gcd(24, 24) = 24$
- $\gcd(56, 48) = 8$
- $\gcd(39, 52) = 13$

---

## 🧠 What Is an FSMD, and Why Use One?

An FSMD decouples digital designs into two cooperating components:

* **Datapath** — Registers, arithmetic logic units (ALUs), multiplexers, and comparators. Executes actual data processing combinationally and via registers without any sequencing awareness.
* **Controller (FSM)** — A pure Moore state machine that sequences the datapath by asserting control signals (load enables, select lines), branching purely on status flags returned from the datapath.


### Advantages

* **Separation of Concerns:** Arithmetic evaluation and control flow are designed, simulated, and debugged independently.
* **Reusability:** The controller logic can drive alternate datapaths (and vice versa) with minimal friction.
* **Tool-Assisted Flow:** Graphical creation of pure Moore FSMs enables auto-generation of clean HDL and netlist cross-verification.
* **Direct Mapping:** Translates algorithmic steps directly into state transitions and branch conditions.

---

## 🔄 Controller — Built with Quartus State Machine Wizard

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

![Top-Level RTL View](path/to/top_level_rtl.png)

### Submodules Breakdown

![Submodules Breakdown](path/to/submodules_rtl.png)

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

---

## 📊 Synthesis Results

* **Tool:** Intel Quartus Prime Lite Edition 18.1.0 (Build 625)
* **Target Device:** Cyclone V FPGA (`5CGXFC7C7F23C8`)

---

## 🛠️ Tools & Technologies

* **Language:** SystemVerilog
* **FSM Capture:** Quartus Prime State Machine Wizard
* **Simulation:** ModelSim
* **Synthesis Engine:** Intel Quartus Prime Lite Edition 18.1.0
* **Hardware Architecture:** FSMD (Finite State Machine with Datapath)
