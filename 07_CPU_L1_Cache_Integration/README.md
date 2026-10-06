# RV32I Pipelined CPU + L1 Cache Integration

### SystemVerilog | RISC-V Architecture | Processor Memory Hierarchy | Hardware Verification

---

# Overview

This project integrates a custom **5-stage RV32I pipelined processor** with a dedicated **L1 cache memory subsystem** using SystemVerilog.

The objective is to demonstrate a complete processor-memory hierarchy interaction similar to modern SoC architectures, including:

- Instruction execution
- Load/store operations
- Cache communication
- Memory transactions
- Pipeline control during memory access

This project focuses on:

- RTL design
- Processor architecture
- Memory subsystem integration
- Hardware verification through simulation and waveform analysis

---

# System Architecture

The integrated system consists of:

```
Instruction Memory
        |
        |
     IF Stage
        |
   IF/ID Register
        |
     ID Stage
        |
   ID/EX Register
        |
     EX Stage
        |
  EX/MEM Register
        |
 L1 Cache Interface
        |
 Cache Controller
        |
   L1 Data Cache
        |
 Memory Model
        |
  MEM/WB Register
        |
 Register File
```

High-level data flow:

```
CPU Core → L1 Cache Controller → L1 Data Cache → Memory Model
```

---

# Processor Architecture

The processor implements a classic **5-stage RV32I pipeline**:

## Pipeline Stages

### 1. Instruction Fetch (IF)
- Program counter management
- Instruction memory access

### 2. Instruction Decode (ID)
- Instruction decoding
- Register file access
- Immediate generation

### 3. Execute (EX)
- ALU operations
- Branch calculation
- Pipeline forwarding support

### 4. Memory Access (MEM)
- Load/store execution
- Cache communication

### 5. Write Back (WB)
- Register update
- Final instruction completion

---

# Pipeline Features Implemented

The processor includes:

- Pipeline registers
- Data forwarding unit
- Hazard detection unit
- Branch handling
- Load/store execution
- Memory transaction control
- Pipeline stall mechanism during memory transactions

---

# Supported RV32I Instructions

## Arithmetic Instructions

Implemented:

- ADD
- SUB
- AND
- OR
- XOR
- SLT

## Immediate Instructions

Implemented:

- ADDI

## Memory Instructions

Implemented:

- LW
- SW

## Branch Instruction

Implemented:

- BEQ

---

# L1 Cache Integration

The processor is connected to a custom L1 cache subsystem.

Implemented cache features:

- CPU-to-cache request interface
- Cache request handshake protocol
- Read transaction support
- Write transaction support
- Cache response signaling
- Cache controller communication
- Memory model integration
- Pipeline control during memory transactions

---

# RTL Design Components

## Processor Core

Main processor modules:

- `pipelined_core_cache.sv`
- `alu.sv`
- `alu_control.sv`
- `control_unit.sv`
- `register_file.sv`
- `pc.sv`

---

## Pipeline Control

Pipeline management modules:

- `if_id_reg.sv`
- `id_ex_reg.sv`
- `ex_mem_reg.sv`
- `mem_wb_reg.sv`
- `hazard_unit.sv`
- `forwarding_unit.sv`

---

## Cache Memory Subsystem

Cache-related modules:

- `l1_cache.sv`
- `cache_controller.sv`
- `cache_tag_array.sv`
- `cache_data_array.sv`
- `memory_model.sv`

---

# Verification Strategy

The integrated CPU-cache system was verified using **SystemVerilog-based simulation**.

Verification focused on:

- Instruction execution validation
- Register write-back verification
- Load/store transaction checking
- Cache communication validation
- Processor datapath verification
- Pipeline execution behavior
- Waveform-based debugging

---

# Verification Program

The CPU-cache system was tested using the following RV32I instruction sequence:

```assembly
ADDI x1, x0, 16
ADDI x2, x0, 123
SW   x2, 0(x1)
LW   x3, 0(x1)
ADD  x4, x3, x2
```

---

# Expected Register Results

After successful execution:

```
x1 = 16
x2 = 123
x3 = 123
x4 = 246
```

The test program validates:

- Immediate instruction execution
- Register write-back path
- Store operation flow
- Load operation flow
- Processor datapath communication
- Pipeline execution behavior

---

# Simulation Tools

| Tool | Purpose |
|---|---|
| SystemVerilog | RTL design and verification |
| Icarus Verilog | Functional simulation |
| GTKWave | Waveform analysis |

---

# Project Status

✅ RV32I CPU pipeline implemented  
✅ Pipeline registers integrated  
✅ Forwarding logic implemented  
✅ Hazard detection implemented  
✅ L1 cache interface integrated  
✅ Cache control logic implemented  
✅ RTL compilation completed  
✅ Simulation environment completed  

---

# Engineering Skills Demonstrated

This project demonstrates practical experience in:

- RTL design using SystemVerilog
- RISC-V processor architecture
- 5-stage pipeline implementation
- Hazard and forwarding control
- Cache memory subsystem design
- Processor-memory interface design
- Simulation-based hardware verification

---

# Repository Structure

```
07_CPU_L1_Cache_Integration/

├── rtl/
│   ├── pipelined_core_cache.sv
│   ├── cache interface modules
│   ├── pipeline registers
│   └── CPU datapath modules
│
├── tb/
│   └── project7_cache_integration_tb.sv
│
├── reports/
│   └── Simulation logs, verification results, and future synthesis reports
│
├── screenshots/
│   └── Verification evidence and waveform screenshots
│
└── README.md
```

---

# Future Improvements

Planned enhancements:

- Cache hit/miss performance counters
- Automated assertion-based verification
- Extended RV32I instruction coverage
- Functional coverage implementation
- FPGA synthesis and timing analysis
- Complete waveform-based verification reports

---

# Author

Hardware Design & Verification Portfolio
