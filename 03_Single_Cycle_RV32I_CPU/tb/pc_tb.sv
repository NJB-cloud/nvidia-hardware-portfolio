// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: Program Counter
// ============================================================

`timescale 1ns/1ps

module pc_tb;

    logic        clk;
    logic        rst_n;
    logic [31:0] next_pc;
    logic [31:0] current_pc;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    pc #(
        .RESET_PC(32'h0000_0000)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Waveform
    // --------------------------------------------------------

    initial begin
        $dumpfile("pc_wave.vcd");
        $dumpvars(0, pc_tb);
    end

    // --------------------------------------------------------
    // Check task
    // --------------------------------------------------------

    task automatic check_pc(
        input logic [31:0] expected,
        input string       message
    );

        begin

            if (current_pc === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %s | PC = 0x%08h",
                    message,
                    current_pc
                );

            end

            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %s | Expected = 0x%08h, Got = 0x%08h",
                    message,
                    expected,
                    current_pc
                );

            end

        end

    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n   = 1'b0;
        next_pc = 32'h0000_0000;

        $display("");
        $display("==============================================");
        $display("       RV32I PROGRAM COUNTER TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        check_pc(
            32'h0000_0000,
            "PC resets to address 0"
        );

        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        rst_n = 1'b1;

        // ----------------------------------------------------
        // Sequential PC update
        // ----------------------------------------------------

        next_pc = 32'h0000_0004;

        @(posedge clk);
        #1;

        check_pc(
            32'h0000_0004,
            "PC updates to 0x00000004"
        );

        next_pc = 32'h0000_0008;

        @(posedge clk);
        #1;

        check_pc(
            32'h0000_0008,
            "PC updates to 0x00000008"
        );

        // ----------------------------------------------------
        // Larger address
        // ----------------------------------------------------

        next_pc = 32'h0000_0100;

        @(posedge clk);
        #1;

        check_pc(
            32'h0000_0100,
            "PC updates to 0x00000100"
        );

        // ----------------------------------------------------
        // Branch-style target
        // ----------------------------------------------------

        next_pc = 32'h0000_0200;

        @(posedge clk);
        #1;

        check_pc(
            32'h0000_0200,
            "PC accepts branch-style target address"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("             PC TEST RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display("          ALL PC TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("          PC TESTS FAILED");
            $display("==============================================");

        end

        $finish;

    end

endmodule