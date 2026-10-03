# 5-Stage Pipelined RV32I CPU — Architecture Specification

## 1. Project Objective

Project 4 extends the previously implemented single-cycle RV32I processor into
a five-stage pipelined processor.

The objective is to demonstrate understanding and implementation of:

- Instruction pipelining
- Pipeline registers
- Data hazards
- Forwarding
- Load-use hazard detection
- Pipeline stalls
- Branch hazards
- Pipeline flushing
- Control-signal propagation
- Program-level verification

The design is intended as an undergraduate computer-architecture and RTL
portfolio project with emphasis on reproducible SystemVerilog implementation,
simulation, debugging, and verification.

---

## 2. Pipeline Architecture

The processor uses five classic pipeline stages:

1. IF  — Instruction Fetch
2. ID  — Instruction Decode
3. EX  — Execute
4. MEM — Memory Access
5. WB  — Write Back

The high-level flow is:

    IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB

Each pipeline boundary stores the information required by the following stage.

---

## 3. Instruction Subset

Project 4 initially supports the same verified instruction subset as Project 3.

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

The processor does not claim complete RV32I ISA coverage.

Unsupported instructions must produce safe control behavior.

---

## 4. IF Stage — Instruction Fetch

The IF stage performs:

- Program-counter selection
- Instruction-memory access
- PC + 4 calculation

The default next PC is:

    PC + 4

For a taken BEQ:

    next PC = branch target

The branch target is calculated in the EX stage.

### IF outputs

The IF stage provides:

- Current PC
- PC + 4
- Instruction

These values are captured by the IF/ID pipeline register.

---

## 5. IF/ID Pipeline Register

The IF/ID register stores:

- PC
- PC + 4
- Instruction
- Valid/control information as required

### Normal operation

On every clock cycle:

    IF outputs → IF/ID register

### Stall operation

When a load-use hazard is detected:

- PC is held
- IF/ID register is held
- A bubble is inserted into ID/EX

This prevents the dependent instruction from advancing until its
source operand becomes available.

### Flush operation

When a taken branch is detected:

- The wrong-path instruction in IF/ID is invalidated
- The appropriate younger instruction is prevented from executing

---

## 6. ID Stage — Instruction Decode

The ID stage performs:

- Instruction decoding
- Register-file reads
- Immediate generation
- Main control generation
- Register-index extraction

The following values are generated:

- rs1
- rs2
- rd
- funct3
- funct7
- register operand 1
- register operand 2
- immediate
- control signals

The decoded information is captured by the ID/EX pipeline register.

---

## 7. ID/EX Pipeline Register

The ID/EX register carries information from ID to EX.

It contains, at minimum:

### Data

- PC
- PC + 4
- Register operand 1
- Register operand 2
- Immediate

### Register identifiers

- rs1
- rs2
- rd

### Instruction fields

- funct3
- funct7_bit5

### Control

- RegWrite
- ALUSrc
- MemRead
- MemWrite
- MemToReg
- Branch
- ALUOp

A valid bit may be used to simplify bubble and flush handling.

---

## 8. EX Stage — Execute

The EX stage performs:

- ALU operation
- ALU operand selection
- Forwarding
- Branch comparison
- Branch-target calculation

### ALU operand A

The normal operand is the value from ID/EX.

It may be replaced by a forwarded value.

### ALU operand B

For R-type and BEQ:

    operand B = register operand

For LW and SW:

    operand B = immediate

The selected operand may also receive a forwarded value when required.

---

## 9. Forwarding Unit

The forwarding unit resolves data hazards where a required result already
exists in a later pipeline stage.

The forwarding logic examines:

- ID/EX.rs1
- ID/EX.rs2
- EX/MEM.rd
- MEM/WB.rd
- EX/MEM.RegWrite
- MEM/WB.RegWrite

### Forwarding priority

The newest available result has priority.

Therefore:

1. EX/MEM forwarding
2. MEM/WB forwarding
3. Register-file value

### Example

    ADD x3, x1, x2
    SUB x4, x3, x1

The SUB instruction requires x3 before it has been written back to the
register file.

The forwarding unit supplies the newly calculated x3 directly to the EX stage.

---

## 10. Store-Data Forwarding

Store instructions require special consideration.

Example:

    ADD x3, x1, x2
    SW  x3, 0(x0)

