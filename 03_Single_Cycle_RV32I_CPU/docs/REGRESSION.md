# RV32I CPU Regression Verification

## 1. Objective

Project 3B extends the single-cycle RV32I CPU verification environment with
program-level regression testing.

The objective is to execute multiple independent instruction programs against
the integrated CPU and verify architectural results automatically.

The final regression suite contains:

- 20 independent programs
- 20 expected-result checks
- PASS/FAIL reporting
- VCD waveform generation

## 2. Verification Environment

### HDL

SystemVerilog

### Simulator

Icarus Verilog

### Waveform Viewer

GTKWave

### Development Environment

Visual Studio Code on Windows

## 3. Regression Results

Final regression result:

```text
============================================================
             RV32I CPU REGRESSION VERIFICATION
============================================================

PROGRAMS EXECUTED = 20
PASSED             = 20
FAILED             = 0
Overall result:
20/20 PASS
4. Program Coverage
Program	Test	Result
01	ADD	PASS
02	SUB	PASS
03	AND	PASS
04	OR	PASS
05	XOR	PASS
06	Signed SLT — true	PASS
07	ADD/SUB dependency chain	PASS
08	LW memory read	PASS
09	SW memory write	PASS
10	LW/SW round-trip	PASS
11	BEQ taken	PASS
12	BEQ not taken	PASS
13	Negative arithmetic	PASS
14	x0 protection	PASS
15	Signed SLT — false	PASS
16	Multiple ALU dependencies	PASS
17	Multiple store/load operations	PASS
18	Branch + register computation	PASS
19	Branch + memory interaction	PASS
20	Complete mixed RV32I program	PASS


5. Coverage Summary
The regression suite exercises:
- Arithmetic operations
- Logical operations
- Signed comparison
- Negative arithmetic
- Register dependencies
- Register write-back
- Load operations
- Store operations
- Load/store round-trip behavior
- Taken branches
- Not-taken branches
- Branch target execution
- Skipped instructions
- x0 protection
- Multi-instruction sequences
- Mixed arithmetic/control/memory execution
6. Program 20 End-to-End Test
Program 20 provides the final mixed instruction sequence:
ADD
SW
LW
XOR
BEQ
skipped instruction
ADD

The intended execution is:
x1 = 10
x2 = 20

x3 = x1 + x2
   = 30

memory[1] = x3
          = 30

x4 = memory[1]
   = 30

x5 = x4 XOR x1
   = 30 XOR 10
   = 20

BEQ x5, x2
    20 == 20
    branch taken

The instruction at 0x14 is skipped.

x7 = x5 + x1
   = 20 + 10
   = 30

Final expected result:
x7 = 30

Observed result:
x7 = 30

Therefore the complete mixed program passed.
7. Debugging Evidence
During regression development, instruction encoding errors were deliberately
exposed by the program-level tests.
One LW test initially used an incorrect instruction encoding. The regression
reported:
FAIL: Program 08 | LW memory read

The instruction encoding was corrected and the test subsequently passed.
Program 20 also initially failed because of an incorrect XOR instruction
encoding. The failing result was:
Expected=0000001e
Got=00000014

Inspection of the instruction fields identified the incorrect source-register
encoding.
The XOR instruction was corrected to represent:
XOR x5,x4,x1

After correction:
PASS: Program 20 | Complete mixed RV32I program
Expected=0000001e
Got=0000001e

The final complete regression then achieved:
20 programs
20 passed
0 failed

8. Waveform Evidence
The final regression simulation generates:
waveform/rv32i_regression_wave.vcd

The waveform can be inspected using GTKWave.
Important signals include:
- current_pc
- instruction
- alu_result
- writeback_data
- register-file state
- data-memory state
- clock
- reset
The waveform provides an additional inspection layer beyond the automated
PASS/FAIL checks.
9. Reproducing the Regression
From the project directory:
iverilog -g2012 -o rv32i_regression_test rtl/pc.sv rtl/instruction_memory.sv rtl/register_file.sv rtl/immediate_generator.sv rtl/alu.sv rtl/control_unit.sv rtl/alu_control.sv rtl/rv32i_cpu.sv tb/rv32i_regression_tb.sv

Run:
vvp .\rv32i_regression_test

Expected final result:
PROGRAMS EXECUTED = 20
PASSED             = 20
FAILED             = 0

10. Verification Hierarchy
The project now contains three verification levels.
Level 1 — Unit Verification
Individual RTL modules were tested independently:
- Program Counter
- Instruction Memory
- Register File
- Immediate Generator
- ALU
- Main Control Unit
- ALU Control
Level 2 — CPU Integration Verification
The complete CPU was tested with directed instruction programs.
Results:
Basic integration:    7/7 PASS
Extended integration: 9/9 PASS

Level 3 — Program-Level Regression
The integrated CPU was exercised using 20 independent programs.
Result:
20/20 PASS
0 FAIL

This provides progressively broader verification from individual modules
through complete processor execution.
11. Current Scope
The regression verifies the currently implemented CPU subset:
R-Type
- ADD
- SUB
- AND
- OR
- XOR
- SLT
I-Type
- LW
S-Type
- SW
B-Type
- BEQ
The regression does not claim full RV32I ISA coverage.
12. Current Limitations
The processor remains a compact single-cycle implementation.
It does not currently include:
- Full RV32I instruction coverage
- Pipelining
- Hazard detection
- Forwarding
- Cache hierarchy
- Interrupt handling
- Exceptions
- CSR subsystem
- Privilege modes
- Constrained-random verification
- Functional coverage infrastructure
- Formal verification
These are potential future extensions.
13. Final Result
The Project 3B program-level regression suite successfully executes:
20 independent programs with 20/20 passing.
Combined with the previously completed unit and integration verification,
this establishes a reproducible RTL simulation and regression workflow for
the current single-cycle RV32I processor implementation.