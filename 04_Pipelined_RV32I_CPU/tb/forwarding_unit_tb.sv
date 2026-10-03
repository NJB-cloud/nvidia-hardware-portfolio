// ============================================================
// Project 4: Forwarding Unit Testbench
// ============================================================

`timescale 1ns/1ps

module forwarding_unit_tb;

    logic [4:0] id_ex_rs1;
    logic [4:0] id_ex_rs2;

    logic [4:0] ex_mem_rd;
    logic       ex_mem_RegWrite;

    logic [4:0] mem_wb_rd;
    logic       mem_wb_RegWrite;

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    forwarding_unit dut (
        .id_ex_rs1      (id_ex_rs1),
        .id_ex_rs2      (id_ex_rs2),

        .ex_mem_rd      (ex_mem_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite),

        .mem_wb_rd      (mem_wb_rd),
        .mem_wb_RegWrite(mem_wb_RegWrite),

        .forward_a      (forward_a),
        .forward_b      (forward_b)
    );

    // --------------------------------------------------------
    // Verification task
    // --------------------------------------------------------

    task automatic check(
        input logic [1:0] expected_a,
        input logic [1:0] expected_b,
        input string      test_name
    );

        begin

            #1;

            if (
                forward_a === expected_a &&
                forward_b === expected_b
            ) begin

                $display(
                    "PASS: %-35s ForwardA=%b ForwardB=%b",
                    test_name,
                    forward_a,
                    forward_b
                );

            end
            else begin

                $display(
                    "FAIL: %-35s ForwardA=%b ForwardB=%b",
                    test_name,
                    forward_a,
                    forward_b
                );

                $display(
                    "      Expected ForwardA=%b ForwardB=%b",
                    expected_a,
                    expected_b
                );

                $fatal;

            end

        end

    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        $display("");
        $display("============================================================");
        $display("             FORWARDING UNIT VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Test 1: No forwarding
        // ----------------------------------------------------

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd3;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd4;
        mem_wb_RegWrite = 1'b1;

        #1;

        check(
            2'b00,
            2'b00,
            "No forwarding"
        );

        // ----------------------------------------------------
        // Test 2: EX/MEM → A
        // ----------------------------------------------------

        id_ex_rs1 = 5'd5;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd5;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd7;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b10,
            2'b00,
            "EX/MEM forwarding to A"
        );

        // ----------------------------------------------------
        // Test 3: EX/MEM → B
        // ----------------------------------------------------

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd6;

        ex_mem_rd = 5'd6;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd7;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b00,
            2'b10,
            "EX/MEM forwarding to B"
        );

        // ----------------------------------------------------
        // Test 4: MEM/WB → A
        // ----------------------------------------------------

        id_ex_rs1 = 5'd8;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd3;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd8;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b01,
            2'b00,
            "MEM/WB forwarding to A"
        );

        // ----------------------------------------------------
        // Test 5: MEM/WB → B
        // ----------------------------------------------------

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd9;

        ex_mem_rd = 5'd3;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd9;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b00,
            2'b01,
            "MEM/WB forwarding to B"
        );

        // ----------------------------------------------------
        // Test 6: Both operands forwarded from EX/MEM
        // ----------------------------------------------------

        id_ex_rs1 = 5'd10;
        id_ex_rs2 = 5'd11;

        ex_mem_rd = 5'd10;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd11;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b10,
            2'b01,
            "Independent forwarding A/B"
        );

        // ----------------------------------------------------
        // Test 7: EX/MEM has priority over MEM/WB
        //
        // Both stages claim to write the same register.
        // The newer EX/MEM result must win.
        // ----------------------------------------------------

        id_ex_rs1 = 5'd12;
        id_ex_rs2 = 5'd13;

        ex_mem_rd = 5'd12;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd12;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b10,
            2'b00,
            "EX/MEM priority over MEM/WB"
        );

        // ----------------------------------------------------
        // Test 8: x0 must never be forwarded
        // ----------------------------------------------------

        id_ex_rs1 = 5'd0;
        id_ex_rs2 = 5'd0;

        ex_mem_rd = 5'd0;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd0;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b00,
            2'b00,
            "x0 protection"
        );

        // ----------------------------------------------------
        // Test 9: RegWrite disabled
        // ----------------------------------------------------

        id_ex_rs1 = 5'd14;
        id_ex_rs2 = 5'd15;

        ex_mem_rd = 5'd14;
        ex_mem_RegWrite = 1'b0;

        mem_wb_rd = 5'd15;
        mem_wb_RegWrite = 1'b0;

        check(
            2'b00,
            2'b00,
            "RegWrite disabled"
        );

        // ----------------------------------------------------
        // Test 10: Mixed forwarding
        // ----------------------------------------------------

        id_ex_rs1 = 5'd16;
        id_ex_rs2 = 5'd17;

        ex_mem_rd = 5'd16;
        ex_mem_RegWrite = 1'b1;

        mem_wb_rd = 5'd17;
        mem_wb_RegWrite = 1'b1;

        check(
            2'b10,
            2'b01,
            "Mixed EX/MEM and MEM/WB"
        );

        $display("");
        $display("============================================================");
        $display("             FORWARDING UNIT RESULT");
        $display("============================================================");
        $display("TOTAL TESTS = 10");
        $display("PASSED      = 10");
        $display("FAILED      = 0");
        $display("ALL FORWARDING UNIT TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule