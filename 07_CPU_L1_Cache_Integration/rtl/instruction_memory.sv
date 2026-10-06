// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: Instruction Memory
//
// Purpose:
//   Combinational instruction fetch for the Project 7
//   CPU + L1 cache integration test.
//
// Test program:
//
//   1. ADDI x1, x0, 16
//      x1 = 16
//
//   2. ADDI x2, x0, 123
//      x2 = 123
//
//   3. SW x2, 0(x1)
//      Memory[16] = 123
//
//   4. LW x3, 0(x1)
//      x3 = Memory[16]
//
//   5. ADD x4, x3, x2
//      x4 = 246
//
// This program intentionally contains a store followed by a load
// so that the CPU -> L1 cache -> memory path can be exercised.
// ============================================================

module instruction_memory #(
    parameter int DEPTH = 256
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:DEPTH-1];

    integer i;

    // ========================================================
    // PROGRAM INITIALIZATION
    // ========================================================

    initial begin

        // Initialize the complete instruction memory to NOPs.

        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'h0000_0013;


        // ----------------------------------------------------
        // Test program
        // ----------------------------------------------------

        // 0x00000000:
        // ADDI x1, x0, 16
        // x1 = 16
        memory[0] = 32'h0100_0093;


        // 0x00000004:
        // ADDI x2, x0, 123
        // x2 = 123
        memory[1] = 32'h07B0_0113;


        // 0x00000008:
        // SW x2, 0(x1)
        //
        // Memory address = x1 + 0 = 16
        // Store x2 = 123
        memory[2] = 32'h0020_A023;


        // 0x0000000C:
        // LW x3, 0(x1)
        //
        // Memory address = x1 + 0 = 16
        // x3 should become 123
        memory[3] = 32'h0000_A183;


        // 0x00000010:
        // ADD x4, x3, x2
        //
        // Expected:
        // x4 = 123 + 123 = 246
        memory[4] = 32'h0021_8233;


        // ----------------------------------------------------
        // Remaining locations stay NOP.
        // ----------------------------------------------------

    end


    // ========================================================
    // COMBINATIONAL INSTRUCTION FETCH
    // ========================================================

    always_comb begin

        if (address[31:2] < DEPTH)

            instruction = memory[address[31:2]];

        else

            instruction = 32'h0000_0013;

    end

endmodule