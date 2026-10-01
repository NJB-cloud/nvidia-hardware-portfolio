# RV32I ALU Design Using SystemVerilog

## Overview

This project implements a **32-bit RV32I compatible Arithmetic Logic Unit (ALU)** using SystemVerilog.

The ALU is designed as a fundamental datapath component for a RISC-V processor and supports multiple arithmetic, logical, shift, and comparison operations.

The design is verified using an automated SystemVerilog testbench. Simulation results are analyzed through waveform visualization using GTKWave.

---

# Features

The implemented ALU supports the following operations:

- 32-bit arithmetic processing
- RV32I compatible operation selection
- Addition
- Subtraction
- Bitwise AND
- Bitwise OR
- Bitwise XOR
- Logical Shift Left
- Logical Shift Right
- Set Less Than comparison
- Carry flag generation
- Zero flag generation

---

# ALU Operation Mapping

| ALU Select | Operation |
|------------|-----------|
| 4'b0000 | Addition |
| 4'b0001 | Subtraction |
| 4'b0010 | AND |
| 4'b0011 | OR |
| 4'b0100 | XOR |
| 4'b0101 | Logical Shift Left |
| 4'b0110 | Logical Shift Right |
| 4'b0111 | Set Less Than |

---

# Design Architecture

The project follows a standard RTL hardware design flow:
Specification
      |
      ↓
SystemVerilog RTL Design
      |
      ↓
Testbench Development
      |
      ↓
Functional Simulation
      |
      ↓
Waveform Analysis using GTKWave

---

# Project Structure
01_RV32I_ALU_RegisterFile
│
├── rtl
│   └── rv32i_alu.sv
│
├── tb
│   └── tb_rv32i_alu.sv
│
├── waveform
│   └── alu_wave.vcd
│
├── screenshots
│   ├── rtl_code1.png
│   ├── rtl_code2.png
│   ├── rtl_code3.png
│   ├── simulation_pass.png
│   └── gtkwave.png
│
└── README.md

---

# RTL Design Description

The ALU receives two 32-bit operands:
Input:
a[31:0]
b[31:0]
Control:
alu_sel[3:0]
Output:
result[31:0]
carry
zero

The `alu_sel` control signal determines which operation is performed.

The output flags provide additional information:

- **Carry Flag:** Indicates carry generation during arithmetic addition.
- **Zero Flag:** Indicates whether the output result is equal to zero.

---

# Verification Methodology

The design was verified using a dedicated SystemVerilog testbench.

Verification includes:

- Applying multiple input combinations
- Testing all supported ALU operations
- Comparing simulation results with expected values
- Generating waveform output for signal verification

---

# Simulation Result

The simulation was performed using **Icarus Verilog**.

All implemented ALU operations passed successfully.

Simulation output:
==== RV32I ALU VERIFICATION START ====
PASS: All ALU operations verified
==== TEST COMPLETE ====

Waveform signals were verified using GTKWave.

---

# Tools Used

- SystemVerilog
- Icarus Verilog
- GTKWave
- Visual Studio Code

---

# Skills Demonstrated

This project demonstrates:

- RTL hardware design
- Digital logic implementation
- SystemVerilog programming
- Testbench development
- Functional verification
- Waveform debugging
- RISC-V processor component design

---

# Future Improvements

Possible future extensions:

- Integration with a complete RV32I processor datapath
- Addition of multiplication and division units
- Pipeline integration
- FPGA implementation and hardware testing

---

# Author

**EEE Project - RTL Hardware Design**
