// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: Program Counter
// ============================================================

module pc #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] next_pc,

    output logic [31:0] current_pc
);

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            current_pc <= RESET_PC;
        end
        else begin
            current_pc <= next_pc;
        end

    end

endmodule