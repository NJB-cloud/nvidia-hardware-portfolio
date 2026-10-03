# Project 4 — 5-Stage Pipelined RV32I CPU
# Verification Test Plan

## 1. Objective

The objective of this verification effort is to validate the integrated
5-stage pipelined RV32I processor and its pipeline-control mechanisms.

The verification focuses on correct instruction execution across the
pipeline and correct handling of data and control hazards.

The current processor supports the following instruction subset:

- R-type: ADD
- R-type: SUB
- R-type: AND
- R-type: OR
- R-type: XOR
- R-type: SLT
- I-type: LW
- S-type: SW
- B-type: BEQ

The processor is organized as a five-stage pipeline:

1. Instruction Fetch (IF)
2. Instruction Decode / Register Read (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

---

## 2. Verification Strategy

Verification is performed progressively.

### Level 1 — Module Verification

Individual pipeline-support modules are tested independently.

Verified components include:

- Forwarding Unit
- Hazard Unit
- EX Stage
- IF/ID Pipeline Register
- ID/EX Pipeline Register
- EX/MEM Pipeline Register
- MEM/WB Pipeline Register

### Level 2 — CPU Integration Verification

The complete pipelined processor is executed using directed programs.

The integration test verifies:

- Instruction execution
- Pipeline progression
- Register write-back
- Memory operations
- Data forwarding
- Load-use hazard handling
- Branch operation
- Branch flushing
- x0 protection

### Level 3 — Program-Level Regression

A 20-program directed regression suite exercises the integrated processor.

The regression automatically reports:

- PASS
- FAIL
- Expected architectural result
- Observed architectural result
- Final regression statistics

---

## 3. Verification Environment

### HDL

SystemVerilog

### Simulator

Icarus Verilog

### Waveform Viewer

GTKWave

### Development Environment

Visual Studio Code on Windows

---

## 4. Functional Verification Areas

### 4.1 ALU Operations

The regression verifies:

- ADD
- SUB
- XOR
- SLT
- Negative arithmetic

These tests establish correct arithmetic execution through the pipeline.

---

### 4.2 Data Dependencies

The verification includes multiple instructions where a later
instruction consumes a result produced by an earlier instruction.

Examples include:

```text
ADD x6,x1,x2
ADD x7,x6,x1
and longer dependency chains.
These tests exercise RAW (Read After Write) dependencies.
4.3 EX/MEM Forwarding
The forwarding logic is tested when a result from the EX/MEM pipeline
stage is required by a following instruction.
Expected behavior:
EX/MEM result
      |
      v
Forwarding Unit
      |
      v
EX-stage ALU input

The dependent instruction must receive the most recent value without
waiting for normal register-file write-back.
4.4 MEM/WB Forwarding
The regression also exercises forwarding from the MEM/WB pipeline stage.
This verifies that an older in-flight result can be supplied directly
to the execute stage when required.
4.5 Dual-Operand Forwarding
A dedicated test verifies that both ALU operands can require forwarding
during the same execute cycle.
This is important because the forwarding network must independently
select the correct source for operand A and operand B.
4.6 Store-Data Forwarding
The verification checks a dependency where a newly calculated value is
subsequently stored to memory.
Example:
ADD x6,x1,x2
SW  x6,0(x0)

The store must receive the correct value even though the producing
instruction has not completed normal write-back at the time the store
requires its data.
4.7 Load Operations
The regression verifies:
LW rd,offset(rs1)

using deterministic data-memory contents.
The loaded value is checked against the expected architectural result.
4.8 Load-Use Hazard
A specific test verifies:
LW  x6,0(x0)
ADD x7,x6,x1

This is a load-use dependency.
Because the loaded value is not immediately available from the EX stage,
the pipeline must correctly invoke its hazard-handling mechanism.
The test verifies the resulting architectural value.
4.9 Store Operations
Store instructions are tested using deterministic memory locations.
Expected behavior:
SW rs2,offset(rs1)

writes the correct value to the intended memory word.
4.10 Branch Taken
The regression includes taken BEQ tests.
Example:
BEQ x7,x3,target

when:
x7 == x3

The branch target must be selected as the next program-counter path.
4.11 Branch Not Taken
A separate test verifies that execution continues sequentially when:
x7 != x3

This ensures that the branch condition does not incorrectly redirect
the program counter.
4.12 Branch Flush
The regression deliberately places an instruction on the sequential
path that must not affect the architectural state after a taken branch.
The test verifies that the incorrect-path instruction is flushed.
This provides direct verification of control-hazard handling.
4.13 x0 Protection
The RISC-V zero register must remain:
x0 = 0

even when an instruction attempts to write to it.
The regression explicitly checks this behavior.
5. Directed Regression Tests
The current regression contains 20 directed programs.
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


6. Expected Verification Evidence
The regression should produce a machine-readable console result containing:
PASS:

or:
FAIL:

for each architectural check.
The final summary reports:
CHECKS EXECUTED
PASSED
FAILED

A successful regression is expected to produce:
FAILED = 0

with all checks passing.
7. Waveform Verification
The regression testbench generates a VCD waveform:
waveform/pipelined_regression_wave.vcd

The waveform can be inspected using GTKWave.
Important signals include:
- clk
- rst_n
- current_pc
- instruction
- stall_debug
- forward_a_debug
- forward_b_debug
- ex_alu_result_debug
- mem_alu_result_debug
- wb_data_debug
The waveform provides cycle-level evidence of pipeline execution and
hazard-control behavior in addition to the automated architectural
checks.
8. Reproducibility
From the Project 4 directory, compile the complete design and regression
testbench using:
iverilog -g2012 -o .\pipelined_regression_test .\rtl\alu.sv .\rtl\alu_control.sv .\rtl\control_unit.sv .\rtl\pc.sv .\rtl\instruction_memory.sv .\rtl\register_file.sv .\rtl\immediate_generator.sv .\rtl\forwarding_unit.sv .\rtl\hazard_unit.sv .\rtl\if_id_reg.sv .\rtl\id_ex_reg.sv .\rtl\ex_stage.sv .\rtl\ex_mem_reg.sv .\rtl\mem_wb_reg.sv .\rtl\pipelined_core.sv .\tb\pipelined_regression_tb.sv

Run the regression:
vvp .\pipelined_regression_test

Open the waveform:
gtkwave .\waveform\pipelined_regression_wave.vcd

9. Verification Limitations
This verification environment is based on directed tests.
It does not currently provide:
- Full RV32I ISA coverage
- Constrained-random stimulus
- Functional coverage infrastructure
- Assertion-based verification
- Formal verification
- Performance benchmarking
- Cache verification
- Interrupt verification
- Exception verification
- CSR verification
- Privilege-mode verification
These are potential future extensions.
10. Completion Criteria
Project 4 pipeline verification is considered complete for the current
scope when:
1. Individual pipeline-support modules pass their directed tests.
2. The integrated pipelined CPU executes correctly.
3. Forwarding behavior is verified.
4. Load-use hazard handling is verified.
5. Branch behavior is verified.
6. Branch flushing is verified.
7. x0 protection is verified.
8. The complete directed regression passes.
9. A VCD waveform is generated successfully.
10. The verification procedure is reproducible from the project directory.
11. Verification results are documented in the project repository.
11. Current Scope Statement
This project demonstrates a compact five-stage pipelined RV32I processor
implementation and a directed RTL verification workflow.
The verification demonstrates progressively broader testing from
individual pipeline mechanisms through integrated processor execution
and program-level regression.
The project should not be interpreted as full RV32I compliance or as a
production processor verification environment.