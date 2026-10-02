// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: ALU Control
// ============================================================

`timescale 1ns/1ps

module alu_control_tb;

    logic [1:0] alu_op;
    logic [2:0] funct3;
    logic       funct7_bit5;

    logic [3:0] alu_control;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Expected ALU operation codes
    // Must match rtl/alu.sv
    // --------------------------------------------------------

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;

    // --------------------------------------------------------
    // ALUOp values
    // --------------------------------------------------------

    localparam logic [1:0] ALUOP_ADD    = 2'b00;
    localparam logic [1:0] ALUOP_SUB    = 2'b01;
    localparam logic [1:0] ALUOP_R_TYPE = 2'b10;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    alu_control dut (
        .alu_op      (alu_op),
        .funct3      (funct3),
        .funct7_bit5 (funct7_bit5),
        .alu_control (alu_control)
    );

    // --------------------------------------------------------
    // Verification task
    // --------------------------------------------------------

    task automatic check_control(
        input logic [1:0] alu_op_in,
        input logic [2:0] funct3_in,
        input logic       funct7_in,
        input logic [3:0] expected,
        input string      test_name
    );

        begin

            alu_op      = alu_op_in;
            funct3      = funct3_in;
            funct7_bit5 = funct7_in;

            #1;

            if (alu_control === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %-30s | ALUOp=%b funct3=%b funct7[5]=%b -> ALU=%b",
                    test_name,
                    alu_op,
                    funct3,
                    funct7_bit5,
                    alu_control
                );

            end

            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %-30s | Expected=%b Got=%b",
                    test_name,
                    expected,
                    alu_control
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

        alu_op      = ALUOP_ADD;
        funct3      = 3'b000;
        funct7_bit5 = 1'b0;

        $display("");
        $display("============================================================");
        $display("                RV32I ALU CONTROL VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // LW / SW address calculation
        // ALUOp = 00 -> ADD
        // ----------------------------------------------------

        check_control(
            ALUOP_ADD,
            3'b000,
            1'b0,
            ALU_ADD,
            "LW/SW address ADD"
        );

        // ----------------------------------------------------
        // BEQ comparison
        // ALUOp = 01 -> SUB
        // ----------------------------------------------------

        check_control(
            ALUOP_SUB,
            3'b000,
            1'b0,
            ALU_SUB,
            "BEQ comparison SUB"
        );

        // ----------------------------------------------------
        // R-Type ADD
        // funct3 = 000, funct7[5] = 0
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b000,
            1'b0,
            ALU_ADD,
            "R-Type ADD"
        );

        // ----------------------------------------------------
        // R-Type SUB
        // funct3 = 000, funct7[5] = 1
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b000,
            1'b1,
            ALU_SUB,
            "R-Type SUB"
        );

        // ----------------------------------------------------
        // R-Type XOR
        // funct3 = 100
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b100,
            1'b0,
            ALU_XOR,
            "R-Type XOR"
        );

        // ----------------------------------------------------
        // R-Type OR
        // funct3 = 110
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b110,
            1'b0,
            ALU_OR,
            "R-Type OR"
        );

        // ----------------------------------------------------
        // R-Type AND
        // funct3 = 111
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b111,
            1'b0,
            ALU_AND,
            "R-Type AND"
        );

        // ----------------------------------------------------
        // R-Type SLT
        // funct3 = 010
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b010,
            1'b0,
            ALU_SLT,
            "R-Type SLT"
        );

        // ----------------------------------------------------
        // Unsupported funct3
        // Safe default = ADD
        // ----------------------------------------------------

        check_control(
            ALUOP_R_TYPE,
            3'b011,
            1'b0,
            ALU_ADD,
            "Unsupported funct3"
        );

        // ----------------------------------------------------
        // Unsupported ALUOp
        // Safe default = ADD
        // ----------------------------------------------------

        check_control(
            2'b11,
            3'b111,
            1'b1,
            ALU_ADD,
            "Unsupported ALUOp"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("                ALU CONTROL TEST RESULT");
        $display("============================================================");

        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("             ALL ALU CONTROL TESTS PASSED");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("             ALU CONTROL TESTS FAILED");
            $display("============================================================");

        end

        $finish;

    end

endmodule