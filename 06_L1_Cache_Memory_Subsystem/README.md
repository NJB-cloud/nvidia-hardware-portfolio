# L1 Cache Memory Subsystem

A synthesizable SystemVerilog implementation of an L1 cache subsystem with
cache hit/miss handling, line refill, dirty-line write-back, conflict
eviction, byte-enable writes, randomized verification, assertions,
functional coverage, performance regression, and ECP5 FPGA implementation.

---

## 1. Project Overview

This project implements a small L1 cache/memory subsystem intended to sit
between a CPU-side request interface and a backing memory interface.

The design demonstrates:

- Cache tag and data storage
- Cache hit detection
- Read misses
- Cache-line refill
- Dirty-line tracking
- Dirty-line write-back
- Conflict eviction
- Byte-enable writes
- CPU response generation
- Memory request generation
- Directed verification
- Randomized regression
- Assertion-based verification
- Functional coverage
- Performance measurement
- FPGA synthesis
- FPGA placement and routing
- Post-place-and-route timing analysis

The project was developed as part of an undergraduate hardware/computer
architecture portfolio with emphasis on RTL design, verification,
debugging, synthesis, and implementation.

---

## 2. High-Level Architecture

```text
                    CPU-SIDE INTERFACE
                           |
                           v
                +-----------------------+
                |      L1 CACHE         |
                |                       |
                |  +-----------------+  |
                |  | Cache Controller|  |
                |  +-----------------+  |
                |           |           |
                |     +-----+-----+     |
                |     |           |     |
                |     v           v     |
                |  Tag Array   Data Array
                |     |           |     |
                |     +-----+-----+     |
                |           |           |
                |       Hit/Miss        |
                |       Detection       |
                |           |           |
                |    Refill / Writeback |
                +-----------+-----------+
                            |
                            v
                    MEMORY-SIDE INTERFACE
The cache separates control behavior from tag and data storage. The
controller coordinates CPU requests, cache hits, misses, refills, and
dirty-line write-back operations.
3. Main RTL Components
rtl/l1_cache.sv
Top-level L1 cache module.
Responsible for integrating:
- CPU request interface
- Cache controller
- Tag array
- Data array
- Refill path
- Write-back path
- CPU response generation
rtl/cache_controller.sv
Implements the cache control state machine.
Coordinates:
- Hit handling
- Read misses
- Refill
- Dirty eviction
- Write-back
- Memory transactions
rtl/cache_tag_array.sv
Stores cache tags and associated cache-line metadata.
rtl/cache_data_array.sv
Stores cache-line data and implements the word/byte write path.
rtl/memory_model.sv
Simulation-side backing memory model used by the verification environment.
4. Cache Data Path
The cache was verified using four word offsets within a cache line.
The data-path regression verified:
Word 0 -> address + 0x00
Word 1 -> address + 0x04
Word 2 -> address + 0x08
Word 3 -> address + 0x0C

The regression successfully verified all four word offsets.
5. Byte-Enable Writes
The data path supports byte-enable writes.
The following byte-enable patterns were explicitly verified:
BE = 0001
BE = 0010
BE = 0100
BE = 1000
BE = 1111

The byte-enable regression demonstrated correct partial-word updates without
overwriting unaffected bytes.
6. Cache Hit and Miss Behavior
The verification environment checks both invalid-line behavior and
cache-hit behavior.
An invalid cache line must not produce a cache hit.
The refill regression verifies the complete sequence:
CPU request
    |
    v
Cache miss
    |
    v
Memory refill request
    |
    v
Cache line installed
    |
    v
CPU response
    |
    v
Repeated access
    |
    v
Cache hit

The miss/refill/hit sequence passed successfully.
7. Dirty Eviction and Write-Back
The cache supports dirty-line handling.
The verified sequence is:
Read miss
    ↓
Cache line refill
    ↓
Write hit
    ↓
Line becomes dirty
    ↓
Conflicting access
    ↓
Dirty victim detected
    ↓
Write-back to memory
    ↓
New cache line refill
    ↓
New access succeeds

The dirty-eviction regression verified:
- Read miss
- Write hit
- Dirty victim
- Write-back
- Conflict refill
- Preservation of modified memory data
The test generated exactly one write-back for the dirty victim.
8. Verification Strategy
The project uses multiple levels of verification rather than relying on a
single testbench.
Directed tests
Dedicated testbenches cover:
- Initial cache hit/miss behavior
- Refill behavior
- Dirty eviction
- Data-path operations
- Byte enables
- Performance
Randomized regression
A randomized regression exercises different combinations of:
- Read operations
- Write operations
- Addresses
- Word offsets
- Byte enables
- Cache conflicts
- Refills
- Write-backs
The randomized regression completed successfully.
Assertion-based verification
The assertion regression reported:
Checks    : 1310
Failures  : 0
Result    : ASSERTIONS PASS

This provides an additional layer of protocol and behavioral checking
beyond the directed testbenches.
9. Functional Coverage
The functional coverage regression explicitly covered:
- Word offset 0
- Word offset 1
- Word offset 2
- Word offset 3
- Byte enable 0001
- Byte enable 0010
- Byte enable 0100
- Byte enable 1000
- Byte enable 1111
- Conflict access
- Memory refill
- Write-back
The regression reported:
FUNCTIONAL COVERAGE RESULT: PASS
ALL TARGET SCENARIOS COVERED

10. Performance Regression
The performance regression measured cache access latency.
Observed behavior included:
Cache hit   -> 1 cycle
Cache miss  -> multiple cycles depending on refill/write-back behavior

The completed regression reported:
Total CPU accesses   : 25
Read accesses        : 17
Write accesses       : 8

Hits                 : 15
Misses               : 10

Hit rate             : 60.00%
Miss rate            : 40.00%

Memory refills       : 10
Memory write-backs   : 2

Total latency        : 67 cycles
Minimum latency      : 1 cycle
Maximum latency      : 6 cycles
Average latency      : 2.68 cycles

The performance regression passed.
11. ECP5 FPGA Synthesis
The cache was synthesized for a Lattice ECP5 target using Yosys.
The synthesis flow was adapted to use conventional ABC LUT mapping instead
of the problematic ABC9 stage in the installed Yosys environment.
The final technology-mapped JSON contained:
LUT4                 : 5,026
TRELLIS_DPR16X4      :   128
TRELLIS_FF           : 1,740

No generic $_NOT_ or generic DFFE cells remained in the final
nextpnr-compatible JSON netlist.
12. ECP5 Implementation
The technology-mapped design was successfully processed by
nextpnr-ecp5 targeting an ECP5-85F device.
The implementation flow completed normally:
JSON netlist
     ↓
Packing
     ↓
Placement
     ↓
Routing
     ↓
Timing analysis

The implementation was performed out-of-context because this project is
focused on the cache subsystem as a reusable hardware block rather than a
complete board-level FPGA design.
13. Post-Place-and-Route Resource Utilization
Final implementation resource usage:
Resource	Used	Available	Utilization
TRELLIS_COMB	5,795	83,640	6.93%
TRELLIS_FF	1,740	83,640	2.08%
TRELLIS_RAMW	128	10,455	1.22%
DP16KD	0	208	0%
MULT18X18D	0	156	0%
ALU54B	0	78	0%


14. Post-Place-and-Route Timing
The final nextpnr implementation achieved:
Maximum measured frequency:
49.42 MHz

The implementation was evaluated against a:
12 MHz timing constraint

The corresponding period at 49.42 MHz is approximately:
20.24 ns

The reported result therefore comfortably meets the 12 MHz implementation
constraint.
This is a measured post-place-and-route result for the specific ECP5
device, implementation configuration, and placement/routing generated by
nextpnr. It should not be interpreted as a universal theoretical maximum
frequency for every implementation of the cache.
15. Critical-Path Engineering Analysis
Post-route timing analysis identified cache address/tag/control/data-path
logic among the important timing contributors.
A representative path includes signals associated with:
CPU address
    ↓
Tag comparison
    ↓
Cache-hit detection
    ↓
Write-hit control
    ↓
Data write/control
    ↓
Sequential enable

The implementation demonstrates that cache timing is influenced not only by
logic depth but also by FPGA routing.
This creates several possible future optimization directions:
1. Reduce tag-comparison logic depth.
2. Simplify cache-hit control logic.
3. Improve placement locality between tag/data/control structures.
4. Reduce unnecessary control fanout.
5. Investigate alternative cache organizations.
6. Compare timing/resource trade-offs after each optimization.
16. Verification Artifacts
Waveform evidence is stored in:
waveforms/

including:
cache_hit.vcd
cache_refill.vcd
cache_dirty_eviction.vcd
cache_data_path.vcd
cache_random_regression.vcd
cache_coverage.vcd
cache_performance.vcd

These waveforms can be opened with GTKWave.
17. Repository Structure
06_L1_Cache_Memory_Subsystem/
│
├── rtl/
│   ├── cache_controller.sv
│   ├── cache_data_array.sv
│   ├── cache_tag_array.sv
│   ├── l1_cache.sv
│   └── memory_model.sv
│
├── tb/
│   ├── cache_assertions.sv
│   ├── cache_coverage_testbench.sv
│   ├── cache_data_path_testbench.sv
│   ├── cache_dirty_eviction_testbench.sv
│   ├── cache_hit_testbench.sv
│   ├── cache_performance_testbench.sv
│   ├── cache_random_regression_testbench.sv
│   └── cache_refill_testbench.sv
│
├── docs/
│   ├── CACHE_INTERFACE.md
│   └── CACHE_SPECIFICATION.md
│
├── waveforms/
│   ├── cache_hit.vcd
│   ├── cache_refill.vcd
│   ├── cache_dirty_eviction.vcd
│   ├── cache_data_path.vcd
│   ├── cache_random_regression.vcd
│   ├── cache_coverage.vcd
│   └── cache_performance.vcd
│
├── synthesis.ys
├── synthesis_ecp5.ys
├── synthesis_l1_cache.v
├── ecp5_synthesis_final.log
├── l1_cache_ecp5.json
├── l1_cache_ecp5_pre_lut.json
├── l1_cache_placed.json
├── l1_cache_nextpnr_report.json
└── README.md

18. Tools
The project uses:
- SystemVerilog
- Icarus Verilog
- GTKWave
- Yosys
- ABC
- nextpnr-ecp5
- Git
19. Key Engineering Results
The project demonstrates the complete hardware-development flow:
RTL Design
    ↓
Directed Verification
    ↓
Randomized Regression
    ↓
Assertions
    ↓
Functional Coverage
    ↓
Performance Analysis
    ↓
RTL Synthesis
    ↓
Technology Mapping
    ↓
FPGA Placement
    ↓
FPGA Routing
    ↓
Post-Route Timing

The final implementation demonstrates that the cache is not only
functionally verified at RTL level but can also be synthesized and
implemented as an FPGA-oriented hardware block.
20. Lessons Learned
This project provided practical experience with several hardware-design
issues:
- Separating cache control from storage structures
- Handling miss/refill state transitions
- Preserving dirty data during conflict eviction
- Implementing byte-enable writes
- Building randomized verification environments
- Using assertions to detect behavioral violations
- Measuring functional coverage
- Investigating synthesis-tool limitations
- Mapping generic RTL cells to FPGA technology primitives
- Debugging synthesis/technology-mapping failures
- Running FPGA placement and routing
- Interpreting post-route timing reports
- Using implementation results to identify future optimization targets
21. Future Work
Potential future improvements include:
- Parameterizing cache size and associativity
- Adding configurable line size
- Adding more comprehensive formal verification
- Optimizing the critical path
- Comparing alternative cache organizations
- Integrating the cache with an RV32I CPU
- Studying CPU/cache interaction under realistic workloads
- Evaluating performance/resource trade-offs across multiple FPGA targets
22. Project Status
STATUS: COMPLETE
The project has successfully progressed from SystemVerilog RTL through
verification, synthesis, ECP5 technology mapping, placement, routing, and
post-place-and-route timing analysis.
Final headline result
49.42 MHz post-place-and-route Fmax on an ECP5-85F implementation, with
5,795 TRELLIS combinational resources, 1,740 flip-flops, and 128 RAM
resources, backed by directed, randomized, assertion-based, coverage, and
performance verification.