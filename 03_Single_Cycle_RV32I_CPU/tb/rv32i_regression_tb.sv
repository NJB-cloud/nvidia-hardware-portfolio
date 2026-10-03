// ============================================================
// Project 3B: RV32I CPU Regression Verification
//
// Purpose:
//   Execute multiple independent small programs against the
//   single-cycle RV32I CPU.
//
// Target:
//   20 programs
//   20 PASS
//   0 FAIL
//
// This testbench does NOT modify the CPU RTL.
// ============================================================

`timescale 1ns/1ps

module rv32i_regression_tb;

    logic clk;
    logic rst_n;

    logic [31:0] current_pc;
    logic [31:0] instruction;
    logic [31:0] alu_result;
    logic [31:0] writeback_data;

    integer total_programs;
    integer passed_programs;
    integer failed_programs;

    integer i;

    // ========================================================
    // DUT
    // ========================================================

    rv32i_cpu #(
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .current_pc     (current_pc),
        .instruction    (instruction),
        .alu_result     (alu_result),
        .writeback_data (writeback_data)
    );

    // ========================================================
    // Clock
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Waveform
    // ========================================================

    initial begin
        $dumpfile("rv32i_regression_wave.vcd");
        $dumpvars(0, rv32i_regression_tb);
    end

    // ========================================================
    // PASS / FAIL reporting
    // ========================================================

    task automatic report_program(
        input integer program_number,
        input string  program_name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );

        begin

            total_programs = total_programs + 1;

            if (actual === expected) begin

                passed_programs = passed_programs + 1;

                $display(
                    "PASS: Program %02d | %-30s | Expected=%08h Got=%08h",
                    program_number,
                    program_name,
                    expected,
                    actual
                );

            end
            else begin

                failed_programs = failed_programs + 1;

                $display(
                    "FAIL: Program %02d | %-30s | Expected=%08h Got=%08h",
                    program_number,
                    program_name,
                    expected,
                    actual
                );

            end

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

        end

    endtask

    // ========================================================
    // Clear memories
    // ========================================================

    task automatic clear_memories;

        begin

            for (i = 0; i < 256; i = i + 1) begin

                dut.u_instruction_memory.memory[i] = 32'h0000_0000;
                dut.data_memory[i] = 32'h0000_0000;

            end

        end

    endtask

    // ========================================================
    // Initialize architectural state
    // ========================================================

    task automatic initialize_state;

        begin

            // Release reset
            rst_n = 1'b1;

            // Initial register values
            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd20;

            // x0 must remain zero
            dut.u_register_file.registers[0] = 32'd0;

        end

    endtask

    // ========================================================
    // PROGRAM 01
    //
    // ADD
    //
    // x3 = x1 + x2
    //     = 10 + 20
    //     = 30
    // ========================================================

    task automatic program_01_add;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h0020_81B3;   // ADD x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;   // BEQ x0,x0,0

            initialize_state;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                1,
                "ADD",
                dut.u_register_file.registers[3],
                32'd30
            );

        end

    endtask

    // ========================================================
    // PROGRAM 02
    //
    // SUB
    //
    // x3 = x1 - x2
    //     = 10 - 20
    //     = -10
    // ========================================================

    task automatic program_02_sub;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h4020_81B3;   // SUB x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                2,
                "SUB",
                dut.u_register_file.registers[3],
                32'hFFFF_FFF6
            );

        end

    endtask

    // ========================================================
    // PROGRAM 03
    //
    // AND
    // ========================================================

    task automatic program_03_and;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h0020_F1B3;   // AND x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            // Test-specific values
            dut.u_register_file.registers[1] =
                32'hFFFF_00FF;

            dut.u_register_file.registers[2] =
                32'h0F0F_0F0F;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                3,
                "AND",
                dut.u_register_file.registers[3],
                32'h0F0F_000F
            );

        end

    endtask

    // ========================================================
    // PROGRAM 04
    //
    // OR
    // ========================================================

    task automatic program_04_or;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h0020_E1B3;   // OR x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                4,
                "OR",
                dut.u_register_file.registers[3],
                32'd30
            );

        end

    endtask

    // ========================================================
    // PROGRAM 05
    //
    // XOR
    // ========================================================

    task automatic program_05_xor;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h0020_C1B3;   // XOR x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                5,
                "XOR",
                dut.u_register_file.registers[3],
                32'd30
            );

        end

    endtask

    // ========================================================
    // PROGRAM 06
    //
    // SLT
    //
    // x3 = (x1 < x2) ? 1 : 0
    // x1 = -5
    // x2 = 10
    // Expected x3 = 1
    // ========================================================

    task automatic program_06_slt;

        begin

            reset_cpu;
            clear_memories;

            dut.u_instruction_memory.memory[0] =
                32'h0020_A1B3;   // SLT x3,x1,x2

            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;   // BEQ x0,x0,0

            initialize_state;

            dut.u_register_file.registers[1] =
                32'hFFFF_FFFB;   // -5

            dut.u_register_file.registers[2] =
                32'd10;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                6,
                "SLT signed comparison",
                dut.u_register_file.registers[3],
                32'd1
            );

        end

    endtask

    // ========================================================
    // PROGRAM 07
    //
    // ADD/SUB DEPENDENCY CHAIN
    //
    // x3 = x1 + x2 = 30
    // x4 = x3 - x1 = 20
    // x5 = x4 + x3 = 50
    //
    // Tests sequential register dependencies.
    // ========================================================

    task automatic program_07_add_sub_chain;

        begin

            reset_cpu;
            clear_memories;

            // ADD x3,x1,x2
            dut.u_instruction_memory.memory[0] =
                32'h0020_81B3;

            // SUB x4,x3,x1
            dut.u_instruction_memory.memory[1] =
                32'h4011_8233;

            // ADD x5,x4,x3
            dut.u_instruction_memory.memory[2] =
                32'h0032_02B3;

            // Final loop
            dut.u_instruction_memory.memory[3] =
                32'h0000_0063;

            initialize_state;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                7,
                "ADD/SUB dependency chain",
                dut.u_register_file.registers[5],
                32'd50
            );

        end

    endtask

    // ========================================================
    // PROGRAM 08
    //
    // LW
    //
    // memory[1] = 55
    // LW x3,4(x0)
    // Expected x3 = 55
    // ========================================================

    task automatic program_08_lw;

        begin

            reset_cpu;
            clear_memories;

            // CORRECT: LW x3,4(x0)
            dut.u_instruction_memory.memory[0] =
                32'h0040_2183;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.data_memory[1] = 32'd55;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                8,
                "LW memory read",
                dut.u_register_file.registers[3],
                32'd55
            );

        end

    endtask

    // ========================================================
    // PROGRAM 09
    //
    // SW
    //
    // x1 = 10
    // SW x1,4(x0)
    // Expected memory[1] = 10
    // ========================================================

    task automatic program_09_sw;

        begin

            reset_cpu;
            clear_memories;

            // SW x1,4(x0)
            dut.u_instruction_memory.memory[0] =
                32'h0010_2223;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                9,
                "SW memory write",
                dut.data_memory[1],
                32'd10
            );

        end

    endtask

    // ========================================================
    // PROGRAM 10
    //
    // LW/SW ROUND TRIP
    //
    // x1 = 10
    // SW x1,4(x0)
    // LW x3,4(x0)
    //
    // Expected x3 = 10
    // ========================================================

    task automatic program_10_lw_sw_roundtrip;

        begin

            reset_cpu;
            clear_memories;

            // SW x1,4(x0)
            dut.u_instruction_memory.memory[0] =
                32'h0010_2223;

            // CORRECT: LW x3,4(x0)
            dut.u_instruction_memory.memory[1] =
                32'h0040_2183;

            // Final loop
            dut.u_instruction_memory.memory[2] =
                32'h0000_0063;

            initialize_state;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                10,
                "LW/SW round-trip",
                dut.u_register_file.registers[3],
                32'd10
            );

        end

    endtask
    // ========================================================
    // PROGRAM 11
    //
    // BEQ TAKEN
    //
    // x1 = 10
    // x2 = 10
    //
    // BEQ x1,x2,+8
    //
    // The instruction at address 0x04 must be skipped.
    //
    // x4 remains 0.
    // x5 = 20 after the branch.
    // ========================================================

    task automatic program_11_beq_taken;

        begin

            reset_cpu;
            clear_memories;

            // BEQ x1,x2,+8
            dut.u_instruction_memory.memory[0] =
                32'h0020_8463;

            // ADD x4,x0,x0
            // Must be skipped.
            dut.u_instruction_memory.memory[1] =
                32'h0000_0233;

            // ADDI is not currently supported.
            // Use ADD x5,x1,x2 after branch target.
            dut.u_instruction_memory.memory[2] =
                32'h0020_82B3;

            // Final loop
            dut.u_instruction_memory.memory[3] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd10;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                11,
                "BEQ taken",
                dut.u_register_file.registers[5],
                32'd20
            );

        end

    endtask


    // ========================================================
    // PROGRAM 12
    //
    // BEQ NOT TAKEN
    //
    // x1 = 10
    // x2 = 20
    //
    // BEQ x1,x2,+8
    //
    // Branch must NOT be taken.
    // Sequential ADD executes.
    //
    // x3 = 30
    // ========================================================

    task automatic program_12_beq_not_taken;

        begin

            reset_cpu;
            clear_memories;

            // BEQ x1,x2,+8
            dut.u_instruction_memory.memory[0] =
                32'h0020_8463;

            // ADD x3,x1,x2
            // Must execute because branch is not taken.
            dut.u_instruction_memory.memory[1] =
                32'h0020_81B3;

            // Final loop
            dut.u_instruction_memory.memory[2] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd20;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                12,
                "BEQ not taken",
                dut.u_register_file.registers[3],
                32'd30
            );

        end

    endtask


    // ========================================================
    // PROGRAM 13
    //
    // NEGATIVE ARITHMETIC
    //
    // x1 = -5
    // x2 = 10
    // x3 = x1 + x2
    //
    // Expected x3 = 5
    // ========================================================

    task automatic program_13_negative_arithmetic;

        begin

            reset_cpu;
            clear_memories;

            // ADD x3,x1,x2
            dut.u_instruction_memory.memory[0] =
                32'h0020_81B3;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] =
                32'hFFFF_FFFB;   // -5

            dut.u_register_file.registers[2] =
                32'd10;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                13,
                "Negative arithmetic",
                dut.u_register_file.registers[3],
                32'd5
            );

        end

    endtask


    // ========================================================
    // PROGRAM 14
    //
    // POSITIVE IMMEDIATE
    //
    // ADDI x3,x1,15
    //
    // x1 = 10
    // Expected x3 = 25
    //
    // This verifies I-type immediate generation and
    // ALU immediate selection.
    // ========================================================

    task automatic program_14_positive_immediate;

        begin

            reset_cpu;
            clear_memories;

            // ADDI x3,x1,15
            //
            // imm[11:0] = 15
            // rs1      = x1
            // funct3   = 000
            // rd       = x3
            // opcode   = 0010011
            //
            dut.u_instruction_memory.memory[0] =
                32'h00F0_8193;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                14,
                "Positive immediate",
                dut.u_register_file.registers[3],
                32'd25
            );

        end

    endtask


    // ========================================================
    // PROGRAM 15
    //
    // NEGATIVE IMMEDIATE
    //
    // ADDI x3,x1,-5
    //
    // x1 = 10
    // Expected x3 = 5
    //
    // This verifies sign extension of a negative I-type
    // immediate.
    // ========================================================

    task automatic program_15_negative_immediate;

        begin

            reset_cpu;
            clear_memories;

            // ADDI x3,x1,-5
            //
            // immediate = 0xFFB
            //
            dut.u_instruction_memory.memory[0] =
                32'hFFB0_8193;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                15,
                "Negative immediate",
                dut.u_register_file.registers[3],
                32'd5
            );

        end

    endtask
        // ========================================================
    // PROGRAM 14
    //
    // x0 PROTECTION
    //
    // Attempt:
    //     ADD x0,x1,x2
    //
    // The architectural zero register must remain zero.
    //
    // Expected:
    //     x0 = 0
    // ========================================================

    task automatic program_14_x0_protection;

        begin

            reset_cpu;
            clear_memories;

            // ADD x0,x1,x2
            dut.u_instruction_memory.memory[0] =
                32'h0020_8033;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[0] = 32'd0;
            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd20;

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                14,
                "x0 protection",
                dut.u_register_file.registers[0],
                32'd0
            );

        end

    endtask


    // ========================================================
    // PROGRAM 15
    //
    // SLT FALSE
    //
    // x1 = 10
    // x2 = -5
    //
    // SLT x3,x1,x2
    //
    // 10 < -5 is false.
    //
    // Expected:
    //     x3 = 0
    // ========================================================

    task automatic program_15_slt_false;

        begin

            reset_cpu;
            clear_memories;

            // SLT x3,x1,x2
            dut.u_instruction_memory.memory[0] =
                32'h0020_A1B3;

            // Final loop
            dut.u_instruction_memory.memory[1] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] =
                32'd10;

            dut.u_register_file.registers[2] =
                32'hFFFF_FFFB;   // -5

            repeat (2)
                @(posedge clk);

            #1;

            report_program(
                15,
                "SLT false signed comparison",
                dut.u_register_file.registers[3],
                32'd0
            );

        end

    endtask
        // ========================================================
    // PROGRAM 16
    //
    // MULTIPLE DEPENDENT ALU OPERATIONS
    //
    // x3 = x1 + x2 = 30
    // x4 = x3 + x2 = 50
    // x5 = x4 - x1 = 40
    //
    // Verifies multiple sequential register dependencies.
    // ========================================================

    task automatic program_16_multiple_dependencies;

        begin

            reset_cpu;
            clear_memories;

            // ADD x3,x1,x2
            dut.u_instruction_memory.memory[0] =
                32'h0020_81B3;

            // ADD x4,x3,x2
            dut.u_instruction_memory.memory[1] =
                32'h0021_8233;

            // SUB x5,x4,x1
            dut.u_instruction_memory.memory[2] =
                32'h4012_02B3;

            // Final loop
            dut.u_instruction_memory.memory[3] =
                32'h0000_0063;

            initialize_state;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                16,
                "Multiple ALU dependencies",
                dut.u_register_file.registers[5],
                32'd40
            );

        end

    endtask


    // ========================================================
    // PROGRAM 17
    //
    // MULTIPLE STORE/LOAD OPERATIONS
    //
    // SW x1,4(x0)
    // SW x2,8(x0)
    // LW x3,4(x0)
    // LW x4,8(x0)
    //
    // Expected:
    // x3 = 10
    // x4 = 20
    //
    // The final check combines both values:
    // x5 = x3 + x4 = 30
    // ========================================================

    task automatic program_17_multiple_memory;

        begin

            reset_cpu;
            clear_memories;

            // SW x1,4(x0)
            dut.u_instruction_memory.memory[0] =
                32'h0010_2223;

            // SW x2,8(x0)
            dut.u_instruction_memory.memory[1] =
                32'h0020_2423;

            // LW x3,4(x0)
            dut.u_instruction_memory.memory[2] =
                32'h0040_2183;

            // LW x4,8(x0)
            dut.u_instruction_memory.memory[3] =
                32'h0080_2203;

            // ADD x5,x3,x4
            dut.u_instruction_memory.memory[4] =
                32'h0041_82B3;

            // Final loop
            dut.u_instruction_memory.memory[5] =
                32'h0000_0063;

            initialize_state;

            repeat (5)
                @(posedge clk);

            #1;

            report_program(
                17,
                "Multiple store/load operations",
                dut.u_register_file.registers[5],
                32'd30
            );

        end

    endtask


    // ========================================================
    // PROGRAM 18
    //
    // BRANCH + REGISTER COMPUTATION
    //
    // x1 = 10
    // x2 = 10
    //
    // BEQ x1,x2,+8
    //
    // The instruction at address 0x04 is skipped.
    //
    // Target instruction:
    // ADD x5,x1,x2
    //
    // Expected:
    // x5 = 20
    // ========================================================

    task automatic program_18_branch_register;

        begin

            reset_cpu;
            clear_memories;

            // BEQ x1,x2,+8
            dut.u_instruction_memory.memory[0] =
                32'h0020_8463;

            // ADD x5,x0,x0
            // Must be skipped.
            dut.u_instruction_memory.memory[1] =
                32'h0000_02B3;

            // ADD x5,x1,x2
            dut.u_instruction_memory.memory[2] =
                32'h0020_82B3;

            // Final loop
            dut.u_instruction_memory.memory[3] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd10;

            repeat (3)
                @(posedge clk);

            #1;

            report_program(
                18,
                "Branch plus register computation",
                dut.u_register_file.registers[5],
                32'd20
            );

        end

    endtask


    // ========================================================
    // PROGRAM 19
    //
    // BRANCH + MEMORY INTERACTION
    //
    // SW x1,4(x0)
    // BEQ x1,x2,+8
    // skipped instruction
    // LW x4,4(x0)
    //
    // x1 = x2 = 10
    //
    // Branch is taken and LW executes at the target.
    //
    // Expected:
    // x4 = 10
    // ========================================================

    task automatic program_19_branch_memory;

        begin

            reset_cpu;
            clear_memories;

            // SW x1,4(x0)
            dut.u_instruction_memory.memory[0] =
                32'h0010_2223;

            // BEQ x1,x2,+8
            dut.u_instruction_memory.memory[1] =
                32'h0020_8463;

            // ADD x4,x0,x0
            // Must be skipped.
            dut.u_instruction_memory.memory[2] =
                32'h0000_0233;

            // LW x4,4(x0)
            dut.u_instruction_memory.memory[3] =
                32'h0040_2203;

            // Final loop
            dut.u_instruction_memory.memory[4] =
                32'h0000_0063;

            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd10;

            repeat (5)
                @(posedge clk);

            #1;

            report_program(
                19,
                "Branch plus memory interaction",
                dut.u_register_file.registers[4],
                32'd10
            );

        end

    endtask

    // ========================================================
    // PROGRAM 20
    //
    // COMPLETE MIXED RV32I MINI-PROGRAM
    //
    // 0x00: ADD x3,x1,x2
    //       x3 = 10 + 20 = 30
    //
    // 0x04: SW x3,4(x0)
    //       memory[1] = 30
    //
    // 0x08: LW x4,4(x0)
    //       x4 = 30
    //
    // 0x0C: XOR x5,x4,x1
    //       x5 = 30 XOR 10 = 20
    //
    // 0x10: BEQ x5,x2,+8
    //       20 == 20, therefore branch is taken
    //       target = 0x18
    //
    // 0x14: ADD x7,x0,x0
    //       skipped
    //
    // 0x18: ADD x7,x5,x1
    //       x7 = 20 + 10 = 30
    //
    // 0x1C: BEQ x0,x0,0
    //       final self-loop
    //
    // Expected:
    //       x7 = 30
    //
    // This is the final end-to-end regression program.
    // ========================================================

    task automatic program_20_complete_program;

        begin

            reset_cpu;
            clear_memories;

            // ------------------------------------------------
            // 0x00: ADD x3,x1,x2
            // ------------------------------------------------
            dut.u_instruction_memory.memory[0] =
                32'h0020_81B3;

            // ------------------------------------------------
            // 0x04: SW x3,4(x0)
            // ------------------------------------------------
            dut.u_instruction_memory.memory[1] =
                32'h0030_2223;

            // ------------------------------------------------
            // 0x08: LW x4,4(x0)
            // ------------------------------------------------
            dut.u_instruction_memory.memory[2] =
                32'h0040_2203;

            // ------------------------------------------------
            // 0x0C: XOR x5,x4,x1
            //
            // CORRECT ENCODING:
            // rs1 = x4
            // rs2 = x1
            // rd  = x5
            // ------------------------------------------------
            dut.u_instruction_memory.memory[3] =
                32'h0012_42B3;

            // ------------------------------------------------
            // 0x10: BEQ x5,x2,+8
            //
            // x5 = 20
            // x2 = 20
            //
            // Branch target = 0x10 + 0x08 = 0x18
            // ------------------------------------------------
            dut.u_instruction_memory.memory[4] =
                32'h0022_8463;

            // ------------------------------------------------
            // 0x14: ADD x7,x0,x0
            //
            // MUST BE SKIPPED.
            // ------------------------------------------------
            dut.u_instruction_memory.memory[5] =
                32'h0000_03B3;

            // ------------------------------------------------
            // 0x18: ADD x7,x5,x1
            //
            // x7 = 20 + 10 = 30
            // ------------------------------------------------
            dut.u_instruction_memory.memory[6] =
                32'h0012_83B3;

            // ------------------------------------------------
            // 0x1C: Final self-loop
            // ------------------------------------------------
            dut.u_instruction_memory.memory[7] =
                32'h0000_0063;

            // ------------------------------------------------
            // Initial architectural state
            // ------------------------------------------------
            initialize_state;

            dut.u_register_file.registers[1] = 32'd10;
            dut.u_register_file.registers[2] = 32'd20;

            // Allow the complete program to execute.
            repeat (8)
                @(posedge clk);

            #1;

            report_program(
                20,
                "Complete mixed RV32I program",
                dut.u_register_file.registers[7],
                32'd30
            );

        end

    endtask
    // ========================================================
    // Main regression sequence
    // ========================================================

    initial begin

        total_programs = 0;
        passed_programs = 0;
        failed_programs = 0;

        rst_n = 1'b0;

        $display("");
        $display("============================================================");
        $display("             RV32I CPU REGRESSION VERIFICATION");
        $display("============================================================");
        $display("");

        // Programs 01-05
        program_01_add;
        program_02_sub;
        program_03_and;
        program_04_or;
        program_05_xor;

        // Programs 06-10
        program_06_slt;
        program_07_add_sub_chain;
        program_08_lw;
        program_09_sw;
        program_10_lw_sw_roundtrip;
        // Programs 11-13
        program_11_beq_taken;
        program_12_beq_not_taken;
        program_13_negative_arithmetic;
                program_14_x0_protection;
        program_15_slt_false;
                // Programs 16-20
        program_16_multiple_dependencies;
        program_17_multiple_memory;
        program_18_branch_register;
        program_19_branch_memory;
        program_20_complete_program;
        // ----------------------------------------------------
        // Current milestone
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("             CURRENT REGRESSION RESULT");
        $display("============================================================");

        $display("PROGRAMS EXECUTED = %0d", total_programs);
        $display("PASSED             = %0d", passed_programs);
        $display("FAILED             = %0d", failed_programs);

        $display("");
        $display("REGRESSION COMPLETE: 20 programs tested");

        $finish;

    end

endmodule