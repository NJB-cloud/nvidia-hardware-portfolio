// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Functional Coverage Verification Testbench
//
// Purpose:
//   Measure which instruction classes and pipeline-control
//   scenarios are actually exercised by the verification suite.
//
// Coverage categories:
//   Instruction:
//     ADD, SUB, AND, OR, XOR, SLT, LW, SW, BEQ
//
//   Forwarding:
//     EX/MEM forwarding
//     MEM/WB forwarding
//     Dual-operand forwarding
//
//   Hazard:
//     Load-use stall
//
//   Branch:
//     Taken
//     Not taken
//     Flush
//
//   Architecture:
//     x0 protection
//
// Simulator:
//   Icarus Verilog 12.0
//
// NOTE:
//   This is explicit portable functional coverage rather than
//   SystemVerilog covergroup syntax, allowing it to run in the
//   current Icarus-based environment.
// ============================================================

`timescale 1ns/1ps

module pipelined_functional_coverage_tb;

    // ========================================================
    // Clock / reset
    // ========================================================

    logic clk;
    logic rst_n;

    // ========================================================
    // DUT debug outputs
    // ========================================================

    logic [31:0] current_pc;
    logic [31:0] instruction;

    logic [31:0] ex_alu_result_debug;
    logic [31:0] mem_alu_result_debug;
    logic [31:0] wb_data_debug;

    logic        stall_debug;
    logic [1:0]  forward_a_debug;
    logic [1:0]  forward_b_debug;

    // ========================================================
    // Coverage counters
    // ========================================================

    integer cov_add;
    integer cov_sub;
    integer cov_and;
    integer cov_or;
    integer cov_xor;
    integer cov_slt;
    integer cov_lw;
    integer cov_sw;
    integer cov_beq;

    integer cov_ex_mem_forward;
    integer cov_mem_wb_forward;
    integer cov_dual_forward;

    integer cov_load_use;

    integer cov_branch_taken;
    integer cov_branch_not_taken;
    integer cov_branch_flush;

    integer cov_x0_protection;

    integer instruction_bins_hit;
    integer forwarding_bins_hit;
    integer hazard_bins_hit;
    integer branch_bins_hit;
    integer architecture_bins_hit;

    integer total_bins;
    integer hit_bins;

    integer cycle_count;

    // ========================================================
    // Opcodes
    // ========================================================

    localparam [6:0] OPCODE_R   = 7'b0110011;
    localparam [6:0] OPCODE_LW  = 7'b0000011;
    localparam [6:0] OPCODE_SW  = 7'b0100011;
    localparam [6:0] OPCODE_BEQ = 7'b1100011;

    // ========================================================
    // Function fields
    // ========================================================

    localparam [6:0] FUNCT7_ADD = 7'b0000000;
    localparam [6:0] FUNCT7_SUB = 7'b0100000;

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_SLT     = 3'b010;
    localparam [2:0] F3_XOR     = 3'b100;
    localparam [2:0] F3_OR      = 3'b110;
    localparam [2:0] F3_AND     = 3'b111;
    localparam [2:0] F3_LW_SW   = 3'b010;

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

        forever
            #5 clk = ~clk;

    end

    // ========================================================
    // R-type encoder
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

    // ========================================================
    // I-type LW encoder
    // ========================================================

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

    // ========================================================
    // S-type SW encoder
    // ========================================================

    function automatic [31:0] enc_s_sw;

        input signed [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;

        begin

            enc_s_sw = {
                imm[11:5],
                rs2,
                rs1,
                F3_LW_SW,
                imm[4:0],
                OPCODE_SW
            };

        end

    endfunction

    // ========================================================
    // B-type BEQ encoder
    // ========================================================

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

    // ========================================================
    // NOP
    // ========================================================

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

            for (i = 0; i < 256; i = i + 1) begin

                dut.u_instruction_memory.memory[i] =
                    32'h0000_0013;

                dut.data_memory[i] =
                    32'h0000_0000;

            end

        end

    endtask

    // ========================================================
    // Reset
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
    // Coverage monitor
    //
    // Samples the integrated processor at each clock.
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            cycle_count = cycle_count + 1;

            // ------------------------------------------------
            // Instruction coverage
            //
            // ID-stage instruction is counted only when valid.
            // ------------------------------------------------

            if (dut.id_valid) begin

                case (dut.id_opcode)

                    OPCODE_R: begin

                        case (dut.id_funct3)

                            F3_ADD_SUB: begin

                                if (dut.id_funct7_bit5)
                                    cov_sub = cov_sub + 1;
                                else
                                    cov_add = cov_add + 1;

                            end

                            F3_AND:
                                cov_and = cov_and + 1;

                            F3_OR:
                                cov_or = cov_or + 1;

                            F3_XOR:
                                cov_xor = cov_xor + 1;

                            F3_SLT:
                                cov_slt = cov_slt + 1;

                            default: begin
                            end

                        endcase

                    end

                    OPCODE_LW:
                        cov_lw = cov_lw + 1;

                    OPCODE_SW:
                        cov_sw = cov_sw + 1;

                    OPCODE_BEQ:
                        cov_beq = cov_beq + 1;

                    default: begin
                    end

                endcase

            end

            // ------------------------------------------------
            // Forwarding coverage
            //
            // 00 = register file
            // 01 = MEM/WB
            // 10 = EX/MEM
            // ------------------------------------------------

            if ((forward_a_debug == 2'b10) ||
                (forward_b_debug == 2'b10)) begin

                cov_ex_mem_forward =
                    cov_ex_mem_forward + 1;

            end

            if ((forward_a_debug == 2'b01) ||
                (forward_b_debug == 2'b01)) begin

                cov_mem_wb_forward =
                    cov_mem_wb_forward + 1;

            end

            if ((forward_a_debug != 2'b00) &&
                (forward_b_debug != 2'b00)) begin

                cov_dual_forward =
                    cov_dual_forward + 1;

            end

            // ------------------------------------------------
            // Load-use hazard coverage
            // ------------------------------------------------

            if (dut.id_ex_flush &&
                !dut.branch_taken) begin

                cov_load_use =
                    cov_load_use + 1;

            end

            // ------------------------------------------------
            // Branch coverage
            // ------------------------------------------------

            if (dut.ex_valid &&
                dut.ex_Branch) begin

                if (dut.branch_taken) begin

                    cov_branch_taken =
                        cov_branch_taken + 1;

                    // A taken branch causes IF/ID flushing
                    // in the current implementation.

                    if (dut.if_id_flush)
                        cov_branch_flush =
                            cov_branch_flush + 1;

                end

                else begin

                    cov_branch_not_taken =
                        cov_branch_not_taken + 1;

                end

            end

        end

    end

    // ========================================================
    // Test 1
    //
    // Instruction-class coverage:
    //
    // ADD
    // SUB
    // AND
    // OR
    // XOR
    // SLT
    // LW
    // SW
    // ========================================================

    task automatic test_instruction_classes;

        begin

            clear_state;

            // ADD x6,x1,x2
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // SUB x7,x2,x1
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_SUB,
                    5'd1,
                    5'd2,
                    F3_ADD_SUB,
                    5'd7
                );

            // AND x8,x1,x2
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_AND,
                    5'd8
                );

            // OR x9,x1,x2
            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_OR,
                    5'd9
                );

            // XOR x10,x1,x2
            dut.u_instruction_memory.memory[4] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_XOR,
                    5'd10
                );

            // SLT x11,x1,x2
            dut.u_instruction_memory.memory[5] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_SLT,
                    5'd11
                );

            // SW x6,0(x0)
            dut.u_instruction_memory.memory[6] =
                enc_s_sw(
                    12'sd0,
                    5'd6,
                    5'd0
                );

            // LW x12,0(x0)
            dut.u_instruction_memory.memory[7] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd12
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

        end

    endtask

    // ========================================================
    // Test 2
    //
    // EX/MEM forwarding
    // ========================================================

    task automatic test_ex_mem_forwarding;

        begin

            clear_state;

            // ADD x6,x1,x2
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // ADD x7,x6,x1
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

            run_pipeline(14);

        end

    endtask

    // ========================================================
    // Test 3
    //
    // MEM/WB forwarding
    //
    // Dependency separated enough to exercise an older
    // in-flight result.
    // ========================================================

    task automatic test_mem_wb_forwarding;

        begin

            clear_state;

            // ADD x6,x1,x2
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // Independent instruction
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd4,
                    5'd3,
                    F3_ADD_SUB,
                    5'd7
                );

            // Consumer of x6
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd8
                );

            reset_cpu;

            seed_registers(
                32'd10,
                32'd20,
                32'd5,
                32'd7,
                32'd0
            );

            run_pipeline(16);

        end

    endtask

    // ========================================================
    // Test 4
    //
    // Dual-operand forwarding
    // ========================================================

    task automatic test_dual_forwarding;

        begin

            clear_state;

            // x6 = x1 + x2 = 30
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // x7 = x3 + x4 = 12
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd4,
                    5'd3,
                    F3_ADD_SUB,
                    5'd7
                );

            // x8 = x6 + x7
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
                32'd5,
                32'd7,
                32'd0
            );

            run_pipeline(16);

        end

    endtask

    // ========================================================
    // Test 5
    //
    // Load-use hazard
    // ========================================================

    task automatic test_load_use;

        begin

            clear_state;

            dut.data_memory[0] = 32'd20;

            // LW x6,0(x0)
            dut.u_instruction_memory.memory[0] =
                enc_i_lw(
                    12'sd0,
                    5'd0,
                    5'd6
                );

            // ADD x7,x6,x1
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

            run_pipeline(16);

        end

    endtask

    // ========================================================
    // Test 6
    //
    // Taken branch + branch flush
    // ========================================================

    task automatic test_branch_taken;

        begin

            clear_state;

            // x6 = x1 + x2 = 30
            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd6
                );

            // BEQ x6,x3,+8
            //
            // x3 = 30, so branch is taken.
            dut.u_instruction_memory.memory[1] =
                enc_b(
                    13'sd8,
                    5'd3,
                    5'd6
                );

            // Wrong-path instruction.
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
                    F3_ADD_SUB,
                    5'd8
                );

            // Branch target.
            dut.u_instruction_memory.memory[3] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
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

            run_pipeline(18);

        end

    endtask

    // ========================================================
    // Test 7
    //
    // Not-taken branch
    // ========================================================

    task automatic test_branch_not_taken;

        begin

            clear_state;

            // BEQ x1,x2,+8
            //
            // x1 = 10
            // x2 = 20
            // Therefore not taken.
            dut.u_instruction_memory.memory[0] =
                enc_b(
                    13'sd8,
                    5'd2,
                    5'd1
                );

            // Sequential instruction must execute.
            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd2,
                    F3_ADD_SUB,
                    5'd6
                );

            // Branch target.
            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd1,
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

            run_pipeline(16);

        end

    endtask

    // ========================================================
    // x0 architectural check
    // ========================================================

    task automatic check_x0;

        begin

            if (dut.u_register_file.registers[0]
                === 32'h0000_0000) begin

                cov_x0_protection = 1;

                $display(
                    "COVERAGE PASS: x0 protection"
                );

            end

            else begin

                $display(
                    "COVERAGE FAIL: x0 protection"
                );

            end

        end

    endtask

    // ========================================================
    // Calculate final coverage
    // ========================================================

    task automatic calculate_coverage;

        begin

            // ------------------------------------------------
            // Instruction bins
            // ------------------------------------------------

            instruction_bins_hit = 0;

            if (cov_add > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_sub > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_and > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_or > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_xor > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_slt > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_lw > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_sw > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            if (cov_beq > 0)
                instruction_bins_hit =
                    instruction_bins_hit + 1;

            // ------------------------------------------------
            // Forwarding bins
            // ------------------------------------------------

            forwarding_bins_hit = 0;

            if (cov_ex_mem_forward > 0)
                forwarding_bins_hit =
                    forwarding_bins_hit + 1;

            if (cov_mem_wb_forward > 0)
                forwarding_bins_hit =
                    forwarding_bins_hit + 1;

            if (cov_dual_forward > 0)
                forwarding_bins_hit =
                    forwarding_bins_hit + 1;

            // ------------------------------------------------
            // Hazard bins
            // ------------------------------------------------

            hazard_bins_hit = 0;

            if (cov_load_use > 0)
                hazard_bins_hit =
                    hazard_bins_hit + 1;

            // ------------------------------------------------
            // Branch bins
            // ------------------------------------------------

            branch_bins_hit = 0;

            if (cov_branch_taken > 0)
                branch_bins_hit =
                    branch_bins_hit + 1;

            if (cov_branch_not_taken > 0)
                branch_bins_hit =
                    branch_bins_hit + 1;

            if (cov_branch_flush > 0)
                branch_bins_hit =
                    branch_bins_hit + 1;

            // ------------------------------------------------
            // Architecture bins
            // ------------------------------------------------

            architecture_bins_hit = 0;

            if (cov_x0_protection > 0)
                architecture_bins_hit =
                    architecture_bins_hit + 1;

            // ------------------------------------------------
            // Total
            // ------------------------------------------------

            total_bins =
                9 +
                3 +
                1 +
                3 +
                1;

            hit_bins =
                instruction_bins_hit +
                forwarding_bins_hit +
                hazard_bins_hit +
                branch_bins_hit +
                architecture_bins_hit;

        end

    endtask

    // ========================================================
    // Final report
    // ========================================================

    task automatic print_report;

        integer coverage_percent;

        begin

            calculate_coverage;

            coverage_percent =
                (hit_bins * 100) / total_bins;

            $display("");
            $display("============================================================");
            $display("             FUNCTIONAL COVERAGE REPORT");
            $display("============================================================");

            $display("");

            $display(
                "Instruction bins : %0d / 9",
                instruction_bins_hit
            );

            $display(
                "Forwarding bins  : %0d / 3",
                forwarding_bins_hit
            );

            $display(
                "Hazard bins      : %0d / 1",
                hazard_bins_hit
            );

            $display(
                "Branch bins      : %0d / 3",
                branch_bins_hit
            );

            $display(
                "Architecture bins: %0d / 1",
                architecture_bins_hit
            );

            $display("");

            $display(
                "TOTAL BINS       : %0d / %0d",
                hit_bins,
                total_bins
            );

            $display(
                "FUNCTIONAL COVERAGE: %0d%%",
                coverage_percent
            );

            $display("");

            $display("------------------------------------------------------------");
            $display("Instruction counters");
            $display("------------------------------------------------------------");

            $display("ADD = %0d", cov_add);
            $display("SUB = %0d", cov_sub);
            $display("AND = %0d", cov_and);
            $display("OR  = %0d", cov_or);
            $display("XOR = %0d", cov_xor);
            $display("SLT = %0d", cov_slt);
            $display("LW  = %0d", cov_lw);
            $display("SW  = %0d", cov_sw);
            $display("BEQ = %0d", cov_beq);

            $display("");

            $display("------------------------------------------------------------");
            $display("Pipeline-control counters");
            $display("------------------------------------------------------------");

            $display(
                "EX/MEM forwarding = %0d",
                cov_ex_mem_forward
            );

            $display(
                "MEM/WB forwarding = %0d",
                cov_mem_wb_forward
            );

            $display(
                "Dual forwarding   = %0d",
                cov_dual_forward
            );

            $display(
                "Load-use hazards  = %0d",
                cov_load_use
            );

            $display(
                "Taken branches    = %0d",
                cov_branch_taken
            );

            $display(
                "Not-taken branches= %0d",
                cov_branch_not_taken
            );

            $display(
                "Branch flushes    = %0d",
                cov_branch_flush
            );

            $display(
                "x0 protection     = %0d",
                cov_x0_protection
            );

            $display("");
            $display("============================================================");

            if (hit_bins == total_bins) begin

                $display(
                    "ALL DEFINED FUNCTIONAL COVERAGE BINS HIT"
                );

            end

            else begin

                $display(
                    "FUNCTIONAL COVERAGE GAPS REMAIN"
                );

            end

            $display("============================================================");

        end

    endtask

    // ========================================================
    // Main
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initialize counters
        // ----------------------------------------------------

        cov_add = 0;
        cov_sub = 0;
        cov_and = 0;
        cov_or  = 0;
        cov_xor = 0;
        cov_slt = 0;
        cov_lw  = 0;
        cov_sw  = 0;
        cov_beq = 0;

        cov_ex_mem_forward = 0;
        cov_mem_wb_forward = 0;
        cov_dual_forward   = 0;

        cov_load_use = 0;

        cov_branch_taken     = 0;
        cov_branch_not_taken = 0;
        cov_branch_flush     = 0;

        cov_x0_protection = 0;

        instruction_bins_hit = 0;
        forwarding_bins_hit = 0;
        hazard_bins_hit = 0;
        branch_bins_hit = 0;
        architecture_bins_hit = 0;

        total_bins = 0;
        hit_bins = 0;

        cycle_count = 0;

        rst_n = 1'b0;

        $display("");
        $display("============================================================");
        $display("       RV32I FUNCTIONAL COVERAGE VERIFICATION");
        $display("============================================================");
        $display("");

        // ----------------------------------------------------
        // Execute coverage scenarios
        // ----------------------------------------------------

        $display("Running instruction-class coverage...");
        test_instruction_classes;

        $display("Running EX/MEM forwarding coverage...");
        test_ex_mem_forwarding;

        $display("Running MEM/WB forwarding coverage...");
        test_mem_wb_forwarding;

        $display("Running dual-operand forwarding coverage...");
        test_dual_forwarding;

        $display("Running load-use hazard coverage...");
        test_load_use;

        $display("Running taken-branch coverage...");
        test_branch_taken;

        $display("Running not-taken branch coverage...");
        test_branch_not_taken;

        // ----------------------------------------------------
        // x0 check
        // ----------------------------------------------------

        check_x0;

        // ----------------------------------------------------
        // Final report
        // ----------------------------------------------------

        print_report;

        $display("");
        $display(
            "TOTAL MONITORED CYCLES = %0d",
            cycle_count
        );

        $display("");

        $finish;

    end

endmodule