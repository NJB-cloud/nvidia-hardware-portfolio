# Project 6 — L1 Data Cache / Memory Subsystem
## Cache Specification

### Target
NVIDIA Summer 2027 Undergraduate Hardware Internship Portfolio

### Target Project Quality
9.5/10 NVIDIA Internship Standard

---

# 1. Project Objective

Design, verify, synthesize, and analyze a parameterized L1 data cache for a 32-bit processor memory interface.

The project will demonstrate:

- Computer architecture
- RTL/SystemVerilog design
- Cache organization
- Memory hierarchy
- Cache hit/miss handling
- Write-back behavior
- Write allocation
- Verification methodology
- Assertion-based verification
- Functional coverage
- Waveform debugging
- Synthesis
- Timing analysis
- Performance analysis

---

# 2. Cache Architecture

The cache is a:

- 1 KiB L1 data cache
- Direct-mapped
- 32-bit data path
- 32-bit address space
- 16-byte cache line
- 64 cache lines
- 4 × 32-bit words per cache line
- 1-way associative

---

# 3. Cache Parameters

| Parameter | Value |
|---|---:|
| Address width | 32 bits |
| Data width | 32 bits |
| Cache capacity | 1024 bytes |
| Cache line size | 16 bytes |
| Number of lines | 64 |
| Words per line | 4 |
| Associativity | 1-way |
| Mapping | Direct-mapped |
| Write policy | Write-back |
| Allocation policy | Write-allocate |

---

# 4. Address Mapping

The 32-bit address is divided into:

