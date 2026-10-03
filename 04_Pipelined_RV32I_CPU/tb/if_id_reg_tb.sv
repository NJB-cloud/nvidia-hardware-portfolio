// ============================================================
// Project 4: IF/ID Pipeline Register Testbench
// ============================================================

`timescale 1ns/1ps

module if_id_reg_tb;

    logic        clk;
    logic        rst_n;
    logic        stall;
    logic        flush;

    logic [31:0] if_pc;
    logic [31:0] if_pc_plus4;
    logic [31:0] if_instruction;

    logic [31:0] id_pc;
    logic [31:0] id_pc_plus4;
    logic [31:0] id_instruction;
    logic        id_valid;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    if_id_reg dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (stall),
        .flush          (flush),
        .if_pc          (if_pc),
        .if_pc_plus4    (if_pc_plus4),
        .if_instruction (if_instruction),
        .id_pc          (id_pc),
        .id_pc_plus4    (id_pc_plus4),
        .id_instruction (id_instruction),
        .id_valid       (id_valid)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Test helper
    // --------------------------------------------------------

    task automatic check(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_pc_plus4,
        input logic [31:0] expected_instruction,
        input logic        expected_valid,
        input string       test_name
    );

        begin

            #1;

            if (
                id_pc === expected_pc &&
                id_pc_plus4 === expected_pc_plus4 &&
                id_instruction === expected_instruction &&
                id_valid === expected_valid
            ) begin

                $display(
                    "PASS: %-25s PC=%08h INST=%08h VALID=%b",
                    test_name,
                    id_pc,
                    id_instruction,
                    id_valid
                );

            end
            else begin

                $display(
                    "FAIL: %-25s PC=%08h INST=%08h VALID=%b",
                    test_name,
                    id_pc,
                    id_instruction,
                    id_valid
                );

                $display(
                    "      Expected            PC=%08h INST=%08h VALID=%b",
                    expected_pc,
                    expected_instruction,
                    expected_valid
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
        $display("          IF/ID PIPELINE REGISTER VERIFICATION");
        $display("============================================================");

        rst_n = 1'b0;
        stall = 1'b0;
        flush = 1'b0;

        if_pc = 32'h0000_0000;
        if_pc_plus4 = 32'h0000_0004;
        if_instruction = 32'h0010_81B3;

        // Reset
        @(posedge clk);
        #1;

        check(
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0013,
            1'b0,
            "Reset"
        );

        // Release reset
        rst_n = 1'b1;

        // Normal capture
        if_pc = 32'h0000_0010;
        if_pc_plus4 = 32'h0000_0014;
        if_instruction = 32'h0020_81B3;

        @(posedge clk);

        check(
            32'h0000_0010,
            32'h0000_0014,
            32'h0020_81B3,
            1'b1,
            "Normal capture"
        );

        // Stall
        stall = 1'b1;

        if_pc = 32'h0000_0020;
        if_pc_plus4 = 32'h0000_0024;
        if_instruction = 32'h0031_0233;

        @(posedge clk);

        check(
            32'h0000_0010,
            32'h0000_0014,
            32'h0020_81B3,
            1'b1,
            "Stall / hold"
        );

        // Flush has priority over stall
        flush = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0013,
            1'b0,
            "Flush / bubble"
        );

        // Release flush and stall
        flush = 1'b0;
        stall = 1'b0;

        // Normal operation resumes
        if_pc = 32'h0000_0030;
        if_pc_plus4 = 32'h0000_0034;
        if_instruction = 32'h0041_82B3;

        @(posedge clk);

        check(
            32'h0000_0030,
            32'h0000_0034,
            32'h0041_82B3,
            1'b1,
            "Resume after flush"
        );

        $display("");
        $display("============================================================");
        $display("             IF/ID REGISTER RESULT");
        $display("============================================================");
        $display("ALL IF/ID PIPELINE REGISTER TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule