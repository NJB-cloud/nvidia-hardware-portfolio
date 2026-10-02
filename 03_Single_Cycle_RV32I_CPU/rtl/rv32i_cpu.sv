// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Module: RV32I CPU Top Level
//
// Supported instructions:
//   R-type: ADD, SUB, AND, OR, XOR, SLT
//   LW
//   SW
//   BEQ
//
// Architecture:
//   PC -> Instruction Memory -> Control / Register File
//                              -> Immediate Generator
//                              -> ALU Control -> ALU
//                              -> Data Memory
//                              -> Write Back
// ============================================================

module rv32i_cpu #(
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256
)(
    input  logic        clk,
    input  logic        rst_n,

    // Debug / verification outputs
    output logic [31:0] current_pc,
    output logic [31:0] instruction,
    output logic [31:0] alu_result,
    output logic [31:0] writeback_data
);

    // ========================================================
    // PC signals
    // ========================================================

    logic [31:0] next_pc;
    logic [31:0] pc_plus4;
    logic [31:0] branch_target;

    // ========================================================
    // Instruction signals
    // ========================================================

    logic [6:0] opcode;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic       funct7_bit5;

    // ========================================================
    // Control signals
    // ========================================================

    logic       RegWrite;
    logic       ALUSrc;
    logic       MemRead;
    logic       MemWrite;
    logic       MemToReg;
    logic       Branch;
    logic [1:0] ALUOp;

    // ========================================================
    // Register File
    // ========================================================

    logic [31:0] register_data1;
    logic [31:0] register_data2;

    // ========================================================
    // Immediate Generator
    // ========================================================

    logic [31:0] immediate;

    // ========================================================
    // ALU Control
    // ========================================================

    logic [3:0] alu_control;

    // ========================================================
    // ALU
    // ========================================================

    logic [31:0] alu_input_b;
    logic        alu_zero;

    // ========================================================
    // Data Memory
    // ========================================================

    logic [31:0] data_memory [0:DMEM_DEPTH-1];
    logic [31:0] memory_read_data;

    // ========================================================
    // Instruction field extraction
    // ========================================================

    assign opcode      = instruction[6:0];
    assign rd          = instruction[11:7];
    assign funct3      = instruction[14:12];
    assign rs1         = instruction[19:15];
    assign rs2         = instruction[24:20];
    assign funct7_bit5 = instruction[30];

    // ========================================================
    // PC + 4
    // ========================================================

    assign pc_plus4 = current_pc + 32'd4;

    // ========================================================
    // Branch target
    // ========================================================

    assign branch_target = current_pc + immediate;

    // ========================================================
    // Next PC
    //
    // BEQ:
    //   Branch = 1
    //   ALU zero = 1
    // ========================================================

    always_comb begin

        if (Branch && alu_zero)
            next_pc = branch_target;
        else
            next_pc = pc_plus4;

    end

    // ========================================================
    // Program Counter
    // ========================================================

    pc u_pc (
        .clk       (clk),
        .rst_n     (rst_n),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    // ========================================================
    // Instruction Memory
    // ========================================================

    instruction_memory #(
        .DEPTH(IMEM_DEPTH)
    ) u_instruction_memory (
        .address    (current_pc),
        .instruction(instruction)
    );

    // ========================================================
    // Main Control Unit
    // ========================================================

    control_unit u_control_unit (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemToReg (MemToReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // ========================================================
    // Register File
    // ========================================================

    register_file u_register_file (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs1        (rs1),
        .rs2        (rs2),
        .read_data1 (register_data1),
        .read_data2 (register_data2),
        .rd         (rd),
        .write_data (writeback_data),
        .reg_write  (RegWrite)
    );

    // ========================================================
    // Immediate Generator
    // ========================================================

    immediate_generator u_immediate_generator (
        .instruction(instruction),
        .immediate  (immediate)
    );

    // ========================================================
    // ALU Control
    // ========================================================

    alu_control u_alu_control (
        .alu_op      (ALUOp),
        .funct3      (funct3),
        .funct7_bit5 (funct7_bit5),
        .alu_control (alu_control)
    );

    // ========================================================
    // ALU input selection
    //
    // R-type / BEQ:
    //   register_data2
    //
    // LW / SW:
    //   immediate
    // ========================================================

    always_comb begin

        if (ALUSrc)
            alu_input_b = immediate;
        else
            alu_input_b = register_data2;

    end

    // ========================================================
    // ALU
    // ========================================================

    alu u_alu (
        .a          (register_data1),
        .b          (alu_input_b),
        .alu_control(alu_control),
        .result     (alu_result),
        .zero       (alu_zero)
    );

    // ========================================================
    // Data Memory Read
    //
    // Word-aligned byte address.
    // ========================================================

    always_comb begin

        if (MemRead) begin

            if (alu_result[31:2] < DMEM_DEPTH)
                memory_read_data = data_memory[alu_result[31:2]];
            else
                memory_read_data = 32'h0000_0000;

        end
        else begin

            memory_read_data = 32'h0000_0000;

        end

    end

    // ========================================================
    // Data Memory Write
    //
    // SW stores at the rising clock edge.
    // ========================================================

    always_ff @(posedge clk) begin

        if (MemWrite) begin

            if (alu_result[31:2] < DMEM_DEPTH)
                data_memory[alu_result[31:2]] <= register_data2;

        end

    end

    // ========================================================
    // Write-back MUX
    // ========================================================

    always_comb begin

        if (MemToReg)
            writeback_data = memory_read_data;
        else
            writeback_data = alu_result;

    end

endmodule