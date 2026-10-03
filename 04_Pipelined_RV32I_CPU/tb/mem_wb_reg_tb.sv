// ============================================================
// Project 4: MEM/WB Pipeline Register Testbench
// ============================================================

`timescale 1ns/1ps

module mem_wb_reg_tb;

    logic clk;
    logic rst_n;

    logic [31:0] mem_alu_result;
    logic [31:0] mem_read_data;

    logic [4:0] mem_rd;

    logic mem_RegWrite;
    logic mem_MemToReg;

    logic mem_valid;

    logic [31:0] wb_alu_result;
    logic [31:0] wb_read_data;

    logic [4:0] wb_rd;

    logic wb_RegWrite;
    logic wb_MemToReg;

    logic wb_valid;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    mem_wb_reg dut (
        .clk          (clk),
        .rst_n        (rst_n),

        .mem_alu_result(mem_alu_result),
        .mem_read_data (mem_read_data),

        .mem_rd        (mem_rd),

        .mem_RegWrite  (mem_RegWrite),
        .mem_MemToReg  (mem_MemToReg),

        .mem_valid     (mem_valid),

        .wb_alu_result (wb_alu_result),
        .wb_read_data  (wb_read_data),

        .wb_rd         (wb_rd),

        .wb_RegWrite   (wb_RegWrite),
        .wb_MemToReg   (wb_MemToReg),

        .wb_valid      (wb_valid)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Verification task
    // --------------------------------------------------------

    task automatic check(
        input logic [31:0] expected_alu,
        input logic [31:0] expected_read,
        input logic [4:0]  expected_rd,
        input logic        expected_RegWrite,
        input logic        expected_MemToReg,
        input logic        expected_valid,
        input string       test_name
    );

        begin

            #1;

            if (
                wb_alu_result === expected_alu &&
                wb_read_data  === expected_read &&
                wb_rd         === expected_rd &&
                wb_RegWrite   === expected_RegWrite &&
                wb_MemToReg   === expected_MemToReg &&
                wb_valid      === expected_valid
            ) begin

                $display("PASS: %s", test_name);

            end
            else begin

                $display("FAIL: %s", test_name);

                $display(
                    "Expected ALU=%08h READ=%08h RD=%0d",
                    expected_alu,
                    expected_read,
                    expected_rd
                );

                $display(
                    "Got      ALU=%08h READ=%08h RD=%0d",
                    wb_alu_result,
                    wb_read_data,
                    wb_rd
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
        $display("          MEM/WB PIPELINE REGISTER VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------

        rst_n = 1'b0;

        mem_alu_result = 32'h0000_0030;
        mem_read_data  = 32'h0000_0040;

        mem_rd = 5'd7;

        mem_RegWrite = 1'b1;
        mem_MemToReg = 1'b0;

        mem_valid = 1'b1;

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        @(posedge clk);
        #1;

        check(
            32'h0000_0000,
            32'h0000_0000,
            5'd0,
            1'b0,
            1'b0,
            1'b0,
            "Reset"
        );

        // ----------------------------------------------------
        // ALU WRITE-BACK
        // ----------------------------------------------------

        rst_n = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0030,
            32'h0000_0040,
            5'd7,
            1'b1,
            1'b0,
            1'b1,
            "ALU write-back"
        );

        // ----------------------------------------------------
        // LOAD WRITE-BACK
        // ----------------------------------------------------

        mem_alu_result = 32'h0000_0100;
        mem_read_data  = 32'hDEAD_BEEF;

        mem_rd = 5'd5;

        mem_RegWrite = 1'b1;
        mem_MemToReg = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0100,
            32'hDEAD_BEEF,
            5'd5,
            1'b1,
            1'b1,
            1'b1,
            "Load write-back"
        );

        // ----------------------------------------------------
        // NON-WRITE INSTRUCTION
        // ----------------------------------------------------

        mem_alu_result = 32'h0000_0200;
        mem_read_data  = 32'h0000_0000;

        mem_rd = 5'd0;

        mem_RegWrite = 1'b0;
        mem_MemToReg = 1'b0;

        @(posedge clk);

        check(
            32'h0000_0200,
            32'h0000_0000,
            5'd0,
            1'b0,
            1'b0,
            1'b1,
            "Non-write instruction"
        );

        // ----------------------------------------------------
        // Resume normal operation
        // ----------------------------------------------------

        mem_alu_result = 32'h0000_0055;
        mem_read_data  = 32'h0000_0066;

        mem_rd = 5'd9;

        mem_RegWrite = 1'b1;
        mem_MemToReg = 1'b0;

        @(posedge clk);

        check(
            32'h0000_0055,
            32'h0000_0066,
            5'd9,
            1'b1,
            1'b0,
            1'b1,
            "Resume operation"
        );

        $display("");
        $display("============================================================");
        $display("             MEM/WB REGISTER RESULT");
        $display("============================================================");
        $display("ALL MEM/WB PIPELINE REGISTER TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule