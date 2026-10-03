# Project 4 — 5-Stage Pipelined RV32I CPU
# Program-Level Regression Verification

## 1. Overview

Project 4 implements and verifies a compact five-stage pipelined RV32I
processor.

The processor pipeline consists of:

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

The verification environment tests both the processor datapath and the
pipeline-control mechanisms required for correct execution in the
presence of data and control dependencies.

---

## 2. Verification Objective

The primary objective is to demonstrate that the integrated pipelined
processor correctly executes a representative subset of RV32I
instructions while handling:

- RAW data dependencies
- EX/MEM forwarding
- MEM/WB forwarding
- dual-operand forwarding
- store-data forwarding
- load-use hazards
- taken branches
- not-taken branches
- branch flushing
- memory operations
- signed comparisons
- x0 protection

The verification uses deterministic directed tests and a reproducible
SystemVerilog simulation environment.

---

## 3. Supported Instruction Subset

The current processor implements the following instruction subset.

### R-Type

- ADD
- SUB
- AND
- OR
- XOR
- SLT

### I-Type

- LW

### S-Type

- SW

### B-Type

- BEQ

This project does not claim complete RV32I ISA compliance.

---

## 4. Verification Environment

### HDL

SystemVerilog

### Simulator

Icarus Verilog

### Waveform Viewer

GTKWave

### Development Environment

Visual Studio Code on Windows

---

## 5. Verification Hierarchy

The verification was performed at multiple levels.

### Level 1 — Individual Module Verification

The following pipeline-support components were tested independently:

- Forwarding Unit
- Hazard Unit
- EX Stage
- IF/ID Pipeline Register
- ID/EX Pipeline Register
- EX/MEM Pipeline Register
- MEM/WB Pipeline Register

### Level 2 — CPU Integration Verification

The complete five-stage processor was tested using directed programs.

The integration tests verify:

- instruction execution
- register write-back
- memory access
- pipeline progression
- forwarding
- hazard handling
- branch operation
- branch flushing

### Level 3 — Program-Level Regression

The integrated processor was exercised using a 20-program regression
suite.

The final regression completed successfully with all checks passing.

---

## 6. Regression Result

Final program-level regression result:

```text
============================================================
       RV32I 5-STAGE PIPELINE REGRESSION VERIFICATION
============================================================

ALL REGRESSION CHECKS PASSED
The regression completed without a failed architectural check.
Final result:
FAILED = 0

Therefore, all checks included in the current directed regression
passed.
7. Regression Test Coverage
The regression contains 20 directed programs covering the following
functional areas.
Test	Verification Target
01	Basic ADD
02	Basic SUB
03	EX/MEM dependency
04	Multiple RAW dependencies
05	Dual-operand forwarding
06	Store-data forwarding
07	LW memory read
08	Load-use dependency
09	Load dependency chain
10	BEQ taken and branch target
11	BEQ not taken
12	Negative arithmetic
13	Signed SLT true
14	Signed SLT false
15	x0 protection
16	XOR dependency
17	Multiple store/load operations
18	Branch plus forwarded value
19	Branch plus memory interaction
20	Complete mixed pipeline program


8. Forwarding Verification
Forwarding is a central feature of the pipelined processor.
The verification checks forwarding from:
- EX/MEM
- MEM/WB
The forwarding unit was independently tested before integrated
processor verification.
The dedicated forwarding-unit test verified:
TOTAL TESTS = 10
PASSED      = 10
FAILED      = 0

The forwarding tests included:
- no forwarding
- EX/MEM forwarding to operand A
- EX/MEM forwarding to operand B
- MEM/WB forwarding to operand A
- MEM/WB forwarding to operand B
- independent A/B forwarding
- EX/MEM priority over MEM/WB
- x0 protection
- RegWrite disabled
- mixed EX/MEM and MEM/WB forwarding
9. Load-Use Hazard Verification
The regression includes a load-use dependency:
LW  x6,0(x0)
ADD x7,x6,x1

The dependent instruction requires the value produced by the load.
This test verifies that the pipeline correctly handles the hazard
rather than allowing the dependent instruction to use an invalid or
stale value.
The resulting architectural state is checked automatically.
10. Store-Data Forwarding Verification
The regression includes a producer-consumer sequence in which a newly
calculated ALU result is subsequently stored.
Example:
ADD x6,x1,x2
SW  x6,0(x0)

The test verifies that the store receives the correct value through the
pipeline forwarding mechanism.
11. Branch Verification
Branch behavior is tested in multiple situations.
Taken Branch
When the BEQ comparison succeeds, the branch target must be selected.
Not-Taken Branch
When the compared registers differ, sequential execution must continue.
Branch Flush
Instructions on the incorrect sequential path must not modify the final
architectural state after a taken branch.
These tests provide directed verification of the processor's control
hazard handling.
12. Complete Mixed Pipeline Test
Program 20 combines several processor mechanisms in a single sequence.
The program performs:
ADD
SW
LW
XOR
BEQ
skipped instruction
ADD

The intended data flow is:
x1 = 10
x2 = 20

x3 = x1 + x2
   = 30

memory[0] = x3
          = 30

x4 = memory[0]
   = 30

x5 = x4 XOR x1
   = 30 XOR 10
   = 20

The branch then compares:
x5 == x2
20 == 20

Therefore the branch is taken and the sequential-path instruction is
flushed.
The branch target computes:
x7 = x5 + x1
   = 20 + 10
   = 30

The final architectural result is therefore:
x7 = 30

The complete mixed program passed the regression check.
13. Architectural Verification
The regression verifies architectural state rather than relying only on
internal pipeline signals.
Checked state includes:
- register-file values
- data-memory values
- branch-dependent execution
- flushed instruction effects
This provides an end-to-end check from instruction fetch through the
pipeline to architectural state.
14. Waveform Evidence
The regression testbench generates a VCD waveform:
waveform/pipelined_regression_wave.vcd

The waveform can be opened using GTKWave.
Important signals include:
clk
rst_n
current_pc
instruction
stall_debug
forward_a_debug
forward_b_debug
ex_alu_result_debug
mem_alu_result_debug
wb_data_debug

The waveform provides cycle-level evidence of:
- pipeline progression
- forwarding activity
- hazard handling
- branch behavior
- write-back activity
The automated regression result and waveform inspection provide
complementary verification evidence.
15. Reproducibility
From the Project 4 directory, compile the complete processor and
regression testbench with:
iverilog -g2012 -o .\pipelined_regression_test .\rtl\alu.sv .\rtl\alu_control.sv .\rtl\control_unit.sv .\rtl\pc.sv .\rtl\instruction_memory.sv .\rtl\register_file.sv .\rtl\immediate_generator.sv .\rtl\forwarding_unit.sv .\rtl\hazard_unit.sv .\rtl\if_id_reg.sv .\rtl\id_ex_reg.sv .\rtl\ex_stage.sv .\rtl\ex_mem_reg.sv .\rtl\mem_wb_reg.sv .\rtl\pipelined_core.sv .\tb\pipelined_regression_tb.sv

Run:
vvp .\pipelined_regression_test

Open the waveform:
gtkwave .\waveform\pipelined_regression_wave.vcd

16. Debugging and Development Evidence
During development, directed verification exposed implementation and
integration problems.
These failures were investigated and corrected before the final
regression.
The development process therefore included:
RTL implementation
        ↓
Module verification
        ↓
Integration verification
        ↓
Failure detection
        ↓
Debugging
        ↓
RTL/test correction
        ↓
Regression rerun
        ↓
All checks passed

This workflow demonstrates that the verification environment was used
to identify and resolve implementation issues rather than only to
produce a final passing result.
17. Verification Limitations
The current verification environment is directed-test based.
It does not currently include:
- full RV32I ISA coverage
- constrained-random verification
- functional coverage infrastructure
- SystemVerilog assertions
- formal verification
- cache verification
- interrupt verification
- exception verification
- CSR verification
- privilege-mode verification
- performance benchmarking
These are potential future extensions.
18. Current Project Scope
This project demonstrates:
- five-stage pipeline organization
- pipeline registers
- forwarding logic
- hazard detection
- load-use hazard handling
- branch control
- branch flushing
- integrated processor execution
- directed program-level regression
- waveform-based debugging
- reproducible RTL simulation
The project is intentionally scoped as an undergraduate-level processor
architecture and RTL verification project.
It should not be interpreted as a production processor implementation
or complete commercial verification environment.
19. Final Verification Statement
The Project 4 five-stage pipelined RV32I processor successfully passed
its current directed program-level regression.
The final verification demonstrates correct behavior across arithmetic,
logical, memory, dependency, forwarding, hazard, and branch-oriented
tests within the implemented instruction subset.
Final regression status:
ALL REGRESSION CHECKS PASSED
FAILED = 0

The project therefore has a reproducible RTL simulation flow supported by
automated architectural checks and VCD waveform evidence.