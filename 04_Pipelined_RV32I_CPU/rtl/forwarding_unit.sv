// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: Forwarding Unit
//
// Purpose:
//   Resolves EX-stage data hazards by forwarding the newest
//   available result from later pipeline stages.
//
// Forwarding encoding:
//
//   2'b00 -> Use ID/EX register value
//   2'b01 -> Forward from MEM/WB
//   2'b10 -> Forward from EX/MEM
//
// Priority:
//
//   EX/MEM has priority over MEM/WB because it contains the
//   more recently produced result.
//
// x0 is never forwarded.
// ============================================================

module forwarding_unit (

    // --------------------------------------------------------
    // Source registers of instruction currently in EX
    // --------------------------------------------------------

    input logic [4:0] id_ex_rs1,
    input logic [4:0] id_ex_rs2,

    // --------------------------------------------------------
    // Destination register of instruction in EX/MEM
    // --------------------------------------------------------

    input logic [4:0] ex_mem_rd,
    input logic       ex_mem_RegWrite,

    // --------------------------------------------------------
    // Destination register of instruction in MEM/WB
    // --------------------------------------------------------

    input logic [4:0] mem_wb_rd,
    input logic       mem_wb_RegWrite,

    // --------------------------------------------------------
    // Forwarding controls
    // --------------------------------------------------------

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin

        // ----------------------------------------------------
        // Default:
        // use the values already present in ID/EX.
        // ----------------------------------------------------

        forward_a = 2'b00;
        forward_b = 2'b00;

        // ----------------------------------------------------
        // EX/MEM forwarding for operand A
        // ----------------------------------------------------

        if (
            ex_mem_RegWrite &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1)
        ) begin

            forward_a = 2'b10;

        end

        // ----------------------------------------------------
        // MEM/WB forwarding for operand A
        //
        // Only apply if EX/MEM did not already provide the
        // newer value.
        // ----------------------------------------------------

        else if (
            mem_wb_RegWrite &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs1)
        ) begin

            forward_a = 2'b01;

        end

        // ----------------------------------------------------
        // EX/MEM forwarding for operand B
        // ----------------------------------------------------

        if (
            ex_mem_RegWrite &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2)
        ) begin

            forward_b = 2'b10;

        end

        // ----------------------------------------------------
        // MEM/WB forwarding for operand B
        // ----------------------------------------------------

        else if (
            mem_wb_RegWrite &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs2)
        ) begin

            forward_b = 2'b01;

        end

    end

endmodule