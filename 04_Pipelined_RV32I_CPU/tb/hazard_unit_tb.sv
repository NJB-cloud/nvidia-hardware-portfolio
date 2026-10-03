// ============================================================
// Project 4: Hazard Detection Unit Testbench
// ============================================================

`timescale 1ns/1ps

module hazard_unit_tb;

    logic       id_ex_MemRead;
    logic [4:0] id_ex_rd;

    logic [4:0] if_id_rs1;
    logic [4:0] if_id_rs2;

    logic       if_id_uses_rs1;
    logic       if_id_uses_rs2;

    logic       pc_write;
    logic       if_id_write;
    logic       id_ex_flush;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    hazard_unit dut (
        .id_ex_MemRead (id_ex_MemRead),
        .id_ex_rd      (id_ex_rd),

        .if_id_rs1     (if_id_rs1),
        .if_id_rs2     (if_id_rs2),

        .if_id_uses_rs1(if_id_uses_rs1),
        .if_id_uses_rs2(if_id_uses_rs2),

        .pc_write      (pc_write),
        .if_id_write   (if_id_write),
        .id_ex_flush   (id_ex_flush)
    );

    // --------------------------------------------------------
    // Verification task
    // --------------------------------------------------------

    task automatic check(
        input logic expected_pc_write,
        input logic expected_if_id_write,
        input logic expected_flush,
        input string test_name
    );

        begin

            #1;

            if (
                pc_write === expected_pc_write &&
                if_id_write === expected_if_id_write &&
                id_ex_flush === expected_flush
            ) begin

                $display(
                    "PASS: %-40s PCWrite=%b IF_ID_Write=%b ID_EX_Flush=%b",
                    test_name,
                    pc_write,
                    if_id_write,
                    id_ex_flush
                );

            end
            else begin

                $display(
                    "FAIL: %-40s PCWrite=%b IF_ID_Write=%b ID_EX_Flush=%b",
                    test_name,
                    pc_write,
                    if_id_write,
                    id_ex_flush
                );

                $display(
                    "      Expected                       PCWrite=%b IF_ID_Write=%b ID_EX_Flush=%b",
                    expected_pc_write,
                    expected_if_id_write,
                    expected_flush
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
        $display("             HAZARD DETECTION UNIT VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Test 1: Normal operation
        // ----------------------------------------------------

        id_ex_MemRead = 1'b0;
        id_ex_rd = 5'd3;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd2;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b1,
            1'b1,
            1'b0,
            "No hazard"
        );

        // ----------------------------------------------------
        // Test 2: Load-use through rs1
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd5;

        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd2;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b0,
            1'b0,
            1'b1,
            "Load-use hazard through rs1"
        );

        // ----------------------------------------------------
        // Test 3: Load-use through rs2
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd6;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd6;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b0,
            1'b0,
            1'b1,
            "Load-use hazard through rs2"
        );

        // ----------------------------------------------------
        // Test 4: Both operands depend on load
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd7;

        if_id_rs1 = 5'd7;
        if_id_rs2 = 5'd7;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b0,
            1'b0,
            1'b1,
            "Both operands depend on load"
        );

        // ----------------------------------------------------
        // Test 5: Different destination register
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd8;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd2;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b1,
            1'b1,
            1'b0,
            "No dependency"
        );

        // ----------------------------------------------------
        // Test 6: x0 must not cause a stall
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd0;

        if_id_rs1 = 5'd0;
        if_id_rs2 = 5'd0;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b1,
            1'b1,
            1'b0,
            "x0 protection"
        );

        // ----------------------------------------------------
        // Test 7: rs1 matches but instruction doesn't use rs1
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd9;

        if_id_rs1 = 5'd9;
        if_id_rs2 = 5'd2;

        if_id_uses_rs1 = 1'b0;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b1,
            1'b1,
            1'b0,
            "Unused rs1 does not cause false stall"
        );

        // ----------------------------------------------------
        // Test 8: rs2 matches but instruction doesn't use rs2
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd10;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd10;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b0;

        check(
            1'b1,
            1'b1,
            1'b0,
            "Unused rs2 does not cause false stall"
        );

        // ----------------------------------------------------
        // Test 9: Only rs1 is used and matches
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd11;

        if_id_rs1 = 5'd11;
        if_id_rs2 = 5'd12;

        if_id_uses_rs1 = 1'b1;
        if_id_uses_rs2 = 1'b0;

        check(
            1'b0,
            1'b0,
            1'b1,
            "Single-source rs1 dependency"
        );

        // ----------------------------------------------------
        // Test 10: Only rs2 is used and matches
        // ----------------------------------------------------

        id_ex_MemRead = 1'b1;
        id_ex_rd = 5'd13;

        if_id_rs1 = 5'd14;
        if_id_rs2 = 5'd13;

        if_id_uses_rs1 = 1'b0;
        if_id_uses_rs2 = 1'b1;

        check(
            1'b0,
            1'b0,
            1'b1,
            "Single-source rs2 dependency"
        );

        $display("");
        $display("============================================================");
        $display("             HAZARD UNIT RESULT");
        $display("============================================================");
        $display("TOTAL TESTS = 10");
        $display("PASSED      = 10");
        $display("FAILED      = 0");
        $display("ALL HAZARD DETECTION TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule