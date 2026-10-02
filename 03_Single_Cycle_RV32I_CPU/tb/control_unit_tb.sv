// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: Main Control Unit
// ============================================================

`timescale 1ns/1ps

module control_unit_tb;

    logic [6:0] opcode;

    logic       RegWrite;
    logic       ALUSrc;
    logic       MemRead;
    logic       MemWrite;
    logic       MemToReg;
    logic       Branch;
    logic [1:0] ALUOp;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // RV32I opcodes
    // --------------------------------------------------------

    localparam logic [6:0] OPCODE_R_TYPE = 7'b0110011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    control_unit dut (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemToReg (MemToReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // --------------------------------------------------------
    // Verification task
    // --------------------------------------------------------

    task automatic check_control(
        input logic       expected_RegWrite,
        input logic       expected_ALUSrc,
        input logic       expected_MemRead,
        input logic       expected_MemWrite,
        input logic       expected_MemToReg,
        input logic       expected_Branch,
        input logic [1:0] expected_ALUOp,
        input string      test_name
    );

        begin

            #1;

            if ((RegWrite === expected_RegWrite) &&
                (ALUSrc   === expected_ALUSrc)   &&
                (MemRead  === expected_MemRead)  &&
                (MemWrite === expected_MemWrite) &&
                (MemToReg === expected_MemToReg) &&
                (Branch   === expected_Branch)   &&
                (ALUOp    === expected_ALUOp)) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %-25s | RW=%b AS=%b MR=%b MW=%b MTR=%b BR=%b ALUOp=%b",
                    test_name,
                    RegWrite,
                    ALUSrc,
                    MemRead,
                    MemWrite,
                    MemToReg,
                    Branch,
                    ALUOp
                );

            end

            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %-25s | EXPECTED=%b%b%b%b%b%b%b%b GOT=%b%b%b%b%b%b%b%b",
                    test_name,
                    expected_RegWrite,
                    expected_ALUSrc,
                    expected_MemRead,
                    expected_MemWrite,
                    expected_MemToReg,
                    expected_Branch,
                    expected_ALUOp,
                    1'b0,
                    RegWrite,
                    ALUSrc,
                    MemRead,
                    MemWrite,
                    MemToReg,
                    Branch,
                    ALUOp,
                    1'b0
                );

            end

        end

    endtask

    // --------------------------------------------------------
    // Tests
    // --------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("============================================================");
        $display("             RV32I CONTROL UNIT VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // R-Type
        //
        // ADD / SUB / AND / OR / XOR
        //
        // Expected:
        // RegWrite = 1
        // ALUSrc   = 0
        // MemRead  = 0
        // MemWrite = 0
        // MemToReg = 0
        // Branch   = 0
        // ALUOp    = 10
        // ----------------------------------------------------

        opcode = OPCODE_R_TYPE;

        check_control(
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b10,
            "R-Type"
        );

        // ----------------------------------------------------
        // LW
        //
        // Expected:
        // RegWrite = 1
        // ALUSrc   = 1
        // MemRead  = 1
        // MemWrite = 0
        // MemToReg = 1
        // Branch   = 0
        // ALUOp    = 00
        // ----------------------------------------------------

        opcode = OPCODE_LOAD;

        check_control(
            1'b1,
            1'b1,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            2'b00,
            "LW"
        );

        // ----------------------------------------------------
        // SW
        //
        // Expected:
        // RegWrite = 0
        // ALUSrc   = 1
        // MemRead  = 0
        // MemWrite = 1
        // MemToReg = 0
        // Branch   = 0
        // ALUOp    = 00
        // ----------------------------------------------------

        opcode = OPCODE_STORE;

        check_control(
            1'b0,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            2'b00,
            "SW"
        );

        // ----------------------------------------------------
        // BEQ
        //
        // Expected:
        // RegWrite = 0
        // ALUSrc   = 0
        // MemRead  = 0
        // MemWrite = 0
        // MemToReg = 0
        // Branch   = 1
        // ALUOp    = 01
        // ----------------------------------------------------

        opcode = OPCODE_BRANCH;

        check_control(
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            2'b01,
            "BEQ"
        );

        // ----------------------------------------------------
        // Unsupported opcode
        // ----------------------------------------------------

        opcode = 7'b1111111;

        check_control(
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b00,
            "Unsupported opcode"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("             CONTROL UNIT TEST RESULT");
        $display("============================================================");

        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("          ALL CONTROL UNIT TESTS PASSED");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("          CONTROL UNIT TESTS FAILED");
            $display("============================================================");

        end

        $finish;

    end

endmodule