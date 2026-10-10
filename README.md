# FPGA Design — Verilog Assignments

My Verilog HDL assignments from a university FPGA design course. Each assignment contains synthesizable RTL, a self-checking or monitor-based testbench, and Vivado screenshots (simulation waveforms, synthesis/implementation results, timing and utilization) plus the written reports.

Topics range from basic sequential logic up to DSP-style datapaths: ripple-carry adders, counters, three FIR filter architectures, FSMs, a FIFO made from two stacks, a debounced button controller, a multi-mode CORDIC core, a Galois LFSR, and fixed-point arithmetic.

## Repository layout

```
.
├── hw2/   Combinational & sequential basics, FIR filter architectures
├── hw3/   Finite-state machines and control logic
├── hw4/   Arithmetic & DSP cores (CORDIC, LFSR, fixed-point)
└── sim.sh Runs any testbench with Icarus Verilog
```

Each `hwN/` folder contains `assignment.pdf` (the problem set), the report where one exists, and one folder per question with the `.v` sources, testbenches (`tb_*.v`) and a `screenshots/` folder.

## Assignments

### HW2 — Building blocks and FIR filters

| Question | Design | Files |
|---|---|---|
| Q1 | Combinational logic (`a & b`, `b \| c`) feeding two D flip-flops | [`hw2/q1-logic-with-dff`](hw2/q1-logic-with-dff) |
| Q2 | 4-bit ripple-carry adder built hierarchically from full-adder instances | [`hw2/q2-ripple-carry-adder`](hw2/q2-ripple-carry-adder) |
| Q3 | 4-bit counter, two ways: **structural** ripple counter from JK flip-flops vs. **behavioral** synchronous counter | [`hw2/q3-counters`](hw2/q3-counters) |
| Q4 | 3-tap FIR filter `y[n] = a·x[n] + b·x[n-1] + c·x[n-2]` in three architectures | [`hw2/q4-fir-filter`](hw2/q4-fir-filter) |

The FIR question compares the area/speed trade-offs of:

- **Direct form** — delay line on the input, a single adder tree to the output register.
- **Transposed form** — input broadcast to all multipliers, with pipeline registers between the partial sums for a shorter critical path.
- **Folded (area-optimized)** — one shared multiplier and an accumulator, time-multiplexed over 3 cycles with a `valid_out` handshake.

Vivado timing and utilization for each version are in `screenshots/direct-form`, `screenshots/transposed` and `screenshots/folded`.

### HW3 — FSMs and control

| Question | Design | Files |
|---|---|---|
| Q1 | Mealy FSM that checks whether a serial binary number (LSB first) is divisible by 3. It tracks the remainder and the current bit weight (1 or 2 mod 3) across 6 states. | [`hw3/q1-div3-fsm`](hw3/q1-div3-fsm) |
| Q2 | Adjustable-speed counter: an 8-bit clock-enable generator divides the clock by `speed_setting + 1`, so the design stays in a single clock domain | [`hw3/q2-adjustable-counter`](hw3/q2-adjustable-counter) |
| Q3 | Parameterized FIFO built from two LIFO stacks, with an FSM that moves data from the input stack to the output stack and a `busy` flag | [`hw3/q3-two-stack-fifo`](hw3/q3-two-stack-fifo) |
| Q4 | Smart appliance controller: 2-FF synchronizer for the async button, counter-based debouncer, edge detection, and a `RESET → IDLE → ACTIVE → ERROR` state machine with a fault output | [`hw3/q4-smart-controller`](hw3/q4-smart-controller) |

### HW4 — Arithmetic and DSP cores

| Question | Design | Files |
|---|---|---|
| Q1 | **Multi-mode CORDIC** (rotation mode): circular mode computes sin/cos, linear mode computes multiplication. 32-bit Q4.28 fixed point, 16 iterations, verified at 50 MHz. Includes a Python bit-accurate model (`cordic_model.py`) for error analysis and a full report. | [`hw4/q1-cordic`](hw4/q1-cordic) |
| Q2 | **16-bit Galois LFSR**, polynomial x¹⁶ + x¹⁴ + x¹³ + x¹¹ + 1, with a seed load and clock enable. The testbench checks seeding, enable, that the all-zero state never occurs, and the period. | [`hw4/q2-galois-lfsr`](hw4/q2-galois-lfsr) |
| Q3 | Q2.5 signed fixed-point adder that outputs the absolute value of the sum, with overflow detection and saturation | [`hw4/q3-fixed-point-adder-abs`](hw4/q3-fixed-point-adder-abs) |

## Tools

- **Xilinx Vivado** for simulation, synthesis and implementation (the screenshots are from Vivado).
- **Icarus Verilog** also works for simulating every design. Install it with `brew install icarus-verilog` on macOS or `apt install iverilog` on Debian/Ubuntu.
- **Python 3** with `numpy` and `matplotlib` for the CORDIC reference model.

## Running the simulations

Use the helper script with a question folder:

```bash
./sim.sh hw3/q3-two-stack-fifo
```

It compiles and runs each testbench in that folder with Icarus Verilog. Testbenches that call `$dumpfile` write a `.vcd` waveform that you can open in [GTKWave](https://gtkwave.sourceforge.net/).

You can also run a design by hand:

```bash
iverilog -g2012 -o sim.vvp hw4/q1-cordic/*.v && vvp sim.vvp
```

For the CORDIC model:

```bash
python3 hw4/q1-cordic/cordic_model.py
```

## Notes

- The code is kept as it was submitted for the course.
- `hw2/q3-counters/tb_counters.v` includes `jk_ff.v`, but the JK flip-flop module is defined inside `counter_structural.v`. Delete that `include` line to simulate it with Icarus.
