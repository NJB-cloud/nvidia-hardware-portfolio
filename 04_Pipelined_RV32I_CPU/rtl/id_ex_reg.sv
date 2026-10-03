// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: ID/EX Pipeline Register
//
// Purpose:
//   Stores decoded instruction information between the ID and
//   EX pipeline stages.
//
// Supports:
//   - Normal pipeline advance
//   - Stall/bubble insertion
//   - Flush/bubble insertion
//   - Reset
//
// The register carries both datapath values and control signals.
// ============================================================

module id_ex_reg (
    input logic clk,
    input logic rst_n,

    // --------------------------------------------------------
    // Pipeline control
    // --------------------------------------------------------

    input logic stall,
    input logic flush,

    // --------------------------------------------------------
    // ID-stage datapath inputs
    // --------------------------------------------------------

    input logic [31:0] id_pc,
    input logic [31:0] id_pc_plus4,

    input logic [31:0] id_register_data1,
    input logic [31:0] id_register_data2,

    input logic [31:0] id_immediate,

    // --------------------------------------------------------
    // Register identifiers
    // --------------------------------------------------------

    input logic [4:0] id_rs1,
    input logic [4:0] id_rs2,
    input logic [4:0] id_rd,

    // --------------------------------------------------------
    // Instruction information
    // --------------------------------------------------------

    input logic [2:0] id_funct3,
    input logic       id_funct7_bit5,

    // --------------------------------------------------------
    // Control signals
    // --------------------------------------------------------

    input logic       id_RegWrite,
    input logic       id_ALUSrc,
    input logic       id_MemRead,
    input logic       id_MemWrite,
    input logic       id_MemToReg,
    input logic       id_Branch,
    input logic [1:0] id_ALUOp,

    // --------------------------------------------------------
    // EX-stage outputs
    // --------------------------------------------------------

    output logic [31:0] ex_pc,
    output logic [31:0] ex_pc_plus4,

    output logic [31:0] ex_register_data1,
    output logic [31:0] ex_register_data2,

    output logic [31:0] ex_immediate,

    output logic [4:0] ex_rs1,
    output logic [4:0] ex_rs2,
    output logic [4:0] ex_rd,

    output logic [2:0] ex_funct3,
    output logic       ex_funct7_bit5,

    output logic       ex_RegWrite,
    output logic       ex_ALUSrc,
    output logic       ex_MemRead,
    output logic       ex_MemWrite,
    output logic       ex_MemToReg,
    output logic       ex_Branch,
    output logic [1:0] ex_ALUOp,

    output logic       ex_valid
);

    // --------------------------------------------------------
    // Sequential pipeline register
    // --------------------------------------------------------

    always_ff @(posedge clk) begin

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        if (!rst_n) begin

            ex_pc             <= 32'h0000_0000;
            ex_pc_plus4       <= 32'h0000_0000;

            ex_register_data1 <= 32'h0000_0000;
            ex_register_data2 <= 32'h0000_0000;

            ex_immediate      <= 32'h0000_0000;

            ex_rs1            <= 5'd0;
            ex_rs2            <= 5'd0;
            ex_rd             <= 5'd0;

            ex_funct3         <= 3'b000;
            ex_funct7_bit5    <= 1'b0;

            ex_RegWrite       <= 1'b0;
            ex_ALUSrc         <= 1'b0;
            ex_MemRead        <= 1'b0;
            ex_MemWrite       <= 1'b0;
            ex_MemToReg       <= 1'b0;
            ex_Branch         <= 1'b0;
            ex_ALUOp          <= 2'b00;

            ex_valid          <= 1'b0;

        end

        // ----------------------------------------------------
        // FLUSH
        //
        // Convert the ID/EX contents into a harmless bubble.
        // ----------------------------------------------------

        else if (flush) begin

            ex_pc             <= 32'h0000_0000;
            ex_pc_plus4       <= 32'h0000_0000;

            ex_register_data1 <= 32'h0000_0000;
            ex_register_data2 <= 32'h0000_0000;

            ex_immediate      <= 32'h0000_0000;

            ex_rs1            <= 5'd0;
            ex_rs2            <= 5'd0;
            ex_rd             <= 5'd0;

            ex_funct3         <= 3'b000;
            ex_funct7_bit5    <= 1'b0;

            ex_RegWrite       <= 1'b0;
            ex_ALUSrc         <= 1'b0;
            ex_MemRead        <= 1'b0;
            ex_MemWrite       <= 1'b0;
            ex_MemToReg       <= 1'b0;
            ex_Branch         <= 1'b0;
            ex_ALUOp          <= 2'b00;

            ex_valid          <= 1'b0;

        end

        // ----------------------------------------------------
        // STALL
        //
        // Preserve the current ID/EX contents.
        //
        // The main load-use stall mechanism will normally
        // inject a bubble into ID/EX rather than using this
        // hold behavior directly. This input is retained to
        // make the pipeline register independently controllable
        // and testable.
        // ----------------------------------------------------

        else if (stall) begin

            ex_pc             <= ex_pc;
            ex_pc_plus4       <= ex_pc_plus4;

            ex_register_data1 <= ex_register_data1;
            ex_register_data2 <= ex_register_data2;

            ex_immediate      <= ex_immediate;

            ex_rs1            <= ex_rs1;
            ex_rs2            <= ex_rs2;
            ex_rd             <= ex_rd;

            ex_funct3         <= ex_funct3;
            ex_funct7_bit5    <= ex_funct7_bit5;

            ex_RegWrite       <= ex_RegWrite;
            ex_ALUSrc         <= ex_ALUSrc;
            ex_MemRead        <= ex_MemRead;
            ex_MemWrite       <= ex_MemWrite;
            ex_MemToReg       <= ex_MemToReg;
            ex_Branch         <= ex_Branch;
            ex_ALUOp          <= ex_ALUOp;

            ex_valid          <= ex_valid;

        end

        // ----------------------------------------------------
        // NORMAL PIPELINE ADVANCE
        // ----------------------------------------------------

        else begin

            ex_pc             <= id_pc;
            ex_pc_plus4       <= id_pc_plus4;

            ex_register_data1 <= id_register_data1;
            ex_register_data2 <= id_register_data2;

            ex_immediate      <= id_immediate;

            ex_rs1            <= id_rs1;
            ex_rs2            <= id_rs2;
            ex_rd             <= id_rd;

            ex_funct3         <= id_funct3;
            ex_funct7_bit5    <= id_funct7_bit5;

            ex_RegWrite       <= id_RegWrite;
            ex_ALUSrc         <= id_ALUSrc;
            ex_MemRead        <= id_MemRead;
            ex_MemWrite       <= id_MemWrite;
            ex_MemToReg       <= id_MemToReg;
            ex_Branch         <= id_Branch;
            ex_ALUOp          <= id_ALUOp;

            ex_valid          <= 1'b1;

        end

    end

endmodule