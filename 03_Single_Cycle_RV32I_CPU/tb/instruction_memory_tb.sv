// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: Instruction Memory
// ============================================================

`timescale 1ns/1ps

module instruction_memory_tb;

    logic [31:0] address;
    logic [31:0] instruction;

    integer pass_count;
    integer fail_count;

    instruction_memory #(
        .DEPTH(16)
    ) dut (
        .address(address),
        .instruction(instruction)
    );

    task automatic check_instruction(
        input logic [31:0] expected,
        input string       message
    );

        begin

            if (instruction === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %s | Instruction = 0x%08h",
                    message,
                    instruction
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %s | Expected = 0x%08h, Got = 0x%08h",
                    message,
                    expected,
                    instruction
                );

            end

        end

    endtask

    initial begin

        pass_count = 0;
        fail_count = 0;

        // ----------------------------------------------------
        // Initialize instruction memory
        // ----------------------------------------------------

        // ADD x3, x1, x2
        dut.memory[0] = 32'h0020_81B3;

        // SUB x4, x3, x1
        dut.memory[1] = 32'h4011_8233;

        // AND x5, x3, x4
        dut.memory[2] = 32'h0041_F2B3;

        // OR x6, x3, x4
        dut.memory[3] = 32'h0041_E333;

        // XOR x7, x3, x4
        dut.memory[4] = 32'h0041_C3B3;

        // ----------------------------------------------------
        // Test instruction fetch
        // ----------------------------------------------------

        address = 32'h0000_0000;
        #1;

        check_instruction(
            32'h0020_81B3,
            "Fetch instruction at address 0"
        );

        address = 32'h0000_0004;
        #1;

        check_instruction(
            32'h4011_8233,
            "Fetch instruction at address 4"
        );

        address = 32'h0000_0008;
        #1;

        check_instruction(
            32'h0041_F2B3,
            "Fetch instruction at address 8"
        );

        address = 32'h0000_000C;
        #1;

        check_instruction(
            32'h0041_E333,
            "Fetch instruction at address 12"
        );

        address = 32'h0000_0010;
        #1;

        check_instruction(
            32'h0041_C3B3,
            "Fetch instruction at address 16"
        );

        // ----------------------------------------------------
        // Test word alignment
        // ----------------------------------------------------

        address = 32'h0000_0001;
        #1;

        check_instruction(
            32'h0020_81B3,
            "Word-aligned fetch uses address[31:2]"
        );

        // ----------------------------------------------------
        // Test out-of-range protection
        // ----------------------------------------------------

        address = 32'h0000_0100;
        #1;

        check_instruction(
            32'h0000_0013,
            "Out-of-range address returns NOP"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       INSTRUCTION MEMORY TEST RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display("   ALL INSTRUCTION MEMORY TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("   INSTRUCTION MEMORY TESTS FAILED");
            $display("==============================================");

        end

        $finish;

    end

endmodule