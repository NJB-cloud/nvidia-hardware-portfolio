# Single-Cycle RV32I CPU

A synthesizable SystemVerilog implementation of a single-cycle RISC-V
RV32I processor, developed as part of an RTL hardware-design and
verification portfolio.

The project focuses on clean RTL structure, modular design, functional
verification, debugging, and waveform-based validation.

---

## 1. Project Overview

This project implements a 32-bit single-cycle RISC-V processor based on
the RV32I instruction-set architecture.

Each instruction is fetched, decoded, executed, and completed within a
single clock cycle.

The design separates the processor into reusable RTL components:

- Program Counter
- Instruction Memory
- Register File
- Immediate Generator
- ALU
- ALU Control
- Main Control Unit
- Data Memory
- CPU Integration Module

The design was verified using SystemVerilog testbenches, Icarus Verilog,
and GTKWave.

---

## 2. Objectives

The main objectives of this project were:

1. Implement a functional single-cycle RV32I CPU.
2. Develop the processor using modular SystemVerilog RTL.
3. Verify individual hardware blocks independently.
4. Integrate the blocks into a complete processor.
5. Verify arithmetic, logical, memory, and branch operations.
6. Verify both taken and not-taken branch behavior.
7. Verify register write-back and x0 protection.
8. Analyze simulation waveforms using GTKWave.
9. Document debugging and verification methodology.

---

## 3. Architecture

The processor follows a conventional single-cycle datapath.

High-level execution flow:

