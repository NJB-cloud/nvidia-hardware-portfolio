// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: ALU
// Description: 32-bit RV32I Arithmetic Logic Unit
// ============================================================

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_control,
    output logic [31:0] result,
    output logic        zero
);

    // --------------------------------------------------------
    // ALU operation encoding
    // --------------------------------------------------------

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;

    // --------------------------------------------------------
    // Combinational ALU
    // --------------------------------------------------------

    always_comb begin

        case (alu_control)

            ALU_ADD: begin
                result = a + b;
            end

            ALU_SUB: begin
                result = a - b;
            end

            ALU_AND: begin
                result = a & b;
            end

            ALU_OR: begin
                result = a | b;
            end

            ALU_XOR: begin
                result = a ^ b;
            end

            ALU_SLT: begin
                result = ($signed(a) < $signed(b)) ? 32'h0000_0001
                                                   : 32'h0000_0000;
            end

            default: begin
                result = 32'h0000_0000;
            end

        endcase

    end

    // --------------------------------------------------------
    // Zero flag
    // --------------------------------------------------------

    always_comb begin

        if (result == 32'h0000_0000)
            zero = 1'b1;
        else
            zero = 1'b0;

    end

endmodule