# UART + FIFO RTL Subsystem Architecture

## Overview

This project implements a verified digital communication subsystem using SystemVerilog.

The design contains:

- UART Transmitter
- UART Receiver
- Parameterized FIFO Buffer
- Automated verification environment


## System Architecture


                +-------------+
                | UART TX     |
                | 8-N-1 Frame |
                +-------------+
                       |
                       |
                 Serial Line
                       |
                       v
                +-------------+
                | UART RX     |
                | Data Decode |
                +-------------+
                       |
                       v
                  Received Data



                +-------------+
 Write Data --->|             |
                | FIFO Buffer |
 Read Data <----|             |
                +-------------+


## Design Components

### UART Transmitter

Responsible for converting parallel data into serial UART frames.

Features:

- 8-bit data transmission
- Start bit generation
- Stop bit generation
- Baud-rate timing control
- Ready/Busy handshake


### UART Receiver

Responsible for converting serial UART data back into parallel data.

Features:

- Start bit detection
- Data sampling
- Stop bit verification
- RX valid pulse generation


### FIFO Buffer

A synchronous parameterized FIFO used for temporary data storage.

Features:

- Configurable data width
- Configurable depth
- Full detection
- Empty detection
- Overflow detection
- Underflow detection


## Verification Flow

RTL Design

↓

SystemVerilog Testbench

↓

Icarus Verilog Simulation

↓

GTKWave Waveform Analysis


## Verification Results

All modules were verified using automated testbenches.

Results:

- FIFO verification: PASS
- UART TX verification: PASS
- UART RX verification: PASS
- UART TX-RX Loopback verification: PASS