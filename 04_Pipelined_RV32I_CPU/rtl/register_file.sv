// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: RV32I Register File
//
// Purpose:
//   32 x 32-bit integer register file with:
//     - two asynchronous read ports
//     - one synchronous write port
//     - x0 hardwired to zero
//     - WB-to-ID write-through bypass
//
// Write-through behavior:
//   If the WB stage writes a register during the current
//   clock cycle and the ID stage reads the same register,
//   the read port immediately sees write_data.
//
// This removes the WB->ID register-file timing dependency
// and makes the register file robust for a pipelined CPU.
// ============================================================

module register_file (

    input logic        clk,
    input logic        rst_n,

    // --------------------------------------------------------
    // Read ports
    // --------------------------------------------------------

    input logic [4:0]  rs1,
    input logic [4:0]  rs2,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    // --------------------------------------------------------
    // Write port
    // --------------------------------------------------------

    input logic [4:0]  rd,
    input logic [31:0] write_data,
    input logic        reg_write
);

    logic [31:0] registers [0:31];

    integer i;

    // ========================================================
    // ASYNCHRONOUS READ + WB WRITE-THROUGH
    // ========================================================
    //
    // Priority:
    //
    //   1. x0 -> always zero
    //   2. current WB write to same register -> write_data
    //   3. otherwise -> stored register value
    //
    // This gives deterministic WB-to-ID behavior.
    // ========================================================

    always_comb begin

        // ----------------------------------------------------
        // Read port 1
        // ----------------------------------------------------

        if (rs1 == 5'd0) begin

            read_data1 = 32'h0000_0000;

        end

        else if (
            reg_write &&
            (rd != 5'd0) &&
            (rd == rs1)
        ) begin

            read_data1 = write_data;

        end

        else begin

            read_data1 = registers[rs1];

        end

        // ----------------------------------------------------
        // Read port 2
        // ----------------------------------------------------

        if (rs2 == 5'd0) begin

            read_data2 = 32'h0000_0000;

        end

        else if (
            reg_write &&
            (rd != 5'd0) &&
            (rd == rs2)
        ) begin

            read_data2 = write_data;

        end

        else begin

            read_data2 = registers[rs2];

        end

    end

    // ========================================================
    // SYNCHRONOUS WRITE
    // ========================================================
    //
    // x0 is architecturally immutable.
    // ========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < 32; i = i + 1) begin

                registers[i] <= 32'h0000_0000;

            end

        end

        else begin

            if (
                reg_write &&
                (rd != 5'd0)
            ) begin

                registers[rd] <= write_data;

            end

            // Explicit x0 protection.
            registers[0] <= 32'h0000_0000;

        end

    end

endmodule