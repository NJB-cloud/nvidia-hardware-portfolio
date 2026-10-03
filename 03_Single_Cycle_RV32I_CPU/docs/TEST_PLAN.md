# RV32I Single-Cycle CPU — Regression Test Plan

## Objective

The purpose of this regression suite is to verify the single-cycle RV32I
CPU using multiple independent small programs.

The regression suite complements the module-level and integrated directed
tests by exercising the processor through complete instruction sequences.

## Regression Target

- Total programs: 20
- Target passing programs: 20
- Target failures: 0

## Program Coverage

| Program | Primary Feature | Expected Result |
|---|---|---|
| 01 | ADD | Correct arithmetic result |
| 02 | SUB | Correct subtraction result |
| 03 | AND | Correct logical result |
| 04 | OR | Correct logical result |
| 05 | XOR | Correct logical result |
| 06 | SLT | Correct signed comparison |
| 07 | ADD/SUB chain | Correct dependent computation |
| 08 | LW | Correct memory read |
| 09 | SW | Correct memory write |
| 10 | LW/SW roundtrip | Stored value recovered correctly |
| 11 | BEQ taken | Target instruction executed |
| 12 | BEQ not taken | Sequential instruction executed |
| 13 | Negative arithmetic | Correct two's-complement result |
| 14 | Positive immediate | Correct immediate value |
| 15 | Negative immediate | Correct sign extension |
| 16 | Register dependency | Correct back-to-back data flow |
| 17 | Multiple memory operations | Correct repeated accesses |
| 18 | Branch + memory | Correct control/data interaction |
| 19 | Mixed RV32I | Multiple instruction classes |
| 20 | Complete program | End-to-end functional result |

## Pass Criteria

A program passes when all expected architectural results match the
reference values defined by its test.

A program fails when any required register, memory location, or control-flow
result differs from the expected value.

## Verification Method

Each program is executed by the RTL CPU in simulation.

The regression environment records:

- Program number
- Test name
- Expected result
- Actual result
- PASS/FAIL status

## Final Acceptance Criteria

The Project 3B regression suite is considered complete when:

```text
20 programs executed
20 programs passed
0 programs failed