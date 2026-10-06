// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: Main Control Unit
//
// Supported instructions:
//   R-type: ADD, SUB, AND, OR, XOR, SLT
//   ADDI
//   LW
//   SW
//   BEQ
// ============================================================

module control_unit (
    input  logic [6:0] opcode,

    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       MemToReg,
    output logic       Branch,
    output logic [1:0] ALUOp
);

    // --------------------------------------------------------
    // RV32I opcodes
    // --------------------------------------------------------

    localparam logic [6:0] OPCODE_R_TYPE  = 7'b0110011;
    localparam logic [6:0] OPCODE_I_TYPE  = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD    = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE   = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH  = 7'b1100011;

    // --------------------------------------------------------
    // ALU operation categories
    //
    // 00 = ADD
    // 01 = SUB
    // 10 = R-type / funct decoding
    // --------------------------------------------------------

    localparam logic [1:0] ALUOP_ADD     = 2'b00;
    localparam logic [1:0] ALUOP_BRANCH  = 2'b01;
    localparam logic [1:0] ALUOP_R_TYPE  = 2'b10;

    // --------------------------------------------------------
    // Main decoder
    // --------------------------------------------------------

    always_comb begin

        // ----------------------------------------------------
        // Safe defaults
        // ----------------------------------------------------

        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemToReg = 1'b0;
        Branch   = 1'b0;
        ALUOp    = ALUOP_ADD;

        case (opcode)

            // =================================================
            // R-TYPE
            //
            // ADD
            // SUB
            // AND
            // OR
            // XOR
            // SLT
            // =================================================

            OPCODE_R_TYPE: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                Branch   = 1'b0;
                ALUOp    = ALUOP_R_TYPE;

            end

            // =================================================
            // ADDI
            //
            // rd = rs1 + immediate
            //
            // Example:
            //   ADDI x1, x0, 16
            //   ADDI x2, x0, 123
            // =================================================

            OPCODE_I_TYPE: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                Branch   = 1'b0;
                ALUOp    = ALUOP_ADD;

            end

            // =================================================
            // LW
            //
            // rd = Memory[rs1 + immediate]
            // =================================================

            OPCODE_LOAD: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemWrite = 1'b0;
                MemToReg = 1'b1;
                Branch   = 1'b0;
                ALUOp    = ALUOP_ADD;

            end

            // =================================================
            // SW
            //
            // Memory[rs1 + immediate] = rs2
            // =================================================

            OPCODE_STORE: begin

                RegWrite = 1'b0;
                ALUSrc   = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b1;
                MemToReg = 1'b0;
                Branch   = 1'b0;
                ALUOp    = ALUOP_ADD;

            end

            // =================================================
            // BEQ
            //
            // Branch if rs1 == rs2
            // =================================================

            OPCODE_BRANCH: begin

                RegWrite = 1'b0;
                ALUSrc   = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                Branch   = 1'b1;
                ALUOp    = ALUOP_BRANCH;

            end

            // =================================================
            // Unsupported instruction
            // =================================================

            default: begin

                RegWrite = 1'b0;
                ALUSrc   = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                Branch   = 1'b0;
                ALUOp    = ALUOP_ADD;

            end

        endcase

    end

endmodule