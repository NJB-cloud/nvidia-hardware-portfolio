// ============================================================
// Project 4: EX/MEM Pipeline Register Testbench
// ============================================================

`timescale 1ns/1ps

module ex_mem_reg_tb;

    logic clk;
    logic rst_n;
    logic flush;

    logic [31:0] ex_alu_result;
    logic [31:0] ex_store_data;

    logic [4:0] ex_rd;

    logic ex_RegWrite;
    logic ex_MemRead;
    logic ex_MemWrite;
    logic ex_MemToReg;

    logic ex_valid;

    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;

    logic [4:0] mem_rd;

    logic mem_RegWrite;
    logic mem_MemRead;
    logic mem_MemWrite;
    logic mem_MemToReg;

    logic mem_valid;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    ex_mem_reg dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .flush        (flush),

        .ex_alu_result(ex_alu_result),
        .ex_store_data(ex_store_data),

        .ex_rd        (ex_rd),

        .ex_RegWrite  (ex_RegWrite),
        .ex_MemRead   (ex_MemRead),
        .ex_MemWrite  (ex_MemWrite),
        .ex_MemToReg  (ex_MemToReg),

        .ex_valid     (ex_valid),

        .mem_alu_result(mem_alu_result),
        .mem_store_data(mem_store_data),

        .mem_rd       (mem_rd),

        .mem_RegWrite (mem_RegWrite),
        .mem_MemRead  (mem_MemRead),
        .mem_MemWrite (mem_MemWrite),
        .mem_MemToReg (mem_MemToReg),

        .mem_valid    (mem_valid)
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
        input logic [31:0] expected_store,
        input logic [4:0]  expected_rd,
        input logic        expected_RegWrite,
        input logic        expected_MemRead,
        input logic        expected_MemWrite,
        input logic        expected_MemToReg,
        input logic        expected_valid,
        input string       test_name
    );

        begin

            #1;

            if (
                mem_alu_result === expected_alu &&
                mem_store_data === expected_store &&
                mem_rd         === expected_rd &&
                mem_RegWrite   === expected_RegWrite &&
                mem_MemRead    === expected_MemRead &&
                mem_MemWrite   === expected_MemWrite &&
                mem_MemToReg   === expected_MemToReg &&
                mem_valid      === expected_valid
            ) begin

                $display("PASS: %s", test_name);

            end
            else begin

                $display("FAIL: %s", test_name);

                $display(
                    "Expected ALU=%08h STORE=%08h RD=%0d",
                    expected_alu,
                    expected_store,
                    expected_rd
                );

                $display(
                    "Got      ALU=%08h STORE=%08h RD=%0d",
                    mem_alu_result,
                    mem_store_data,
                    mem_rd
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
        $display("          EX/MEM PIPELINE REGISTER VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------

        rst_n = 1'b0;
        flush = 1'b0;

        ex_alu_result = 32'h0000_0030;
        ex_store_data = 32'h0000_0040;

        ex_rd = 5'd7;

        ex_RegWrite = 1'b1;
        ex_MemRead  = 1'b0;
        ex_MemWrite = 1'b0;
        ex_MemToReg = 1'b0;

        ex_valid = 1'b1;

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
            1'b0,
            1'b0,
            "Reset"
        );

        // ----------------------------------------------------
        // NORMAL CAPTURE
        // ----------------------------------------------------

        rst_n = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0030,
            32'h0000_0040,
            5'd7,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            "Normal capture"
        );

        // ----------------------------------------------------
        // MEMORY OPERATION
        // ----------------------------------------------------

        ex_alu_result = 32'h0000_0100;
        ex_store_data = 32'hDEAD_BEEF;

        ex_rd = 5'd0;

        ex_RegWrite = 1'b0;
        ex_MemRead  = 1'b0;
        ex_MemWrite = 1'b1;
        ex_MemToReg = 1'b0;

        @(posedge clk);

        check(
            32'h0000_0100,
            32'hDEAD_BEEF,
            5'd0,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b1,
            "Store operation"
        );

        // ----------------------------------------------------
        // LOAD OPERATION
        // ----------------------------------------------------

        ex_alu_result = 32'h0000_0200;
        ex_store_data = 32'h0000_0000;

        ex_rd = 5'd5;

        ex_RegWrite = 1'b1;
        ex_MemRead  = 1'b1;
        ex_MemWrite = 1'b0;
        ex_MemToReg = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0200,
            32'h0000_0000,
            5'd5,
            1'b1,
            1'b1,
            1'b0,
            1'b1,
            1'b1,
            "Load operation"
        );

        // ----------------------------------------------------
        // FLUSH
        // ----------------------------------------------------

        flush = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0000,
            32'h0000_0000,
            5'd0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "Flush / bubble"
        );

        // ----------------------------------------------------
        // RESUME
        // ----------------------------------------------------

        flush = 1'b0;

        ex_alu_result = 32'h0000_0055;
        ex_store_data = 32'h0000_0066;

        ex_rd = 5'd9;

        ex_RegWrite = 1'b1;
        ex_MemRead  = 1'b0;
        ex_MemWrite = 1'b0;
        ex_MemToReg = 1'b0;

        @(posedge clk);

        check(
            32'h0000_0055,
            32'h0000_0066,
            5'd9,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            "Resume after flush"
        );

        $display("");
        $display("============================================================");
        $display("             EX/MEM REGISTER RESULT");
        $display("============================================================");
        $display("ALL EX/MEM PIPELINE REGISTER TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule