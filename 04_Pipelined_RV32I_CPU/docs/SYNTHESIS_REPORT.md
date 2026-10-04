# RV32I 5-Stage Pipeline CPU
# Synthesis Report

## 1. Overview

This document summarizes the synthesis results of the 5-stage pipelined RV32I processor.

The processor implements:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

Supported instructions:

- ADD
- SUB
- AND
- OR
- XOR
- SLT
- LW
- SW
- BEQ

---

# 2. Synthesis Flow

Tool:

- Yosys Open Synthesis Suite

Flow:
SystemVerilog RTL
        |
        v
Yosys RTL synthesis
        |
        v
Optimization passes
        |
        v
Technology-independent statistics

---

# 3. Top-Level Hardware Statistics

| Parameter | Value |
|---|---:|
| Top Module | pipelined_core |
| Total Cells | 25,477 |
| Multiplexers | 8,693 |
| AND gates | 3,797 |
| OR gates | 2,785 |
| XOR gates | 260 |
| Flip-flop cells | 9,571 |

---

# 4. Major Hardware Blocks

## Register File

The register file contributes significant hardware because it is implemented using synthesizable logic.

Cells:

5478

---

## Arithmetic Logic Unit

The ALU contains:

- arithmetic operations
- logical operations
- comparison logic

Cells:

904

---

## Pipeline Storage

Pipeline registers:

| Stage Register | Cells |
|---|---:|
| IF/ID | 99 |
| ID/EX | 190 |
| EX/MEM | 76 |
| MEM/WB | 72 |

---

# 5. Design Observations

The largest contributors are:

1. Register file implementation
2. Pipeline data paths
3. Operand forwarding logic

The forwarding network increases hardware complexity but improves performance by reducing pipeline stalls.

---

# 6. Future Optimization Possibilities

Possible improvements:

- Replace flip-flop register file with SRAM macro
- Add branch prediction
- Optimize forwarding multiplexers
- Add instruction cache
- Perform FPGA mapping

---

# 7. Conclusion

The RV32I processor has successfully completed:

- RTL implementation
- Functional verification
- Assertion verification
- Coverage verification
- Randomized verification
- Logic synthesis

This demonstrates a complete hardware development workflow.