// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Extended Integration Verification
//
// Tests:
//   ADD
//   SUB
//   XOR
//   LW
//   SW
//   BEQ taken
//   BEQ not taken
//   x0 protection
//   Register write-back
//   Sequential execution
// ============================================================

`timescale 1ns/1ps

module rv32i_cpu_extended_tb;

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
        $dumpfile("rv32i_cpu_extended_wave.vcd");
        $dumpvars(0, rv32i_cpu_extended_tb);
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
                    "PASS: %-42s | Expected=%08h Got=%08h",
                    test_name,
                    expected,
                    actual
                );

            end

            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %-42s | Expected=%08h Got=%08h",
                    test_name,
                    expected,
                    actual
                );

            end

        end

    endtask

    // ========================================================
    // Program
    //
    // Address    Instruction
    //
    // 0x00       ADD x3, x1, x2
    // 0x04       SUB x4, x3, x1
    // 0x08       SW  x4, 4(x0)
    // 0x0C       LW  x5, 4(x0)
    // 0x10       BEQ x5, x4, +8
    // 0x14       XOR x6, x5, x5       [SKIPPED]
    // 0x18       ADD x7, x5, x1
    // 0x1C       BEQ x5, x3, +8       [NOT TAKEN]
    // 0x20       ADD x8, x7, x1
    // 0x24       ADD x0, x8, x1       [x0 MUST NOT CHANGE]
    // 0x28       BEQ x0, x0, 0        [FINAL LOOP]
    //
    // Initial:
    //   x1 = 10
    //   x2 = 20
    //   x6 = 123
    //
    // Expected:
    //   x3 = 30
    //   x4 = 20
    //   memory[1] = 20
    //   x5 = 20
    //   x6 = 123
    //   x7 = 30
    //   x8 = 40
    //   x0 = 0
    //   PC = 0x28
    // ========================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n = 1'b0;

        // ----------------------------------------------------
        // Instruction memory initialization
        // ----------------------------------------------------

        // ADD x3, x1, x2
        dut.u_instruction_memory.memory[0] =
            32'h0020_81B3;

        // SUB x4, x3, x1
        dut.u_instruction_memory.memory[1] =
            32'h4011_8233;

        // SW x4, 4(x0)
        dut.u_instruction_memory.memory[2] =
            32'h0040_2223;

        // LW x5, 4(x0)
        dut.u_instruction_memory.memory[3] =
            32'h0040_2283;

        // BEQ x5, x4, +8
        // Taken: jumps from 0x10 to 0x18
        dut.u_instruction_memory.memory[4] =
            32'h0042_8463;

        // XOR x6, x5, x5
        // Must be skipped
        dut.u_instruction_memory.memory[5] =
            32'h0052_C333;

        // ADD x7, x5, x1
        dut.u_instruction_memory.memory[6] =
            32'h0012_83B3;

        // BEQ x5, x3, +8
        // x5 = 20, x3 = 30
        // Therefore NOT taken
        dut.u_instruction_memory.memory[7] =
            32'h0032_8463;

        // ADD x8, x7, x1
        dut.u_instruction_memory.memory[8] =
            32'h0013_8433;

        // ADD x0, x8, x1
        // Register file must reject write to x0
        dut.u_instruction_memory.memory[9] =
            32'h0014_0033;

        // BEQ x0, x0, 0
        // Final loop
        dut.u_instruction_memory.memory[10] =
            32'h0000_0063;

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        rst_n = 1'b1;

        // ----------------------------------------------------
        // Initial register values
        // ----------------------------------------------------

        dut.u_register_file.registers[1] = 32'd10;
        dut.u_register_file.registers[2] = 32'd20;

        // Sentinel value.
        // XOR would change this to zero if the branch failed.
        dut.u_register_file.registers[6] = 32'd123;

        // Explicitly verify x0 starts at zero.
        dut.u_register_file.registers[0] = 32'd0;

        // ----------------------------------------------------
        // Execute the program
        //
        // 11 instructions / cycles
        // ----------------------------------------------------

        repeat (11)
            @(posedge clk);

        #1;

        $display("");
        $display("============================================================");
        $display("          EXTENDED RV32I CPU VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Test 1: ADD
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[3],
            32'd30,
            "ADD x3, x1, x2"
        );

        // ----------------------------------------------------
        // Test 2: SUB
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[4],
            32'd20,
            "SUB x4, x3, x1"
        );

        // ----------------------------------------------------
        // Test 3: STORE
        // ----------------------------------------------------

        check_value(
            dut.data_memory[1],
            32'd20,
            "SW x4, 4(x0)"
        );

        // ----------------------------------------------------
        // Test 4: LOAD
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[5],
            32'd20,
            "LW x5, 4(x0)"
        );

        // ----------------------------------------------------
        // Test 5: Taken branch
        //
        // XOR at 0x14 must be skipped.
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[6],
            32'd123,
            "BEQ taken: XOR instruction skipped"
        );

        // ----------------------------------------------------
        // Test 6: Instruction after taken branch
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[7],
            32'd30,
            "ADD x7 executes after taken branch"
        );

        // ----------------------------------------------------
        // Test 7: Not-taken branch
        //
        // x5 != x3, so execution continues to 0x20.
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[8],
            32'd40,
            "BEQ not taken: ADD x8 executes"
        );

        // ----------------------------------------------------
        // Test 8: x0 protection
        //
        // ADD x0, x8, x1 attempts to write 50 into x0.
        // x0 must remain zero.
        // ----------------------------------------------------

        check_value(
            dut.u_register_file.registers[0],
            32'd0,
            "x0 remains permanently zero"
        );

        // ----------------------------------------------------
        // Test 9: Final PC
        // ----------------------------------------------------

        check_value(
            current_pc,
            32'h0000_0028,
            "PC reaches final branch loop"
        );

        // ----------------------------------------------------
        // Final report
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("        EXTENDED RV32I CPU TEST RESULT");
        $display("============================================================");

        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("       ALL EXTENDED RV32I CPU TESTS PASSED");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("       EXTENDED RV32I CPU TESTS FAILED");
            $display("============================================================");

        end

        $finish;

    end

endmodule