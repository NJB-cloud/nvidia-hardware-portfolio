# RV32I Single-Cycle CPU — Verification Report

## 1. Verification Objective

The purpose of this verification effort is to demonstrate functional correctness of the
single-cycle RV32I CPU and its major RTL components.

Verification was performed at two levels:

1. Module-level verification
2. CPU-level integration verification

Simulation was performed using Icarus Verilog with SystemVerilog support.
Waveforms were inspected using GTKWave.

---

## 2. Module-Level Verification

| Module | Verification Status |
|---|---|
| Program Counter | PASS |
| Instruction Memory | PASS |
| Register File | PASS |
| Immediate Generator | PASS |
| ALU | PASS |
| Main Control Unit | PASS |
| ALU Control | PASS |

### ALU Verification

The ALU verification covered:

- ADD
- SUB
- AND
- OR
- XOR
- Signed SLT
- Zero-result detection
- Negative arithmetic result
- Equal operands
- Zero-result conditions

Final ALU result:

**14/14 tests passed**

---

## 3. CPU Integration Verification

The first integrated CPU test verified:

- ADD
- SUB
- Store Word
- Load Word
- Branch Equal
- Register write-back
- Program counter sequencing

Final result:

**7/7 tests passed**

---

## 4. Extended CPU Verification

An additional integration test was developed to exercise more realistic
control-flow behavior.

The extended program verifies:

- ADD
- SUB
- XOR
- LW
- SW
- BEQ taken
- BEQ not taken
- Register write-back
- x0 protection
- Sequential instruction execution
- Final program-counter behavior

Final result:

**9/9 tests passed**

---

## 5. Branch Verification

### Taken Branch

The CPU executes:

```text
BEQ x5, x4, +8
with: x5 = x4
Therefore the branch is taken.
The observed program-counter transition is:
0x10 → 0x18
This skips the instruction located at:
0x14
The skipped instruction was:
XOR x6, x5, x5
The testbench initialized:
x6 = 123
and verified that x6 remained 123.
This confirms the branch control path.
6. Not-Taken Branch Verification
The extended test also executes a BEQ where the operands are unequal:
x5 = 20
x3 = 30
Therefore:
x5 != x3
and the branch must not be taken.
Execution continues to the next sequential instruction.
The following instruction successfully produces:
x8 = 40
This verifies the not-taken branch path.
7. Load/Store Verification
The CPU stores a value using:
SW x4, 4(x0)
The memory location is subsequently read using:
LW x5, 4(x0)
The verification confirms:
memory[1] = 20
x5       = 20
This verifies the basic data-memory write/read path.
8. Register File Verification
The register file was independently verified before CPU integration.
The integrated CPU additionally verifies register write-back.
The architectural zero register was also tested.
An instruction attempts to write to:
x0
The final verification confirms:
x0 = 0
Therefore the zero register remains protected from modification.
9. Debugging Record
During development, an integration failure was identified in branch execution.
Initial observation:
BEQ skips XOR x6, x5, x5
Expected x6 = 123
Observed x6 = 30
This indicated that the branch target behavior required investigation.
The integration testbench and instruction encoding were reviewed.
The branch instruction encoding was corrected and the subsequent integration
verification produced:
ALL RV32I CPU TESTS PASSED
A later extended verification suite was then created to ensure that both
taken and not-taken branches behaved correctly.
Final extended result:
TOTAL TESTS = 9
PASSED      = 9
FAILED      = 0
10. Waveform Verification
The final extended CPU simulation was dumped to:
rv32i_cpu_extended_wave.vcd
The waveform was inspected using GTKWave.
The waveform demonstrates:
- Clock activity
- Reset behavior
- Program-counter progression
- Instruction execution
- ALU operation
- Branch control
- Memory read
- Memory write
- Register write-back
- Branch target generation
- Register operands
The key branch transition observed in the waveform is:
0x10 → 0x18
confirming that the taken BEQ skips the instruction at 0x14.
The final program counter reaches:
0x28
where the CPU enters the final branch loop.
11. Final Verification Summary
Verification Level	Result
PC verification	PASS
Instruction Memory	PASS
Register File	PASS
Immediate Generator	PASS
ALU	14/14 PASS
Control Unit	PASS
ALU Control	PASS
Basic CPU Integration	7/7 PASS
Extended CPU Integration	9/9 PASS
GTKWave waveform inspection	PASS
12. Verification Conclusion
The current verification results demonstrate functional operation of the
implemented single-cycle RV32I CPU for the tested instruction subset.
The design has been verified at both component and integrated-system levels.
The verification suite specifically covers arithmetic operations, logical
operations, memory access, branch control, register write-back, zero-register
protection, and program-counter sequencing.
Further verification can expand instruction coverage and introduce automated
program-level regression testing.
