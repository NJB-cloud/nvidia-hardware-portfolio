// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: MEM/WB Pipeline Register
//
// Purpose:
//   Stores memory-stage results between MEM and WB.
//
// Carries:
//   - ALU result
//   - Memory read data
//   - Destination register
//   - Write-back control
//   - Valid bit
// ============================================================

module mem_wb_reg (
    input logic clk,
    input logic rst_n,

    // --------------------------------------------------------
    // MEM-stage inputs
    // --------------------------------------------------------

    input logic [31:0] mem_alu_result,
    input logic [31:0] mem_read_data,

    input logic [4:0] mem_rd,

    // Write-back control
    input logic mem_RegWrite,
    input logic mem_MemToReg,

    input logic mem_valid,

    // --------------------------------------------------------
    // WB-stage outputs
    // --------------------------------------------------------

    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_read_data,

    output logic [4:0] wb_rd,

    output logic wb_RegWrite,
    output logic wb_MemToReg,

    output logic wb_valid
);

    // --------------------------------------------------------
    // Sequential pipeline register
    // --------------------------------------------------------

    always_ff @(posedge clk) begin

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        if (!rst_n) begin

            wb_alu_result <= 32'h0000_0000;
            wb_read_data  <= 32'h0000_0000;

            wb_rd <= 5'd0;

            wb_RegWrite <= 1'b0;
            wb_MemToReg <= 1'b0;

            wb_valid <= 1'b0;

        end

        // ----------------------------------------------------
        // NORMAL PIPELINE ADVANCE
        // ----------------------------------------------------

        else begin

            wb_alu_result <= mem_alu_result;
            wb_read_data  <= mem_read_data;

            wb_rd <= mem_rd;

            wb_RegWrite <= mem_RegWrite;
            wb_MemToReg <= mem_MemToReg;

            wb_valid <= mem_valid;

        end

    end

endmodule