// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Testbench: Program-Level Regression Verification
//
// Regression goals:
//   - ALU execution
//   - RAW dependencies
//   - EX/MEM forwarding
//   - MEM/WB forwarding
//   - dual-operand forwarding
//   - store-data forwarding
//   - load/store operation
//   - load-use hazard
//   - taken branch
//   - not-taken branch
//   - branch flushing
//   - x0 protection
//   - negative arithmetic
//   - mixed execution
//
// Current supported ISA:
//   ADD, SUB, AND, OR, XOR, SLT
//   LW, SW, BEQ
// ============================================================

`timescale 1ns/1ps

module pipelined_regression_tb;

    logic clk;
    logic rst_n;

    logic [31:0] current_pc;
    logic [31:0] instruction;

    logic [31:0] ex_alu_result_debug;
    logic [31:0] mem_alu_result_debug;
    logic [31:0] wb_data_debug;

    logic        stall_debug;
    logic [1:0]  forward_a_debug;
    logic [1:0]  forward_b_debug;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    // ========================================================
    // DUT
    // ========================================================

    pipelined_core dut (
        .clk                  (clk),
        .rst_n                (rst_n),

        .current_pc           (current_pc),
        .instruction          (instruction),

        .ex_alu_result_debug  (ex_alu_result_debug),
        .mem_alu_result_debug (mem_alu_result_debug),
        .wb_data_debug        (wb_data_debug),

        .stall_debug          (stall_debug),
        .forward_a_debug      (forward_a_debug),
        .forward_b_debug      (forward_b_debug)
    );

    // ========================================================
    // Clock
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Opcodes
    // ========================================================

    localparam [6:0] OPCODE_R   = 7'b0110011;
    localparam [6:0] OPCODE_LW  = 7'b0000011;
    localparam [6:0] OPCODE_SW  = 7'b0100011;
    localparam [6:0] OPCODE_BEQ = 7'b1100011;

    // ========================================================
    // R-type fields
    // ========================================================

    localparam [6:0] FUNCT7_ADD = 7'b0000000;
    localparam [6:0] FUNCT7_SUB = 7'b0100000;

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_XOR     = 3'b100;
    localparam [2:0] F3_SLT     = 3'b010;
    localparam [2:0] F3_LW_SW   = 3'b010;

    // ========================================================
    // Instruction encoders
    // ========================================================

    function automatic [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;

        begin
            enc_r = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                OPCODE_R
            };
        end
    endfunction


    function automatic [31:0] enc_i_lw;
        input signed [11:0] imm;
        input [4:0] rs1;
        input [4:0] rd;

        begin
            enc_i_lw = {
                imm[11:0],
                rs1,
                F3_LW_SW,
                rd,
                OPCODE_LW
            };
        end
    endfunction


    function automatic [31:0] enc_s;
        input signed [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;

        begin
            enc_s = {
                imm[11:5],
                rs2,
                rs1,
                F3_LW_SW,
                imm[4:0],
                OPCODE_SW
            };
        end
    endfunction


    function automatic [31:0] enc_b;
        input signed [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;

        begin
            enc_b = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                3'b000,
                imm[4:1],
                imm[11],
                OPCODE_BEQ
            };
        end
    endfunction


    function automatic [31:0] nop;

        begin
            nop = 32'h0000_0013;
        end

    endfunction

    // ========================================================
    // Clear memories
    // ========================================================

    task automatic clear_state;

        integer i;

        begin

            // IMPORTANT:
            // Use the explicit NOP encoding here.
            // NOP = ADDI x0,x0,0 = 32'h00000013.
            //
            // This avoids treating the nop function as a
            // variable, which caused the previous compilation
            // error.
            for (i = 0; i < 256; i = i + 1)
                dut.u_instruction_memory.memory[i] =
                    32'h0000_0013;

            for (i = 0; i < 256; i = i + 1)
                dut.data_memory[i] =
                    32'h0000_0000;

        end

    endtask

    // ========================================================
    // Reset CPU
    // ========================================================

    task automatic reset_cpu;

        begin

            rst_n = 1'b0;

            repeat (2)
                @(posedge clk);

            #1;

            rst_n = 1'b1;

            #1;

        end

    endtask

    // ========================================================
    // Seed registers
    // ========================================================

    task automatic seed_registers;

        input [31:0] x1_value;
        input [31:0] x2_value;
        input [31:0] x3_value;
        input [31:0] x4_value;
        input [31:0] x5_value;

        begin

            dut.u_register_file.registers[1] = x1_value;
            dut.u_register_file.registers[2] = x2_value;
            dut.u_register_file.registers[3] = x3_value;
            dut.u_register_file.registers[4] = x4_value;
            dut.u_register_file.registers[5] = x5_value;

        end

    endtask

    // ========================================================
    // Run pipeline
    // ========================================================

    task automatic run_pipeline;

        input integer cycles;

        integer i;

        begin

            for (i = 0; i < cycles; i = i + 1)
                @(posedge clk);

            #1;

        end

    endtask

    // ========================================================
    // Register check
    // ========================================================

    task automatic check_reg;

        input integer reg_num;
        input [31:0] expected;
        input [255:0] name;

        reg [31:0] actual;

        begin

            total_tests = total_tests + 1;

            actual =
                dut.u_register_file.registers[reg_num];

            if (actual === expected) begin

                passed_tests = passed_tests + 1;

                $display(
                    "PASS: %-42s x%0d Expected=%h Got=%h",
                    name,
                    reg_num,
                    expected,
                    actual
                );

            end

            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL: %-42s x%0d Expected=%h Got=%h",
                    name,
                    reg_num,
                    expected,
                    actual
                );

            end

        end

    endtask

    // ========================================================
    // Memory check
    // ========================================================

    task automatic check_mem;

        input integer index;
        input [31:0] expected;
        input [255:0] name;

        reg [31:0] actual;

        begin

            total_tests = total_tests + 1;

            actual = dut.data_memory[index];

            if (actual === expected) begin

                passed_tests = passed_tests + 1;

                $display(
                    "PASS: %-42s MEM[%0d] Expected=%h Got=%h",
                    name,
                    index,
                    expected,
                    actual
                );

            end

            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL: %-42s MEM[%0d] Expected=%h Got=%h",
                    name,
                    index,
                    expected,
                    actual
                );

            end

        end

    endtask

    // ========================================================
    // TEST 01
    // Basic ADD
    // ========================================================

    task automatic test_01;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'd30,
                "01 Basic ADD"
            );

        end

    endtask

    // ========================================================
    // TEST 02
    // SUB
    // ========================================================

    task automatic test_02;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_SUB,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd30,
                32'd10,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'd20,
                "02 Basic SUB"
            );

        end

    endtask

    // ========================================================
    // TEST 03
    // RAW dependency / EX-MEM forwarding
    //
    // x6 = x1 + x2
    // x7 = x6 + x1
    // ========================================================

    task automatic test_03;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(12);

            check_reg(
                6,
                32'd30,
                "03 EX/MEM dependency result"
            );

            check_reg(
                7,
                32'd40,
                "03 EX/MEM forwarding"
            );

        end

    endtask

    // ========================================================
    // TEST 04
    // Two consecutive dependencies
    // ========================================================

    task automatic test_04;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7
                );

            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_SUB,
                    5'd2,
                    5'd7,
                    F3_ADD_SUB,
                    5'd8
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(14);

            check_reg(
                8,
                32'd20,
                "04 Multiple RAW dependencies"
            );

        end

    endtask

    // ========================================================
    // TEST 05
    // Both operands forwarded
    //
    // x6 = x1+x2 = 30
    // x7 = x3+x4 = 70
    // x8 = x6+x7 = 100
    // ========================================================

    task automatic test_05;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd4,
                    5'd3,
                    F3_ADD_SUB,
                    5'd7
                );

            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd7,
                    5'd6,
                    F3_ADD_SUB,
                    5'd8
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd30,
                32'd40,
                32'd0
            );

            run_pipeline(14);

            check_reg(
                8,
                32'd100,
                "05 Dual-operand forwarding"
            );

        end

    endtask

    // ========================================================
    // TEST 06
    // Store-data forwarding
    // ========================================================

    task automatic test_06;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_s(
                    12'sd0,
                    5'd6,
                    5'd0
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(12);

            check_mem(
                0,
                32'd30,
                "06 Store-data forwarding"
            );

        end

    endtask

    // ========================================================
    // TEST 07
    // Load
    // ========================================================

    task automatic test_07;

        begin

            clear_state;

            dut.data_memory[4] = 32'h0000_0055;

            dut.u_instruction_memory.memory[0] =
                enc_i_lw(
                    12'sd16,
                    5'd0,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd0,
                32'd0,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'h0000_0055,
                "07 LW memory read"
            );

        end

    endtask

    // ========================================================
    // TEST 08
    // Load-use dependency
    //
    // LW x6,0(x0)
    // ADD x7,x6,x1
    //
    // Must require a hazard stall.
    // ========================================================

    task automatic test_08;

        begin

            clear_state;

            dut.data_memory[0] = 32'd30;

            dut.u_instruction_memory.memory[0] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd0,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(14);

            check_reg(
                6,
                32'd30,
                "08 Load-use load result"
            );

            check_reg(
                7,
                32'd40,
                "08 Load-use dependent ADD"
            );

        end

    endtask

    // ========================================================
    // TEST 09
    // LW -> ADD -> SUB dependency chain
    // ========================================================

    task automatic test_09;

        begin

            clear_state;

            dut.data_memory[0] = 32'd50;

            dut.u_instruction_memory.memory[0] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7
                );

            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_SUB,
                    5'd2,
                    5'd7,
                    F3_ADD_SUB,
                    5'd8
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(16);

            check_reg(
                8,
                32'd40,
                "09 Load dependency chain"
            );

        end

    endtask

    // ========================================================
    // TEST 10
    // BEQ taken + flush
    //
    // x1 == x2
    //
    // Instruction at index 2 must be skipped.
    // Target at index 3 executes.
    // ========================================================

    task automatic test_10;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_b(
                    13'sd12,
                    5'd2,
                    5'd1
                );

            // This instruction must be flushed.
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // This instruction must also be skipped.
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd2,
                    F3_ADD_SUB,
                    5'd6
                );

            // Branch target: index 3.
            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd2,
                    F3_ADD_SUB,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd10,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(14);

            check_reg(
                7,
                32'd20,
                "10 BEQ taken target"
            );

            check_reg(
                6,
                32'd0,
                "10 Branch flush protection"
            );

        end

    endtask

    // ========================================================
    // TEST 11
    // BEQ not taken
    // ========================================================

    task automatic test_11;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_b(
                    13'sd8,
                    5'd2,
                    5'd1
                );

            // Executes because branch is not taken.
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd2,
                    F3_ADD_SUB,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(12);

            check_reg(
                6,
                32'd30,
                "11 BEQ not taken"
            );

        end

    endtask

    // ========================================================
    // TEST 12
    // Negative arithmetic
    // ========================================================

    task automatic test_12;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_SUB,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd5,
                32'd10,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'hFFFF_FFFB,
                "12 Negative SUB"
            );

        end

    endtask

    // ========================================================
    // TEST 13
    // SLT true
    // ========================================================

    task automatic test_13;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_SLT,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd5,
                32'd10,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'd1,
                "13 Signed SLT true"
            );

        end

    endtask

    // ========================================================
    // TEST 14
    // SLT false
    // ========================================================

    task automatic test_14;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_SLT,
                    5'd6
                );

            reset_cpu;

            seed_registers(
                32'd20,
                32'd10,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                6,
                32'd0,
                "14 Signed SLT false"
            );

        end

    endtask

    // ========================================================
    // TEST 15
    // x0 protection
    // ========================================================

    task automatic test_15;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd0
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(10);

            check_reg(
                0,
                32'd0,
                "15 x0 protection"
            );

        end

    endtask

    // ========================================================
    // TEST 16
    // XOR dependency
    // ========================================================

    task automatic test_16;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_XOR,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_XOR,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'h0F0F_0000,
                32'h00FF_00FF,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(12);

            check_reg(
                7,
                32'h00FF_00FF,
                "16 XOR dependency"
            );

        end

    endtask

    // ========================================================
    // TEST 17
    // Multiple memory operations
    // ========================================================

    task automatic test_17;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_s(
                    12'sd4,
                    5'd6,
                    5'd0
                );

            dut.u_instruction_memory.memory[2] =
                enc_i_lw(
                    12'sd4,
                    5'd0,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(16);

            check_mem(
                1,
                32'd30,
                "17 Multiple store operations"
            );

            check_reg(
                7,
                32'd30,
                "17 Multiple load operations"
            );

        end

    endtask

    // ========================================================
    // TEST 18
    // Branch + forwarding
    // ========================================================

    task automatic test_18;

        begin

            clear_state;

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_b(
                    13'sd8,
                    5'd6,
                    5'd3
                );

            // Must be flushed if branch is taken.
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
                    F3_ADD_SUB,
                    5'd7
                );

            // Target.
            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd6,
                    5'd2,
                    F3_ADD_SUB,
                    5'd8
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd30,
                32'd0,
                32'd0
            );

            run_pipeline(16);

            check_reg(
                8,
                32'd50,
                "18 Branch plus forwarded value"
            );

            check_reg(
                7,
                32'd0,
                "18 Flushed instruction"
            );

        end

    endtask

    // ========================================================
    // TEST 19
    // Branch + memory interaction
    // ========================================================

    task automatic test_19;

        begin

            clear_state;

            dut.data_memory[0] = 32'd20;

            dut.u_instruction_memory.memory[0] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd6
                );

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7
                );

            dut.u_instruction_memory.memory[2] =
                enc_b(
                    13'sd8,
                    5'd3,
                    5'd7
                );

            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
                    F3_ADD_SUB,
                    5'd8
                );

            dut.u_instruction_memory.memory[4] =
                enc_r(
                    FUNCT7_ADD,
                    5'd7,
                    5'd2,
                    F3_ADD_SUB,
                    5'd9
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd30,
                32'd0,
                32'd0
            );

            run_pipeline(20);

            check_reg(
                7,
                32'd30,
                "19 Load result before branch"
            );

            check_reg(
                9,
                32'd50,
                "19 Branch memory interaction"
            );

            check_reg(
                8,
                32'd0,
                "19 Flushed memory-path instruction"
            );

        end

    endtask

    // ========================================================
    // TEST 20
    // Complete mixed pipeline program
    //
    // x3 = x1 + x2
    // SW x3,0(x0)
    // LW x4,0(x0)
    // x5 = x4 XOR x1
    // BEQ x5,x2,+8
    // skipped instruction
    // target ADD
    // ========================================================

    task automatic test_20;

        begin

            clear_state;

            // x3 = 10 + 20 = 30
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd3
                );

            // MEM[0] = x3
            dut.u_instruction_memory.memory[1] =
                enc_s(
                    12'sd0,
                    5'd3,
                    5'd0
                );

            // x4 = MEM[0] = 30
            dut.u_instruction_memory.memory[2] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd4
                );

            // x5 = x4 XOR x1 = 30 XOR 10 = 20
            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd4,
                    F3_XOR,
                    5'd5
                );

            // BEQ x5,x2,+8
            dut.u_instruction_memory.memory[4] =
                enc_b(
                    13'sd8,
                    5'd2,
                    5'd5
                );

            // This instruction must be flushed.
            dut.u_instruction_memory.memory[5] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
                    F3_ADD_SUB,
                    5'd7
                );

            // Target.
            // x7 = x5 + x1 = 20 + 10 = 30
            dut.u_instruction_memory.memory[6] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd5,
                    F3_ADD_SUB,
                    5'd7
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd0,
                32'd0,
                32'd0
            );

            run_pipeline(20);

            check_reg(
                3,
                32'd30,
                "20 Mixed ADD"
            );

            check_mem(
                0,
                32'd30,
                "20 Mixed SW"
            );

            check_reg(
                4,
                32'd30,
                "20 Mixed LW"
            );

            check_reg(
                5,
                32'd20,
                "20 Mixed XOR"
            );

            check_reg(
                7,
                32'd30,
                "20 Mixed branch target"
            );

        end

    endtask

    // ========================================================
    // Main regression
    // ========================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;
        // ====================================================
        // VCD waveform dump
        // ====================================================

        $dumpfile("waveform/pipelined_regression_wave.vcd");
        $dumpvars(0, pipelined_regression_tb);
        rst_n = 1'b0;

        $display("");
        $display("============================================================");
        $display("       RV32I 5-STAGE PIPELINE REGRESSION VERIFICATION");
        $display("============================================================");
        $display("");

        test_01;
        test_02;
        test_03;
        test_04;
        test_05;
        test_06;
        test_07;
        test_08;
        test_09;
        test_10;
        test_11;
        test_12;
        test_13;
        test_14;
        test_15;
        test_16;
        test_17;
        test_18;
        test_19;
        test_20;

        $display("");
        $display("============================================================");
        $display("             FINAL REGRESSION RESULT");
        $display("============================================================");

        $display(
            "CHECKS EXECUTED = %0d",
            total_tests
        );

        $display(
            "PASSED          = %0d",
            passed_tests
        );

        $display(
            "FAILED          = %0d",
            failed_tests
        );

        if (failed_tests == 0) begin

            $display("");
            $display("============================================================");
            $display("              ALL REGRESSION CHECKS PASSED");
            $display("============================================================");

        end

        else begin

            $display("");
            $display("============================================================");
            $display("              REGRESSION FAILURES DETECTED");
            $display("============================================================");

        end

        $finish;

    end

endmodule