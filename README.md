# GCD FSMD — Finite State Machine with Datapath

A hardware **Greatest Common Divisor (GCD)** unit implemented as a classic **FSMD (Finite State Machine with Datapath)**: a hand-written SystemVerilog **datapath**, a **controller** captured graphically with Quartus's **State Machine Wizard** and auto-generated into synthesizable SystemVerilog, integrated into a top-level module (`ugcd`), verified in **ModelSim**, and synthesized in **Quartus Prime Lite 18.1.0** targeting a **Cyclone V (5CGXFC7C7F23C8)**.

---

## 🎯 What This Project Does

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

Registers `x`, `y`, `d` load only when their `*_ld` control signal is asserted — otherwise they hold. `x_lt_y` and `x_neq_y` are the two status flags the algorithm's `while`/`if` need to branch on.

---

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

### Synthesizer-Extracted State Diagram (Sanity Check)

Quartus's synthesizer independently re-derives the state machine from the compiled netlist:

```
state1 --go_i--> state2 --(unconditional)--> state3
state3 --(x_neq_y)&(x_lt_y)--> state5 --> state3
state3 --(x_neq_y)&(~x_lt_y)--> state4 --> state3
state3 --~x_neq_y--> state6
state6 --go_i--> state2      state6 --~go_i--> state1
state1 --~go_i--> state1 (self-loop)
```

This matches the original graphical design exactly — confirming the auto-generated HDL is correct.

---

## 🔗 Top-Level Integration (`ugcd`)

```systemverilog
module ugcd #(parameter N = 6)(
    input  logic          clk,
    input  logic          rst,
    input  logic          go_i,
    input  logic [N-1:0]  xi,
    input  logic [N-1:0]  yi,
    output logic [N-1:0]  d_o
);
    logic x_ld, y_ld, x_sel, y_sel, d_ld;
    logic x_lt_y, x_neq_y;

    controller fsm (
        .clk(clk), .rst(rst), .go_i(go_i),
        .x_lt_y(x_lt_y), .x_neq_y(x_neq_y),
        .x_ld(x_ld), .y_ld(y_ld),
        .x_sel(x_sel), .y_sel(y_sel), .d_ld(d_ld)
    );

    gcd_datapath #(.N(N)) dp (
        .clk(clk), .rst(rst), .xi(xi), .yi(yi), .d_o(d_o),
        .x_sel(x_sel), .y_sel(y_sel),
        .x_ld(x_ld), .y_ld(y_ld), .d_ld(d_ld),
        .x_lt_y(x_lt_y), .x_neq_y(x_neq_y)
    );
endmodule
```

Controller and datapath only ever talk through control signals (out) and status flags (in) — the textbook FSMD interface.

---

## ✅ Testbench & Simulation (ModelSim)

```systemverilog
xi = 6'd56; yi = 6'd48; go_i = 1; #10; go_i = 0; #170; // GCD = 8
xi = 6'd39; yi = 6'd52; go_i = 1; #10; go_i = 0; #150; // GCD = 13
```

A one-cycle `go_i` pulse starts each computation; the testbench then waits long enough for the FSM to walk `state2 → state3 → (state4|state5) → state3 → … → state6` and latch the result.

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

| Metric | Value |
|---|---|
| Logic utilization | **17 / 56,480 ALMs** (< 1%) |
| Total registers | 24 |
| Total pins | 21 / 268 (8%) |
| Target device | Cyclone V, `5CGXFC7C7F23C8` |
| Flow status | Successful |

Tiny footprint, as expected: three 6-bit registers (`x`, `y`, `d`) plus a small FSM state register, two subtractors, two comparators, and Moore output-decode logic.

---

## 🛠️ Tools Used

- **HDL:** SystemVerilog (hand-written datapath & testbench; Quartus-generated controller)
- **Controller entry:** Quartus Prime **State Machine Wizard** (graphical state-diagram → auto-generated SystemVerilog)
- **Functional verification:** ModelSim
- **Synthesis:** Quartus Prime Lite Edition 18.1.0 (Build 625)
- **Target device:** Intel/Altera Cyclone V, `5CGXFC7C7F23C8`

---

## 📄 License

Add your preferred license here (e.g. MIT).
