// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: Hazard Detection Unit
//
// Purpose:
//   Detects load-use data hazards that cannot be resolved by
//   normal forwarding.
//
// Load-use condition:
//
//   ID/EX contains a load instruction
//   AND
//   the instruction in IF/ID requires the loaded destination
//
// Response:
//
//   PCWrite     = 0
//   IF_ID_Write = 0
//   ID_EX_Flush = 1
//
// This creates one pipeline bubble.
//
// x0 is excluded because it is architecturally constant zero.
// ============================================================

module hazard_unit (

    // --------------------------------------------------------
    // Instruction currently in ID/EX
    // --------------------------------------------------------

    input logic       id_ex_MemRead,
    input logic [4:0] id_ex_rd,

    // --------------------------------------------------------
    // Instruction currently in IF/ID
    // --------------------------------------------------------

    input logic [4:0] if_id_rs1,
    input logic [4:0] if_id_rs2,

    // Indicates which source operands the IF/ID instruction
    // actually uses.
    // --------------------------------------------------------

    input logic       if_id_uses_rs1,
    input logic       if_id_uses_rs2,

    // --------------------------------------------------------
    // Hazard-control outputs
    // --------------------------------------------------------

    output logic pc_write,
    output logic if_id_write,
    output logic id_ex_flush
);

    always_comb begin

        // ----------------------------------------------------
        // Normal operation
        // ----------------------------------------------------

        pc_write     = 1'b1;
        if_id_write  = 1'b1;
        id_ex_flush  = 1'b0;

        // ----------------------------------------------------
        // Load-use hazard
        // ----------------------------------------------------

        if (
            id_ex_MemRead &&
            (id_ex_rd != 5'd0) &&
            (
                (if_id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                (if_id_uses_rs2 && (id_ex_rd == if_id_rs2))
            )
        ) begin

            // Hold the PC.
            pc_write = 1'b0;

            // Hold the dependent instruction in IF/ID.
            if_id_write = 1'b0;

            // Insert a bubble into ID/EX.
            id_ex_flush = 1'b1;

        end

    end

endmodule