```text
                 +------------------+
                 | Program Counter  |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Instruction      |
                 | Memory           |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Instruction      |
                 | Decode           |
                 +--------+---------+
                          |
             +------------+------------+
             |                         |
             v                         v
      +-------------+           +-------------+
      | Register    |           | Immediate   |
      | File        |           | Generator   |
      +------+------+           +------+------+
             |                         |
             +------------+------------+
                          |
                          v
                    +-----------+
                    |    ALU    |
                    +-----+-----+
                          |
              +-----------+-----------+
              |                       |
              v                       v
       +-------------+          +-------------+
       | Data Memory |          | Write-back  |
       +-------------+          +------+------+
                                      |
                                      v
                               Register File
                               Branch instructions additionally use the branch target and comparison
logic to determine the next program counter.
4. Supported Instruction Classes
The current verified CPU subset includes:
R-Type
ADD
SUB
AND
OR
XOR
SLT
I-Type
LW
S-Type
SW

B-Type
BEQ

The project is structured so that additional RV32I instructions can be
added without redesigning the complete architecture.
5. RTL Modules
Module	Purpose
pc.sv	Stores and updates the program counter
instruction_memory.sv	Provides instructions to the CPU
register_file.sv	Implements the 32 general-purpose registers
immediate_generator.sv	Generates sign-extended immediates
alu.sv	Performs arithmetic and logical operations
alu_control.sv	Generates ALU operation control
control_unit.sv	Generates main datapath control signals
rv32i_cpu.sv	Integrates the complete processor
6. Verification Strategy
Verification was performed at multiple levels.
Level 1 — Unit Verification
Individual modules were tested independently before integration.
Verified modules include:
- Program Counter
- Instruction Memory
- Register File
- Immediate Generator
- ALU
- Main Control Unit
- ALU Control
Level 2 — CPU Integration
The complete CPU was tested using a small instruction program.
The first integration suite verified:
- ADD
- SUB
- SW
- LW
- BEQ
- Register write-back
- Program-counter sequencing
Result:
7/7 tests passed

Level 3 — Extended Integration
A second verification program was developed to exercise more realistic
control-flow behavior.
The extended suite verifies:
- Arithmetic operations
- Logical operations
- Load/store
- Taken BEQ
- Not-taken BEQ
- Register write-back
- x0 protection
- Sequential execution
- Final PC behavior
Result:
9/9 tests passed
7. ALU Verification
The ALU was independently tested using 14 directed tests.
Coverage included:
- ADD
- SUB
- AND
- OR
- XOR
- Signed SLT
- Zero detection
- Negative arithmetic
- Equal operands
- Zero-result cases
Final result:
TOTAL TESTS = 14
PASSED      = 14
FAILED      = 0
8. Branch Verification
Branch behavior is an important part of the processor verification.
Taken Branch
The CPU executes:
BEQ x5, x4, +8

with:
x5 = x4

Therefore the branch is taken.
The observed PC transition is:
0x10 -> 0x18

The instruction at 0x14 is therefore skipped.
The skipped instruction is:
XOR x6, x5, x5

The testbench initializes:
x6 = 123

and verifies that x6 remains 123.
This provides direct evidence that the branch target is functioning
correctly.
Not-Taken Branch
The extended test also evaluates a branch where:
x5 = 20
x3 = 30

Since:
x5 != x3

the branch is not taken.
Execution continues sequentially to the next instruction.
The following instruction successfully produces:
x8 = 40
9. Load/Store Verification
The processor verifies the store/load data path using:
SW x4, 4(x0)
LW x5, 4(x0)

The verification confirms:
memory[1] = 20
x5        = 20

This demonstrates successful transfer of data between the register file
and data memory.
10. Register File and x0 Verification
The register file was independently verified before CPU integration.
The integrated CPU also verifies register write-back.
A test instruction attempts to write a calculated value into:
x0

The final result remains:
x0 = 0

This confirms the architectural requirement that RISC-V register x0
remains permanently zero.
11. Debugging and Verification Improvement
During development, the first CPU integration test exposed a branch-related
verification failure.
Initial observation:
BEQ skips XOR x6, x5, x5
Expected = 123
Observed  = 30

The failure was investigated by examining:
1. Instruction encoding
2. Branch immediate generation
3. Branch target calculation
4. Program-counter sequencing
5. Register values
6. Simulation behavior
The instruction encoding/testbench was corrected and the integrated CPU
subsequently passed:
ALL RV32I CPU TESTS PASSED

A separate extended verification program was then developed to prevent
the verification suite from depending on only one branch scenario.
The extended suite passed:
TOTAL TESTS = 9
PASSED      = 9
FAILED      = 0

This debugging cycle was useful because it demonstrated the complete
RTL-development workflow:
Design
  ↓
Simulation
  ↓
Failure
  ↓
Waveform/logic investigation
  ↓
Correction
  ↓
Regression test
  ↓
Extended verification
12. Waveform Verification
Simulation waveforms were generated in VCD format and inspected using
GTKWave.
Primary extended waveform:
rv32i_cpu_extended_wave.vcd

The waveform provides visibility into:
- Clock
- Reset
- Program counter
- Instruction
- ALU inputs
- ALU result
- ALU control
- Branch control
- Memory read
- Memory write
- Register write
- Register operands
- Immediate values
- Next PC
- Branch target
The key branch transition visible in the waveform is:
0x10 -> 0x18

demonstrating the taken BEQ and skipped instruction.
The final program counter reaches:
0x28

where the test program enters its final branch loop.
13. Verification Summary
Test Area	Result
Program Counter	PASS
Instruction Memory	PASS
Register File	PASS
Immediate Generator	PASS
ALU	14/14 PASS
Main Control Unit	PASS
ALU Control	PASS
Basic CPU Integration	7/7 PASS
Extended CPU Integration	9/9 PASS
GTKWave Waveform	PASS
14. Tools
HDL
SystemVerilog

Simulator
Icarus Verilog

Waveform Analysis
GTKWave

Development Environment
Visual Studio Code
Windows
Git
GitHub
15. Project Structure
03_Single_Cycle_RV32I_CPU/
│
├── rtl/
│   ├── alu.sv
│   ├── alu_control.sv
│   ├── control_unit.sv
│   ├── immediate_generator.sv
│   ├── instruction_memory.sv
│   ├── pc.sv
│   ├── register_file.sv
│   └── rv32i_cpu.sv
│
├── tb/
│   ├── alu_tb.sv
│   ├── alu_control_tb.sv
│   ├── control_unit_tb.sv
│   ├── immediate_generator_tb.sv
│   ├── instruction_memory_tb.sv
│   ├── register_file_tb.sv
│   ├── pc_tb.sv
│   ├── rv32i_cpu_tb.sv
│   └── rv32i_cpu_extended_tb.sv
│
├── docs/
│   ├── VERIFICATION.md
│   └── README.md
│
├── screenshots/
│   └── rv32i_cpu_extended_waveform.png
│
└── waveform/
    └── rv32i_cpu_extended_wave.vcd
    16. How to Run
From the project directory:
iverilog -g2012 -o rv32i_cpu_test rtl/pc.sv rtl/instruction_memory.sv rtl/register_file.sv rtl/immediate_generator.sv rtl/alu.sv rtl/control_unit.sv rtl/alu_control.sv rtl/rv32i_cpu.sv tb/rv32i_cpu_tb.sv

Run:
vvp .\rv32i_cpu_test

For the extended verification:
iverilog -g2012 -o rv32i_cpu_extended_test rtl/pc.sv rtl/instruction_memory.sv rtl/register_file.sv rtl/immediate_generator.sv rtl/alu.sv rtl/control_unit.sv rtl/alu_control.sv rtl/rv32i_cpu.sv tb/rv32i_cpu_extended_tb.sv

Run:
vvp .\rv32i_cpu_extended_test

Expected extended result:
TOTAL TESTS = 9
PASSED      = 9
FAILED      = 0
17. Current Limitations
This implementation is intentionally a compact single-cycle processor.
Current limitations include:
- Limited verified RV32I instruction subset
- No pipelining
- No hazard-management unit
- No caches
- No interrupts or exceptions
- No CSR subsystem
- No privilege modes
- Basic simulation memories
- Directed verification rather than a constrained-random verification
  environment
These limitations are intentional and provide a clear path for future
architectural extensions.
18. Future Development
Potential future extensions include:
1. Expand the supported RV32I instruction subset.
2. Add JAL and JALR.
3. Add additional load/store instructions.
4. Add automated program-level regression tests.
5. Add randomized ALU verification.
6. Add assertion-based verification.
7. Add functional coverage.
8. Synthesize the complete CPU.
9. Analyze timing and resource utilization.
10. Develop a 5-stage pipelined RV32I processor.
The planned pipelined implementation can reuse several verified concepts
from this single-cycle processor.
19. Engineering Skills Demonstrated
This project demonstrates practical experience in:
- RTL design
- SystemVerilog
- RISC-V ISA concepts
- CPU datapath design
- Control-path design
- ALU design
- Register-file design
- Immediate decoding
- Branch target calculation
- Memory interfacing
- Testbench development
- Directed verification
- Debugging simulation failures
- Waveform analysis
- Git-based project organization
20. Final Result
The implemented single-cycle RV32I CPU successfully passed both basic and
extended integration verification.
Final verified results:
ALU:
14/14 PASS

Basic CPU Integration:
7/7 PASS

Extended CPU Integration:
9/9 PASS

The project provides a complete RTL-to-verification workflow and forms the
foundation for subsequent pipelined CPU and hardware-verification work.