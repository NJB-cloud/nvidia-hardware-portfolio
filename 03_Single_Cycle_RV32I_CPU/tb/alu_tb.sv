// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: RV32I ALU
// ============================================================

`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_control;

    logic [31:0] result;
    logic        zero;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    alu dut (
        .a           (a),
        .b           (b),
        .alu_control (alu_control),
        .result      (result),
        .zero        (zero)
    );

    // --------------------------------------------------------
    // ALU operation codes
    // --------------------------------------------------------

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;

    // --------------------------------------------------------
    // Test task
    // --------------------------------------------------------

    task automatic check_alu(
        input logic [31:0] a_in,
        input logic [31:0] b_in,
        input logic [3:0]  control_in,
        input logic [31:0] expected_result,
        input logic        expected_zero,
        input string       message
    );

        begin

            a = a_in;
            b = b_in;
            alu_control = control_in;

            #1;

            if ((result === expected_result) &&
                (zero === expected_zero)) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %-32s | A=%08h B=%08h RESULT=%08h ZERO=%0b",
                    message,
                    a,
                    b,
                    result,
                    zero
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %-32s | A=%08h B=%08h EXPECTED=%08h/%0b GOT=%08h/%0b",
                    message,
                    a,
                    b,
                    expected_result,
                    expected_zero,
                    result,
                    zero
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

        a = 32'h0000_0000;
        b = 32'h0000_0000;
        alu_control = ALU_ADD;

        $display("");
        $display("============================================================");
        $display("                  RV32I ALU VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // ADD TESTS
        // ----------------------------------------------------

        check_alu(
            32'd10,
            32'd5,
            ALU_ADD,
            32'd15,
            1'b0,
            "ADD 10 + 5"
        );

        check_alu(
            32'd0,
            32'd0,
            ALU_ADD,
            32'd0,
            1'b1,
            "ADD 0 + 0"
        );

        check_alu(
            32'h1234_5678,
            32'h1111_1111,
            ALU_ADD,
            32'h2345_6789,
            1'b0,
            "ADD hexadecimal values"
        );

        // ----------------------------------------------------
        // SUB TESTS
        // ----------------------------------------------------

        check_alu(
            32'd10,
            32'd5,
            ALU_SUB,
            32'd5,
            1'b0,
            "SUB 10 - 5"
        );

        check_alu(
            32'd25,
            32'd25,
            ALU_SUB,
            32'd0,
            1'b1,
            "SUB 25 - 25"
        );

        check_alu(
            32'd5,
            32'd10,
            ALU_SUB,
            32'hFFFF_FFFB,
            1'b0,
            "SUB 5 - 10 = -5"
        );

        // ----------------------------------------------------
        // AND TEST
        //
        // FFFF00FF & 0F0F0F0F = 0F0F000F
        // ----------------------------------------------------

        check_alu(
            32'hFFFF_00FF,
            32'h0F0F_0F0F,
            ALU_AND,
            32'h0F0F_000F,
            1'b0,
            "AND operation"
        );

        // ----------------------------------------------------
        // OR TEST
        // ----------------------------------------------------

        check_alu(
            32'hFFFF_0000,
            32'h0000_00FF,
            ALU_OR,
            32'hFFFF_00FF,
            1'b0,
            "OR operation"
        );

        // ----------------------------------------------------
        // XOR TEST
        // ----------------------------------------------------

        check_alu(
            32'hFFFF_00FF,
            32'h0F0F_0F0F,
            ALU_XOR,
            32'hF0F0_0FF0,
            1'b0,
            "XOR operation"
        );

        // ----------------------------------------------------
        // SLT SIGNED TESTS
        // ----------------------------------------------------

        check_alu(
            32'hFFFF_FFFB,
            32'd10,
            ALU_SLT,
            32'd1,
            1'b0,
            "SLT signed -5 < 10"
        );

        check_alu(
            32'd10,
            32'hFFFF_FFFB,
            ALU_SLT,
            32'd0,
            1'b1,
            "SLT signed 10 < -5"
        );

        check_alu(
            32'd20,
            32'd20,
            ALU_SLT,
            32'd0,
            1'b1,
            "SLT equal values"
        );

        // ----------------------------------------------------
        // ZERO RESULT TESTS
        // ----------------------------------------------------

        check_alu(
            32'hFFFF_0000,
            32'h0000_FFFF,
            ALU_AND,
            32'h0000_0000,
            1'b1,
            "AND zero result"
        );

        check_alu(
            32'hA5A5_A5A5,
            32'hA5A5_A5A5,
            ALU_XOR,
            32'h0000_0000,
            1'b1,
            "XOR zero result"
        );

        // ----------------------------------------------------
        // FINAL RESULT
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("                     ALU TEST RESULT");
        $display("============================================================");

        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("              ALL ALU TESTS PASSED");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("                 ALU TESTS FAILED");
            $display("============================================================");

        end

        $finish;

    end

endmodule