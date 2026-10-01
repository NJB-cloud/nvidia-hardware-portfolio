# UART + FIFO RTL Communication Subsystem

A SystemVerilog RTL design and verification project implementing a complete
buffered serial communication subsystem.

The project combines:

- UART Transmitter
- UART Receiver
- Parameterized Synchronous FIFO
- Automated SystemVerilog verification environment
- Waveform-based debugging using GTKWave

The main focus of this project is clean RTL design, modular architecture,
functional verification, corner-case testing, and subsystem-level integration.

---

# Project Overview

This project demonstrates the design and verification of a digital
communication subsystem capable of:

- Parallel data buffering using FIFO memory
- Parallel-to-serial data conversion using UART TX
- Serial-to-parallel data recovery using UART RX
- End-to-end UART communication verification using loopback testing

The design follows an 8-N-1 UART communication protocol:

- 1 Start bit
- 8 Data bits
- No parity bit
- 1 Stop bit


---

# System Architecture


```
                     Parallel Data

                          |
                          v

                 +----------------+
                 |   UART TX      |
                 |                |
                 | Parallel to    |
                 | Serial Convert |
                 +----------------+

                          |
                          |
                    Serial Line

                          |
                          v

                 +----------------+
                 |   UART RX      |
                 |                |
                 | Serial to       |
                 | Parallel Data   |
                 +----------------+

                          |
                          v

                    Received Data



                 +----------------+
                 |      FIFO      |
                 |                |
 Write Data ---> |  Data Storage  | ---> Read Data
                 |                |
                 | Full / Empty   |
                 | Detection      |
                 +----------------+

```

---

# Design Components

## 1. UART Transmitter (UART TX)

The UART transmitter converts parallel input data into an 8-N-1 serial frame.

Features:

- 8-bit data transmission
- Start bit generation
- Stop bit generation
- Baud-rate timing control
- TX ready handshake
- Busy status indication


## 2. UART Receiver (UART RX)

The UART receiver reconstructs parallel data from incoming UART serial data.

Features:

- Start bit detection
- Data bit sampling
- LSB-first reception
- Stop bit checking
- RX valid pulse generation
- Busy status indication


## 3. Parameterized FIFO Buffer

A synchronous FIFO is implemented for temporary data storage.

Features:

- Configurable data width
- Configurable FIFO depth
- Independent read and write control
- Read/write pointer management
- Occupancy counter
- Empty detection
- Full detection
- Overflow detection
- Underflow detection
- Write acceptance indication
- Read acceptance indication


---

# RTL Implementation

Main RTL files:

```
rtl/

├── uart_tx.sv
├── uart_rx.sv
└── fifo.sv
```

The RTL design uses:

- SystemVerilog always_ff sequential logic
- Modular hardware blocks
- Parameterized design approach
- FSM-based UART control
- Hardware status monitoring


---

# Verification Environment

Verification files:

```
tb/

├── uart_tx_tb.sv
├── uart_rx_tb.sv
├── fifo_tb.sv
└── uart_loopback_tb.sv
```

The verification environment includes:

- Individual module testing
- Automated functional checking
- Boundary-condition testing
- Subsystem integration testing
- Waveform analysis


---

# Verification Strategy

## FIFO Verification

The FIFO testbench verifies:

- Reset behavior
- Write operation
- Read operation
- Data ordering
- Multiple consecutive writes
- Multiple consecutive reads
- Empty condition
- Full condition
- Overflow attempt
- Underflow attempt
- Pointer movement
- Occupancy count behavior


## UART TX Verification

The UART transmitter verification checks:

- Correct UART frame generation
- Start bit timing
- Data transmission
- Stop bit generation
- Ready/busy behavior


## UART RX Verification

The UART receiver verification checks:

- Start bit detection
- Data recovery
- Valid pulse generation
- Multiple received data patterns


## UART Loopback Verification

UART TX and UART RX are connected together:

```
UART TX  --->  Serial Line  --->  UART RX
```

Tested data patterns:

```
0xA5
0x3C
0x00
0xFF
```

Result:

```
ALL UART LOOPBACK TESTS PASSED
```

---

# Simulation Flow

Design flow:

```
RTL Design

      |

SystemVerilog Testbench

      |

Icarus Verilog Simulation

      |

GTKWave Waveform Analysis

```

---

# Tools Used

- SystemVerilog
- Icarus Verilog
- GTKWave
- Visual Studio Code


---

# Running Simulation

From the project directory:

## UART Loopback Test

Compile:

```bash
iverilog -g2012 -o uart_loopback_test rtl/uart_tx.sv rtl/uart_rx.sv tb/uart_loopback_tb.sv
```

Run:

```bash
vvp uart_loopback_test
```


## FIFO Test

Compile:

```bash
iverilog -g2012 -o fifo_test rtl/fifo.sv tb/fifo_tb.sv
```

Run:

```bash
vvp fifo_test
```


Successful verification produces:

```
ALL TESTS PASSED
```

---

# Waveform Evidence

Waveforms were generated and analyzed using GTKWave.

## UART TX-RX Loopback Waveform

The waveform demonstrates:

- Transmitted data
- UART serial frame
- Received data
- RX validation pulse
- TX/RX synchronization


![UART Loopback Waveform](ss/uart_loopback_waveform.png)


## FIFO Verification Waveform

The waveform demonstrates:

- Write transactions
- Read transactions
- FIFO count changes
- Empty/full transitions
- Data movement


![FIFO Waveform](ss/fifo_waveform.png)


---

# Project Structure

```
02_UART_FIFO_Subsystem/

├── docs/
│
├── rtl/
│   ├── uart_tx.sv
│   ├── uart_rx.sv
│   └── fifo.sv
│
├── tb/
│   ├── uart_tx_tb.sv
│   ├── uart_rx_tb.sv
│   ├── fifo_tb.sv
│   └── uart_loopback_tb.sv
│
├── ss/
│   ├── uart_loopback_waveform.png
│   └── fifo_waveform.png
│
└── README.md
```

---

# Future Improvements

Possible future extensions:

- SystemVerilog Assertions (SVA)
- Constrained random verification
- Functional coverage
- FIFO-to-UART streaming datapath
- FPGA implementation
- RTL synthesis and timing analysis


---

# Engineering Skills Demonstrated

This project demonstrates:

- SystemVerilog RTL coding
- Digital hardware design
- UART protocol implementation
- FIFO architecture
- Finite state machine design
- Modular RTL development
- Testbench creation
- Functional verification
- Boundary-condition testing
- Waveform debugging
- Hardware documentation


---

# Author

EEE Undergraduate Student  
RTL / Digital Hardware Portfolio

This project is developed as part of an undergraduate hardware-design
portfolio focused on RTL design, verification, computer architecture,
and digital systems.