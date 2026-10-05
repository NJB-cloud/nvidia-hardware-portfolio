# Project 6 — L1 Cache Interface Specification

## 1. Purpose

This document freezes the interface between the L1 data cache,
the CPU-side requester, and the lower-level memory model.

The interfaces are defined before RTL implementation.

---

# 2. CPU-Side Interface

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk` | Input | 1 | System clock |
| `rst_n` | Input | 1 | Active-low reset |
| `cpu_req_valid` | Input | 1 | CPU presents a valid request |
| `cpu_req_ready` | Output | 1 | Cache can accept request |
| `cpu_req_addr` | Input | 32 | Byte address |
| `cpu_req_write` | Input | 1 | 1 = write, 0 = read |
| `cpu_req_wdata` | Input | 32 | Store data |
| `cpu_req_be` | Input | 4 | Byte enables |
| `cpu_rsp_valid` | Output | 1 | Response is valid |
| `cpu_rsp_rdata` | Output | 32 | Load response data |

---

# 3. CPU Request Handshake

A request is accepted when:

    cpu_req_valid && cpu_req_ready

The cache shall not accept a request unless both signals are high.

The request address and control information must remain stable
until the request is accepted.

---

# 4. CPU Response

For a load request:

    cpu_rsp_valid = 1

indicates that:

    cpu_rsp_rdata

contains the requested 32-bit data.

For a store request, the response indicates that the store
operation has completed successfully.

---

# 5. Byte Enables

`cpu_req_be[3:0]` selects which bytes of the 32-bit word are modified.

A full-word write uses:

    cpu_req_be = 4'b1111

Byte-enable handling will be implemented in the cache data-update
logic.

---

# 6. Memory-Side Interface

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `mem_req_valid` | Output | 1 | Cache presents memory request |
| `mem_req_ready` | Input | 1 | Memory accepts request |
| `mem_req_write` | Output | 1 | 1 = write-back, 0 = line read |
| `mem_req_addr` | Output | 32 | Line-aligned address |
| `mem_req_wdata` | Output | 128 | Cache-line write-back data |
| `mem_rsp_valid` | Input | 1 | Refill data is valid |
| `mem_rsp_rdata` | Input | 128 | 16-byte memory line |

---

# 7. Memory Request Handshake

A memory request is accepted when:

    mem_req_valid && mem_req_ready

For a refill:

    mem_req_write = 0

For a dirty-line write-back:

    mem_req_write = 1

---

# 8. Cache-Line Width

The cache line is:

    16 bytes

Therefore:

    16 × 8 = 128 bits

The memory data interface transfers:

    128 bits

per cache-line transaction.

---

# 9. Memory Address Alignment

All memory-side cache-line addresses are aligned to 16 bytes.

Therefore:

    mem_req_addr[3:0] = 4'b0000

The lower four address bits are zero for line transactions.

---

# 10. Read Hit

Sequence:

    CPU request
        ↓
    Tag comparison
        ↓
    Valid + matching tag
        ↓
    HIT
        ↓
    Return requested word

No lower-memory transaction occurs for a normal read hit.

---

# 11. Read Miss

Sequence:

    CPU request
        ↓
    Tag comparison
        ↓
    MISS
        ↓
    Check victim dirty bit
        ↓
    Refill line
        ↓
    Update cache
        ↓
    Return requested word

---

# 12. Dirty Eviction

If:

    valid = 1
    dirty = 1
    tag mismatch

the existing cache line must be written back before replacement.

Sequence:

    MISS
      ↓
    DIRTY
      ↓
    WRITE BACK
      ↓
    REFILL
      ↓
    UPDATE CACHE
      ↓
    RESPONSE

---

# 13. Write Hit

Sequence:

    CPU store
        ↓
    Tag comparison
        ↓
    HIT
        ↓
    Modify selected bytes
        ↓
    dirty = 1
        ↓
    Store complete

---

# 14. Write Miss

The cache uses write-allocate.

Sequence:

    CPU store miss
        ↓
    Check victim
        ↓
    Write back if dirty
        ↓
    Refill requested line
        ↓
    Modify requested word
        ↓
    dirty = 1
        ↓
    Store complete

---

# 15. Reset

During reset:

    valid_array = 0
    dirty_array = 0

All cache lines therefore behave as invalid after reset.

---

# 16. Interface Verification

The verification environment shall test:

- Request handshake
- Response handshake
- Read hits
- Read misses
- Write hits
- Write misses
- Clean eviction
- Dirty eviction
- Refill
- Write-back
- Write allocation
- Back-to-back requests
- Random addresses
- Byte-enable behavior

---

# 17. Design Constraint

The CPU-side and memory-side interfaces shall remain separate
from the internal cache implementation.

This allows the cache controller, tag array, data array, and
verification environment to be developed and tested independently.

---

# 18. Project Quality Requirement

The interface must be stable before RTL implementation begins.

Any later interface change must be documented because it affects:

- RTL
- testbench
- reference model
- scoreboard
- assertions
- memory model
- synthesis
- documentation