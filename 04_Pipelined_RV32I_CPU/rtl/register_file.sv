// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: RV32I Register File
// ============================================================

module register_file (
    input  logic        clk,
    input  logic        rst_n,

    // Read ports
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    // Write port
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    input  logic        reg_write
);

    logic [31:0] registers [0:31];

    integer i;

    // --------------------------------------------------------
    // Asynchronous read
    // x0 always reads as zero
    // --------------------------------------------------------

    always_comb begin

        if (rs1 == 5'd0)
            read_data1 = 32'h0000_0000;
        else
            read_data1 = registers[rs1];

        if (rs2 == 5'd0)
            read_data2 = 32'h0000_0000;
        else
            read_data2 = registers[rs2];

    end

    // --------------------------------------------------------
    // Synchronous write
    // x0 cannot be modified
    // --------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'h0000_0000;

        end

        else if (reg_write && (rd != 5'd0)) begin

            registers[rd] <= write_data;

        end

    end

endmodule