The value of x3 must be correctly propagated to the store operation.

The design therefore provides forwarding for store data where necessary.

The store-data path may select the most recent value from:

- ID/EX register operand
- EX/MEM result
- MEM/WB write-back result

This prevents stale register values from being written to data memory.

---

## 11. Load-Use Hazard

Forwarding alone cannot completely resolve a load-use dependency.

Example:

    LW  x3, 0(x1)
    ADD x4, x3, x2

The loaded data becomes available too late for the immediately following
instruction's EX stage.

The hazard detection unit must therefore insert a stall.

### Required behavior

When:

    ID/EX.MemRead = 1

and:

    ID/EX.rd == IF/ID.rs1

or:

    ID/EX.rd == IF/ID.rs2

for an instruction that actually uses the corresponding source register:

- Freeze PC
- Freeze IF/ID
- Insert a bubble into ID/EX

After the required stall, normal forwarding resumes.

Register x0 must be ignored when determining a true dependency.

---

## 12. Hazard Detection Unit

The hazard detection unit is responsible for detecting pipeline hazards
that cannot be solved through forwarding alone.

Primary responsibility:

### Load-use hazard detection

Inputs include:

- ID/EX.MemRead
- ID/EX.rd
- IF/ID.rs1
- IF/ID.rs2
- Instruction-use information

Outputs include:

- PCWrite
- IF_ID_Write
- ID_EX_Flush / control-bubble signal

### Stall policy

When a load-use hazard is detected:

    PCWrite      = 0
    IF_ID_Write  = 0
    ID_EX control = 0

This inserts one bubble while preserving the stalled instruction.

---

## 13. EX/MEM Pipeline Register

The EX/MEM register carries execution results into the memory stage.

It contains, at minimum:

### Data

- ALU result
- Store data
- Branch-related information

### Register

- rd

### Control

- RegWrite
- MemRead
- MemWrite
- MemToReg

The store-data path must contain the correctly forwarded value.

---

## 14. MEM Stage — Memory Access

The MEM stage performs:

### LW

    memory read

### SW

    memory write

For normal ALU instructions:

    no memory operation

The data-memory address is supplied by the ALU result.

Word-aligned addressing is used.

---

## 15. MEM/WB Pipeline Register

The MEM/WB register carries the final result toward write-back.

It contains:

### Data

- ALU result
- Memory read data

### Register

- rd

### Control

- RegWrite
- MemToReg

---

## 16. WB Stage — Write Back

The WB stage selects between:

### ALU instruction

    writeback_data = ALU result

### LW

    writeback_data = memory read data

When RegWrite is asserted, the selected value is written to rd.

Register x0 must remain permanently zero.

---

## 17. Branch Handling

The initial branch instruction is:

    BEQ

The branch condition is:

    rs1 == rs2

The comparison is performed in EX.

The branch target is:

    ID/EX.PC + immediate

When BEQ is taken:

    next PC = branch target

Otherwise:

    next PC = PC + 4

---

## 18. Taken-Branch Flush Policy

Because the branch decision is made in EX, younger instructions may already
exist in earlier pipeline stages.

When a BEQ is taken:

- The incorrect sequential-path instructions must not modify architectural
  state.
- Younger pipeline instructions are flushed.
- The PC is redirected to the branch target.

The implementation must explicitly demonstrate that wrong-path instructions
do not perform register or memory writes.

---

## 19. Pipeline Control Signals

The pipeline must explicitly support:

- Normal advance
- Stall
- Bubble insertion
- Flush
- Forwarding

Control signals must travel through the pipeline registers with the
instructions they belong to.

A flushed instruction must have harmless control values.

In particular, a flushed instruction must not assert:

    RegWrite
    MemWrite

---

## 20. Hazard Cases to Verify

The verification environment must explicitly test:

### ALU → ALU

    ADD x3,x1,x2
    SUB x4,x3,x1

### ALU → ALU with multiple dependencies

    ADD x3,x1,x2
    SUB x4,x3,x1
    XOR x5,x4,x3

### MEM/WB → EX

A dependency where the required value is available from the WB path.

### Load → Use

    LW  x3,0(x1)
    ADD x4,x3,x2

This must cause a stall.

### Load → Store

    LW x3,0(x1)
    SW x3,0(x2)

