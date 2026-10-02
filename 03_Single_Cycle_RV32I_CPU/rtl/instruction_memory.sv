// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: Instruction Memory
// Purpose: Combinational instruction fetch
// ============================================================

module instruction_memory #(
    parameter int DEPTH = 256
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:DEPTH-1];

    // Word-aligned instruction fetch.
    // address[31:2] selects a 32-bit instruction word.
    always_comb begin

        if (address[31:2] < DEPTH)
            instruction = memory[address[31:2]];
        else
            instruction = 32'h0000_0013; // NOP = ADDI x0,x0,0

    end

endmodule