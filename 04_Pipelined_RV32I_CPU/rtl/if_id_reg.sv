// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: IF/ID Pipeline Register
//
// Purpose:
//   Stores instruction-fetch information between the IF and
//   ID pipeline stages.
//
// Supported control:
//   - Normal pipeline advance
//   - Stall / hold
//   - Flush / bubble
//   - Reset
// ============================================================

module if_id_reg (
    input  logic        clk,
    input  logic        rst_n,

    // Pipeline control
    input  logic        stall,
    input  logic        flush,

    // IF-stage inputs
    input  logic [31:0] if_pc,
    input  logic [31:0] if_pc_plus4,
    input  logic [31:0] if_instruction,

    // ID-stage outputs
    output logic [31:0] id_pc,
    output logic [31:0] id_pc_plus4,
    output logic [31:0] id_instruction,
    output logic        id_valid
);

    // --------------------------------------------------------
    // Sequential pipeline register
    // --------------------------------------------------------

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            id_pc          <= 32'h0000_0000;
            id_pc_plus4    <= 32'h0000_0000;
            id_instruction <= 32'h0000_0013;
            id_valid       <= 1'b0;

        end
        else if (flush) begin

            // Insert a bubble.
            //
            // ADDI x0,x0,0 (0x00000013) is used as the
            // canonical RISC-V NOP encoding.

            id_pc          <= 32'h0000_0000;
            id_pc_plus4    <= 32'h0000_0000;
            id_instruction <= 32'h0000_0013;
            id_valid       <= 1'b0;

        end
        else if (stall) begin

            // Hold the current instruction and PC.
            // This is required during a load-use hazard.

            id_pc          <= id_pc;
            id_pc_plus4    <= id_pc_plus4;
            id_instruction <= id_instruction;
            id_valid       <= id_valid;

        end
        else begin

    // Normal pipeline advance.

    id_pc          <= if_pc;
    id_pc_plus4    <= if_pc_plus4;
    id_instruction <= if_instruction;
    id_valid       <= 1'b1;

end

    end

endmodule