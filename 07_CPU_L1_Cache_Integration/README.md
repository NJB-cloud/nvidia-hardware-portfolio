Project 7: RV32I CPU + L1 Cache Integration
Overview
This project integrates a custom 5-stage RV32I pipelined processor with a dedicated L1 cache memory subsystem.
The objective is to demonstrate a complete processor-memory hierarchy interaction similar to modern SoC architectures, including instruction execution, load/store operations, cache communication, and pipeline control during memory transactions.
Architecture
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

Processor Features
Implemented a 5-stage RV32I processor pipeline:
- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)
Pipeline Features
Implemented:
- Pipeline registers
- Data forwarding unit
- Hazard detection unit
- Branch handling
- Load/store execution
- Memory transaction control
Supported RV32I Instructions
Arithmetic Instructions
- ADD
- SUB
- AND
- OR
- XOR
- SLT
Immediate Instruction
- ADDI
Memory Instructions
- LW
- SW
Branch Instruction
- BEQ
L1 Cache Integration
The processor is connected to a custom L1 cache subsystem.
Implemented features:
- CPU-to-cache request interface
- Cache request handshake protocol
- Read transaction support
- Write transaction support
- Cache response signaling
- Pipeline stall mechanism during memory transactions
- Cache controller communication
- Memory model integration
Verification Program
The integrated CPU-cache system was tested using the following RV32I program:
ADDI x1, x0, 16
ADDI x2, x0, 123
SW   x2, 0(x1)
LW   x3, 0(x1)
ADD  x4, x3, x2

Target Register Results
x1 = 16
x2 = 123
x3 = 123
x4 = 246

The test program verifies:
- Immediate instruction execution
- Register write-back path
- Store operation flow
- Load operation flow
- Processor datapath communication
- Pipeline execution behavior
Design Tools
Tool	Purpose
SystemVerilog	RTL Design
Icarus Verilog	Functional Simulation
GTKWave	Waveform Analysis


Project Status
✅ RV32I CPU pipeline implemented
✅ Pipeline registers integrated
✅ Forwarding and hazard control implemented
✅ L1 cache interface integrated
✅ Cache control logic implemented
✅ RTL compilation completed
✅ Simulation environment completed  
This project demonstrates processor architecture and memory subsystem integration as part of a hardware design portfolio.
Future Improvements
Planned enhancements:
- Cache hit/miss performance counters
- Automated assertion-based verification
- Extended RV32I instruction coverage
- FPGA synthesis and timing analysis
- Complete waveform-based verification reports
Repository Structure
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
│   └── simulation reports
│
├── screenshots/
│   └── verification evidence
│
└── README.md

Author
Hardware Design Portfolio