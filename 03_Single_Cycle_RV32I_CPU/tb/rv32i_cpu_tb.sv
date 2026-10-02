// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: Integrated RV32I CPU
//
// Supported verification:
//   R-type: ADD, SUB
//   SW
//   LW
//   BEQ
//
// Program:
//
//   0x00: ADD x3, x1, x2
//   0x04: SUB x4, x3, x1
//   0x08: SW  x4, 0(x0)
//   0x0C: LW  x5, 0(x0)
//   0x10: BEQ x5, x4, +8
//   0x14: XOR x6, x5, x5       <- must be skipped
//   0x18: ADD x7, x5, x1
//   0x1C: BEQ x0, x0, 0        <- final loop
//
// Initial register values:
//   x1 = 10
//   x2 = 20
//   x6 = 123
//
// Expected:
//   x3 = 30
//   x4 = 20
//   memory[0] = 20
//   x5 = 20
//   x6 = 123   (XOR instruction skipped)
//   x7 = 30
//   PC = 0x1C
// ============================================================

`timescale 1ns/1ps

module rv32i_cpu_tb;

    logic clk;
    logic rst_n;

    logic [31:0] current_pc;
    logic [31:0] instruction;
    logic [31:0] alu_result;
    logic [31:0] writeback_data;

    integer pass_count;
    integer fail_count;

    // ========================================================
    // DUT
    // ========================================================

    rv32i_cpu #(
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .current_pc    (current_pc),
        .instruction   (instruction),
        .alu_result    (alu_result),
        .writeback_data(writeback_data)
    );

    // ========================================================
    // Clock
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Waveform generation
    // ========================================================

    initial begin
        $dumpfile("rv32i_cpu_wave.vcd");
        $dumpvars(0, rv32i_cpu_tb);
    end

    // ========================================================
    // Verification task
    // ========================================================

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string       test_name
    );

        begin

            if (actual === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %-35s | Expected=%08h Got=%08h",
                    test_name,
                    expected,
                    actual
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %-35s | Expected=%08h Got=%08h",
                    test_name,
                    expected,
                    actual
                );

            end

        end

    endtask

    // ========================================================
    // Test program
    // ========================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n = 1'b0;

        // ====================================================
        // Initialize instruction memory
        // ====================================================

        // 0x00:
        // ADD x3, x1, x2
        // x3 = 10 + 20 = 30
        dut.u_instruction_memory.memory[0] =
            32'h0020_81B3;

        // 0x04:
        // SUB x4, x3, x1
        // x4 = 30 - 10 = 20
        dut.u_instruction_memory.memory[1] =
            32'h4011_8233;

        // 0x08:
        // SW x4, 0(x0)
        // memory[0] = 20
        dut.u_instruction_memory.memory[2] =
            32'h0040_2023;

        // 0x0C:
        // LW x5, 0(x0)
        // x5 = memory[0] = 20
        dut.u_instruction_memory.memory[3] =
            32'h0000_2283;

        // 0x10:
        // BEQ x5, x4, +8
        //
        // x5 == x4
        // Therefore branch to 0x18.
        dut.u_instruction_memory.memory[4] =
            32'h0052_0463;

        // 0x14:
        // XOR x6, x5, x5
        //
        // This instruction MUST be skipped.
        // x6 therefore remains 123.
        dut.u_instruction_memory.memory[5] =
            32'h0052_C333;

        // 0x18:
        // ADD x7, x5, x1
        //
        // x7 = 20 + 10 = 30
        //
        // IMPORTANT:
        // Correct encoding has rd = x7.
        dut.u_instruction_memory.memory[6] =
            32'h0012_83B3;

        // 0x1C:
        // BEQ x0, x0, 0
        //
        // Infinite loop / final stop point.
        dut.u_instruction_memory.memory[7] =
            32'h0000_0063;

        // ====================================================
        // Reset
        // ====================================================

        repeat (2)
            @(posedge clk);

        #1;

        // ====================================================
        // Release reset
        // ====================================================

        rst_n = 1'b1;

        // ====================================================
        // Initialize registers after reset
        // ====================================================

        dut.u_register_file.registers[1] = 32'd10;
        dut.u_register_file.registers[2] = 32'd20;

        // Sentinel value.
        //
        // If the XOR instruction at 0x14 executes:
        //
        // x6 = x5 XOR x5 = 0
        //
        // If BEQ works correctly, the XOR is skipped and
        // x6 remains 123.
        dut.u_register_file.registers[6] = 32'd123;

        // ====================================================
        // Execute program
        // ====================================================

        repeat (8)
            @(posedge clk);

        #1;

        $display("");
        $display("============================================================");
        $display("              RV32I CPU INTEGRATION TEST");
        $display("============================================================");

        // ====================================================
        // Test 1: ADD
        // ====================================================

        check_value(
            dut.u_register_file.registers[3],
            32'd30,
            "ADD x3, x1, x2"
        );

        // ====================================================
        // Test 2: SUB
        // ====================================================

        check_value(
            dut.u_register_file.registers[4],
            32'd20,
            "SUB x4, x3, x1"
        );

        // ====================================================
        // Test 3: STORE
        // ====================================================

        check_value(
            dut.data_memory[0],
            32'd20,
            "SW x4, 0(x0)"
        );

        // ====================================================
        // Test 4: LOAD
        // ====================================================

        check_value(
            dut.u_register_file.registers[5],
            32'd20,
            "LW x5, 0(x0)"
        );

        // ====================================================
        // Test 5: BRANCH
        //
        // x5 == x4.
        //
        // Therefore BEQ must skip the XOR instruction.
        // ====================================================

        check_value(
            dut.u_register_file.registers[6],
            32'd123,
            "BEQ skips XOR x6, x5, x5"
        );

        // ====================================================
        // Test 6: Instruction after branch
        // ====================================================

        check_value(
            dut.u_register_file.registers[7],
            32'd30,
            "ADD x7, x5, x1 after branch"
        );

        // ====================================================
        // Test 7: Final PC
        // ====================================================

        check_value(
            current_pc,
            32'h0000_001C,
            "PC reaches final branch loop"
        );

        // ====================================================
        // Final result
        // ====================================================

        $display("");
        $display("============================================================");
        $display("             RV32I CPU TEST RESULT");
        $display("============================================================");

        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("          ALL RV32I CPU TESTS PASSED");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("          RV32I CPU TESTS FAILED");
            $display("============================================================");

        end

        $finish;

    end

endmodule