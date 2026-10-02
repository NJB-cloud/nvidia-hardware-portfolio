// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: Immediate Generator
// ============================================================

`timescale 1ns/1ps

module immediate_generator_tb;

    logic [31:0] instruction;
    logic [31:0] immediate;

    integer pass_count;
    integer fail_count;

    immediate_generator dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    task automatic check_immediate(
        input logic [31:0] expected,
        input string message
    );
        begin
            if (immediate === expected) begin
                pass_count = pass_count + 1;

                $display(
                    "PASS: %s | Immediate = 0x%08h",
                    message,
                    immediate
                );
            end
            else begin
                fail_count = fail_count + 1;

                $display(
                    "FAIL: %s | Expected = 0x%08h, Got = 0x%08h",
                    message,
                    expected,
                    immediate
                );
            end
        end
    endtask

    initial begin

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("==============================================");
        $display("      RV32I IMMEDIATE GENERATOR TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Test 1: I-Type
        // LW x5, 16(x1)
        // Immediate = +16
        // ----------------------------------------------------

        instruction = 32'h0100_A283;
        #1;

        check_immediate(
            32'h0000_0010,
            "I-type immediate +16"
        );

        // ----------------------------------------------------
        // Test 2: I-Type negative immediate
        // Immediate = -16
        // ----------------------------------------------------

        instruction = 32'hFF00_A283;
        #1;

        check_immediate(
            32'hFFFF_FFF0,
            "I-type sign extension -16"
        );

        // ----------------------------------------------------
        // Test 3: S-Type
        // SW x5, 20(x1)
        // Immediate = +20
        // ----------------------------------------------------

        instruction = 32'h0050_AA23;
        #1;

        check_immediate(
            32'h0000_0014,
            "S-type immediate +20"
        );

        // ----------------------------------------------------
        // Test 4: B-Type
        //
        // BEQ-style branch encoding
        // Immediate = +8 bytes
        // ----------------------------------------------------

        instruction = 32'h0020_8463;
        #1;

        check_immediate(
            32'h0000_0008,
            "B-type branch immediate +8"
        );

        // ----------------------------------------------------
        // Test 5: Unsupported opcode
        // Immediate should be zero
        // ----------------------------------------------------

        instruction = 32'hFFFF_FFFF;
        #1;

        check_immediate(
            32'h0000_0000,
            "Unsupported opcode produces zero immediate"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("    IMMEDIATE GENERATOR TEST RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display(" ALL IMMEDIATE GENERATOR TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display(" IMMEDIATE GENERATOR TESTS FAILED");
            $display("==============================================");

        end

        $finish;

    end

endmodule