The correct loaded value must reach the store.

### ALU → Store

    ADD x3,x1,x2
    SW  x3,0(x0)

Store data must be correctly forwarded.

### Branch dependency

    ADD x3,x1,x2
    BEQ x3,x4,target

The branch must receive the correct value.

### Taken branch

The wrong-path instruction must be flushed.

### Not-taken branch

Sequential execution must continue normally.

### x0 dependency

Dependencies involving x0 must not cause unnecessary forwarding or stalls.

---

## 21. Verification Strategy

Verification will be performed at multiple levels.

### Level 1 — Unit Verification

Independently verify:

- Forwarding Unit
- Hazard Detection Unit
- Pipeline Registers
- ALU
- Control Unit

### Level 2 — Pipeline Integration

Verify:

- Sequential execution
- Arithmetic operations
- Logical operations
- Memory operations
- Branches
- Pipeline progression

### Level 3 — Hazard Verification

Verify:

- EX forwarding
- MEM forwarding
- Load-use stall
- Store-data forwarding
- Branch forwarding
- Pipeline flush

### Level 4 — Program-Level Regression

Create a collection of independent programs covering the implemented
instruction subset and hazard cases.

Every program must have:

- Program description
- Expected result
- Automated PASS/FAIL check

### Level 5 — Waveform Inspection

GTKWave will be used to inspect:

- PC
- Instruction
- Pipeline registers
- Forwarding controls
- Hazard controls
- Stall signals
- Flush signals
- ALU results
- Memory operations
- Register write-back

---

## 22. Verification Evidence

The final project should contain:

- Unit testbenches
- Pipeline integration testbench
- Hazard tests
- Regression testbench
- Test plan
- Verification report
- Waveform evidence
- Debugging records
- Reproducible simulation commands

Where supported by the simulation environment, additional verification
evidence will include:

- SystemVerilog assertions
- Functional coverage
- Randomized stimulus

These will supplement, rather than replace, directed architectural tests.

---

## 23. Performance Observations

The project will record basic pipeline behavior including:

- Number of executed instructions
- Number of cycles
- Number of stalls
- Number of taken branches
- Number of flushes

The purpose is to demonstrate the behavioral effect of pipelining and hazards.

No unsupported performance claim will be made without measured simulation
evidence.

---

## 24. Design Constraints

The project remains an educational undergraduate RTL implementation.

It does not initially include:

- Full RV32I ISA
- Superscalar execution
- Out-of-order execution
- Caches
- Branch prediction
- Interrupt subsystem
- CSR subsystem
- Privilege modes
- Exceptions
- MMU
- Operating-system support

The project will focus on correctly implementing and verifying the selected
five-stage pipeline.

---

## 25. Engineering Goals

The implementation should demonstrate:

1. Clean modular RTL
2. Explicit pipeline boundaries
3. Correct hazard handling
4. Correct forwarding
5. Correct stall behavior
6. Correct branch flushing
7. Reproducible simulation
8. Automated verification
9. Waveform-based debugging
10. Clear technical documentation

The design should prioritize correctness and observability over unnecessary
architectural complexity.

---

## 26. Project Success Criteria

Project 4 will be considered complete only when all of the following have
been demonstrated:

- Five-stage pipeline operates correctly
- Pipeline registers operate correctly
- Supported instructions execute correctly
- Forwarding works correctly
- Load-use hazards produce the required stall
- Branches execute correctly
- Taken branches flush wrong-path instructions
- Store data dependencies are handled correctly
- x0 remains protected
- Directed tests pass
- Hazard tests pass
- Program-level regression passes
- Waveforms provide evidence of pipeline behavior
- Verification documentation is complete
- RTL and verification artifacts are reproducible
- Final implementation is committed to version control

---

## 27. Final Scope Statement

This project is a five-stage pipelined RV32I-subset processor developed in
SystemVerilog.

The primary engineering focus is the transition from a single-cycle
processor to a pipelined processor with explicit handling of:

    Pipeline Registers
    Forwarding
    Hazard Detection
    Stalls
    Branch Flushes
    Memory Hazards
    Program-Level Verification

The project is intended to demonstrate undergraduate-level capability in
digital design, computer architecture, SystemVerilog RTL development,
verification, debugging, and hardware-oriented engineering practice.