```text
31                         10 9          4 3        0
┌────────────────────────────┬────────────┬──────────┐
│            TAG             │   INDEX    │  OFFSET  │
│          22 bits           │   6 bits   │  4 bits  │
└────────────────────────────┴────────────┴──────────┘
Therefore:
TAG    = address[31:10]
INDEX  = address[9:4]
OFFSET = address[3:0]

The offset identifies a byte within a 16-byte cache line.
The index selects one of the 64 cache lines.
The tag identifies which memory block currently occupies that cache line.
5. Cache Line Organization
Each cache line contains:
4 × 32-bit words = 128 bits

Conceptually:
Cache Line
┌──────────┬──────────┬──────────┬──────────┐
│ Word 0   │ Word 1   │ Word 2   │ Word 3   │
│ 32 bits  │ 32 bits  │ 32 bits  │ 32 bits  │
└──────────┴──────────┴──────────┴──────────┘

                 128 bits

Each cache line also contains:
- Tag
- Valid bit
- Dirty bit
6. Internal Storage
The RTL implementation shall conceptually contain:
data_array[0:63]
tag_array[0:63]
valid_array[0:63]
dirty_array[0:63]

Each data array entry represents one 16-byte cache line.
7. Read Operation
For a CPU read request:
1. Extract tag, index, and offset from the address.
2. Use the index to select a cache line.
3. Check the valid bit.
4. Compare the requested tag with the stored tag.
5. If valid and tag matches, declare a cache hit.
6. Return the requested word from the cache line.
7. If the tag does not match or the line is invalid, declare a cache miss.
8. Handle any required write-back.
9. Refill the cache line from lower memory.
10. Update tag, valid, and dirty information.
11. Return the requested word to the CPU.
8. Cache Hit
A cache hit occurs when:
valid[index] == 1

and
tag_array[index] == requested_tag

On a read hit:
CPU request
     |
     v
Tag comparison
     |
     v
   HIT
     |
     v
Cache data
     |
     v
CPU response

The lower memory is not accessed during a normal read hit.
9. Cache Miss
A cache miss occurs when:
valid[index] == 0

or:
tag_array[index] != requested_tag

The controller must determine whether the existing line is dirty.
For a clean or invalid line:
MISS
  |
  v
REFILL
  |
  v
UPDATE CACHE
  |
  v
RETURN DATA

For a dirty line:
MISS
  |
  v
DIRTY?
  |
 YES
  |
  v
WRITE BACK
  |
  v
REFILL
  |
  v
UPDATE CACHE
  |
  v
RETURN DATA

10. Write Policy
The cache uses:
Write-back
A CPU store updates the cache rather than immediately updating lower memory.
If a cache line is modified:
dirty = 1

The modified line is written to lower memory only when it is evicted.
11. Write-Allocate Policy
For a store miss:
1. Identify the missing cache line.
2. Write back the old line if it is dirty.
3. Fetch the requested line from lower memory.
4. Install the line in the cache.
5. Perform the requested store.
6. Set the dirty bit.
Therefore:
Store Miss
    |
    v
Write back old line if dirty
    |
    v
Fetch new line
    |
    v
Install line
    |
    v
Perform store
    |
    v
dirty = 1

12. Memory Interface
The cache shall communicate with a lower-level memory model.
The interface must support:
CPU → Cache
- Read/write request
- Address
- Write data
- Byte/word control as required
Cache → CPU
- Response/ready indication
- Read data
Cache → Memory
- Memory request
- Address
- Write data
- Read/write indication
Memory → Cache
- Memory response
- Read data
The exact signal names will be frozen during RTL interface design before implementation.
13. Controller FSM
The cache controller shall use an explicit finite-state machine.
The initial architecture shall include states conceptually equivalent to:
IDLE
  |
  v
TAG_CHECK
  |
  +------ HIT ------> RESPOND
  |
  MISS
  |
  v
CHECK_DIRTY
  |
  +------ CLEAN ----> REFILL
  |
  DIRTY
  |
  v
WRITEBACK
  |
  v
REFILL
  |
  v
UPDATE
  |
  v
RESPOND
  |
  v
IDLE

The final state encoding will be determined during RTL implementation.
14. Reset Behavior
On reset:
valid_array = 0
dirty_array = 0

Cache data and tag contents do not need meaningful initialization if the valid bits are cleared.
After reset, all cache lines must behave as invalid.
15. Verification Requirements
The verification environment shall test:
Basic functionality
- Reset
- First access
- Read hit
- Read miss
- Write hit
- Write miss
- Repeated access
Address behavior
- Same address
- Same cache line
- Different cache line
- Same index / different tag
- Lowest address
- Highest address
- Line boundaries
Cache behavior
- Cold misses
- Capacity-related behavior
- Conflict misses
- Clean eviction
- Dirty eviction
- Cache refill
- Write-back
- Write allocation
Stress testing
- Random addresses
- Random reads
- Random writes
- Mixed read/write sequences
- Back-to-back requests
- Repeated conflicting addresses
16. Reference Model
A software reference model shall represent expected memory/cache behavior.
The scoreboard shall compare:
DUT result
    vs.
Reference-model result

The verification environment shall report mismatches automatically.
17. Assertions
Assertions shall check important architectural properties, including:
- Reset clears valid state
- Invalid lines cannot produce cache hits
- Hit requires valid tag match
- Dirty state is handled correctly
- Controller does not enter illegal states
- Requests eventually receive responses
- Cache responses correspond to valid requests
- No illegal memory transaction occurs
18. Functional Coverage
Coverage shall include at minimum:
Access type
- Read
- Write
Result
- Hit
- Miss
Line state
- Invalid
- Valid clean
- Valid dirty
Miss behavior
- Clean miss
- Dirty miss
Address behavior
- Same line
- Different line
- Same index / different tag
Reset
- Reset followed by first access
Target:
Functional coverage > 95%

where practical and supported by the implemented coverage model.
19. Waveform Verification
GTKWave shall be used to inspect important transactions.
Evidence shall include at least:
Hit waveform
Request
   ↓
Tag comparison
   ↓
HIT
   ↓
Data response

Miss waveform
Request
   ↓
MISS
   ↓
Memory access
   ↓
Refill
   ↓
Cache update
   ↓
Data response

Dirty eviction waveform
Request
   ↓
MISS
   ↓
Dirty line detected
   ↓
Write-back
   ↓
Refill
   ↓
Response

20. Synthesis Requirements
The cache shall be synthesized using Yosys.
Reports shall include, where supported:
- Cell count
- Flip-flop count
- Combinational logic
- Memory implementation information
- Area proxy
- Timing information
Generated synthesis artifacts shall be stored under:
synthesis/
├── scripts/
└── reports/

21. Timing Analysis
The project shall identify:
- Critical path
- Major combinational path
- Cache tag comparison path
- Controller timing
- Memory interface timing
Timing results shall be documented rather than merely reported.
22. Performance Analysis
The project shall calculate or estimate:
Hit rate
Miss rate
Average memory access time
Hit latency
Miss penalty

Simulation results shall be used to demonstrate the performance effect of caching.
23. Portfolio Evidence
The final GitHub project should contain:
RTL
Verification environment
Assertions
Functional coverage
Waveforms
Synthesis reports
Timing analysis
Performance analysis
Architecture documentation
README

Generated binaries and temporary simulation outputs should not be committed.
24. Project Acceptance Criteria
Project 6 will not be considered complete until:
- [ ] Cache RTL compiles
- [ ] Reset passes
- [ ] Read hit passes
- [ ] Read miss passes
- [ ] Write hit passes
- [ ] Write miss passes
- [ ] Clean eviction passes
- [ ] Dirty eviction passes
- [ ] Write-back passes
- [ ] Write-allocate passes
- [ ] Random verification passes
- [ ] Reference model passes
- [ ] Scoreboard passes
- [ ] Assertions pass
- [ ] Functional coverage target achieved
- [ ] GTKWave evidence captured
- [ ] Yosys synthesis completed
- [ ] Timing analysis completed
- [ ] Performance analysis completed
- [ ] README completed
- [ ] GitHub repository cleaned and committed
25. Target Project Rating
Target:
9.5 / 10
The rating will be based on demonstrated engineering evidence, not simply the number of features implemented.
The project should demonstrate:
1. Correct architecture
2. Clean RTL
3. Strong verification
4. Hardware debugging
5. Synthesis awareness
6. Timing awareness
7. Performance analysis
8. Professional documentation