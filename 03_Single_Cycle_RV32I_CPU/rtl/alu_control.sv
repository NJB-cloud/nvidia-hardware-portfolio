// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: ALU Control
// Description: Decodes ALUOp, funct3 and funct7
// ============================================================

module alu_control (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_bit5,

    output logic [3:0] alu_control
);

    // --------------------------------------------------------
    // ALU operation encoding
    // Must match rtl/alu.sv
    // --------------------------------------------------------

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;

    // --------------------------------------------------------
    // ALUOp encoding from Main Control Unit
    //
    // 00 = ADD
    // 01 = SUB
    // 10 = R-Type funct decoding
    // --------------------------------------------------------

    localparam logic [1:0] ALUOP_ADD    = 2'b00;
    localparam logic [1:0] ALUOP_SUB    = 2'b01;
    localparam logic [1:0] ALUOP_R_TYPE = 2'b10;

    // --------------------------------------------------------
    // RISC-V funct3 values
    // --------------------------------------------------------

    localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;
    localparam logic [2:0] FUNCT3_XOR     = 3'b100;
    localparam logic [2:0] FUNCT3_OR      = 3'b110;
    localparam logic [2:0] FUNCT3_AND     = 3'b111;
    localparam logic [2:0] FUNCT3_SLT     = 3'b010;

    // --------------------------------------------------------
    // Combinational decoder
    // --------------------------------------------------------

    always_comb begin

        // Safe default
        alu_control = ALU_ADD;

        case (alu_op)

            // ------------------------------------------------
            // LW / SW
            // Address calculation = ADD
            // ------------------------------------------------

            ALUOP_ADD: begin

                alu_control = ALU_ADD;

            end

            // ------------------------------------------------
            // BEQ
            // Comparison = SUB
            // Zero flag determines equality
            // ------------------------------------------------

            ALUOP_SUB: begin

                alu_control = ALU_SUB;

            end

            // ------------------------------------------------
            // R-Type instructions
            // ------------------------------------------------

            ALUOP_R_TYPE: begin

                case (funct3)

                    FUNCT3_ADD_SUB: begin

                        if (funct7_bit5)
                            alu_control = ALU_SUB;
                        else
                            alu_control = ALU_ADD;

                    end

                    FUNCT3_XOR: begin

                        alu_control = ALU_XOR;

                    end

                    FUNCT3_OR: begin

                        alu_control = ALU_OR;

                    end

                    FUNCT3_AND: begin

                        alu_control = ALU_AND;

                    end

                    FUNCT3_SLT: begin

                        alu_control = ALU_SLT;

                    end

                    default: begin

                        alu_control = ALU_ADD;

                    end

                endcase

            end

            default: begin

                alu_control = ALU_ADD;

            end

        endcase

    end

endmodule
